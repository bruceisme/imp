# 😈 Imp

[[📖 Technical report](https://arxiv.org/abs/2405.12107)\]&nbsp;&nbsp;[[😈Demo](https://xmbot.net/imp/)\]&nbsp;&nbsp;[[🤗Huggingface](https://huggingface.co/MILVLG)\]


This repository contains the official training/evaluation code of the Imp project, which aims to provide a family of highly capable yet efficient large multimodal models (LMMs). `Imp-v1-3B` is our attempt with only **3B** parameters, which is build upon a small yet powerful SLM [Phi-2](https://huggingface.co/microsoft/phi-2) (2.7B) and a powerful visual encoder [SigLIP](https://huggingface.co/google/siglip-so400m-patch14-384) (0.4B), and trained on the [LLaVA-v1.5](https://github.com/haotian-liu/LLaVA) training set. After that, we further investigate different LLMs, training strategies, and traning data, and obtain a series of models termed `Imp-v1.5-2B/3B/4B`. 

As shown in the [Evaluation](#evaluation), our Imp model significantly outperforms the counterparts of similar model sizes, and even achieves slightly better performance than the strong LLaVA-7B model on various multimodal benchmarks. 

Now the training and evaluation codes of `Imp-v1-3B` and `Imp-v1.5-2B/3B/4B` are released. And the Multimodal instruction tuning data will be released as soon as possible.

## Updates
- July 4, 2024: Training and evaluation codes of `Imp-v1.5-2B/3B/4B` are released.
- May 21, 2024: The technical report and corresponding `Imp-v1.5-2B/3B/4B` model series are released on [🤗HuggingFace](https://huggingface.co/collections/MILVLG/imp-v15-664c07c27a71afa504f69cec).
- February 9, 2024: Training and evaluation codes of the `Imp-v1-3B` model are released.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Model Zoo](#model-zoo)
- [Training](#training)
- [Finetuning](#customized-continue-finetuning) 
- [Evaluation](#evaluation)
- [Deployment](#deployment)
- [License](#license)
- [Citation](#citation)

## Prerequisites

1. Clone this repository and navigate to the folder 
``` shell
git clone https://github.com/MILVLG/imp.git
cd imp
```
2. Install Package

We recommend using [Anaconda](https://www.anaconda.com/) to create a new environment for the project, and install the requirements with the following commands:
``` shell
conda create -n imp python=3.10 -y
conda activate imp
pip install -r requirements.txt
pip install flash-attn==2.4.2 --no-build-isolation
```

<!-- 3. Download the pretrained base models (i.e., Phi-2 and SigLIP) to your local directories. (optional)
``` shell
python scripts/download_models.py
```
The base models will be stored in `checkpoints/base` in default.
```
checkpoints
└── base
    └── siglip-so400m-patch14-384
    └── phi-2
``` -->
## Model-zoo
All models of `Imp` family can be checked on [Model_Zoo.md](./docs/Model_Zoo.md).

## Customized Continue-Finetuning
You can directly finetune different versions of `Imp` using your own custom dataset use `scripts/finetune_lora_custom.sh`. The custom dataset should be in the LLaVA-1.5 format.

If you want to train an imp from scratch, please refers to [Training](#training).

``` shell
#imp_model should be hg repository or local model path with imp
#version should be the same as imp, only in phi2/qwen1.5/phi3
bash scripts/finetune_lora_custom.sh -imp_model "path/to/imp" -version "phi2"
```
You will get a trained lora model `imp-{version}-custom-lora`  under `./checkpoints/`. And you can use the following script to merge lora model and base `imp` into a single one for release and evaluation. Our [evaluation](./docs/Evaluation.md) script supports both the lora model and merged model checkpoints.

``` shell
#version should be the same as imp, only in phi2/qwen1.5/phi3
bash scripts/merge.sh -imp_model "path/to/imp"  -lora "path/to/lora" -version "phi2"
```
After that, a checkpoint file will be stored in `./checkpoints/imp-{version}-merged`.


## Training
The training pipeline and datasets of our Imp models are directly inherited from [LLaVA-v1.5](https://github.com/haotian-liu/LLaVA). The training  
- *Multimodal pretraining*: train a projector on a subset of ∼558K image-text pairs to connect a frozen pretrained vision encoder and a frozen LLM.
- *Multimodal instruction tuning*: fine-tune the projector and LoRA in the LLM with multimodal instruction data and VQA-formatted data to empower the MLSM the ability of multimodal instruction following.
- Note: For `Imp-v1.5-2B/3B/4B`, we append OCR&chart-oriented datasets and GPT4V-annotated datasets in the base of llava 1.5's Multimodal instruction tuning datasets. The augmented data will be released as soon as possible. More information about the data refers to [imp](https://arxiv.org/abs/2405.12107)

Imp is trained on 8 A100 (40G) GPUs. You can reduce the `per_device_train_batch_size` and increase the `gradient_accumulation_steps` to match your resources. .But always keep the global batch size the same: `global_batch_size ` = `per_device_train_batch_size` $`\times`$ `gradient_accumulation_steps` $`\times`$ `num_gpus`.

<!-- You can directly finetune `imp` on your custom datasets in [Customized Continue-Finetuning](#customized-continue-finetuning) . -->

<details>
<summary>Training scripts </summary>

### Stage-1: Multimodal pretraining
Take `Imp-v1-3B` as an example, all stages' checkpoint can be downloaded in [Model_Zoo.md](./docs/Model_Zoo.md).
Please download the caption annotations `blip_laion_cc_sbu_558k.json` and images from [here](https://huggingface.co/datasets/liuhaotian/LLaVA-Pretrain). Move the downloaded files to the `./datasets` folder, with image folder unzipped and renamed to `pretrain_images`. Then run the following command to start the training process:

``` shell
bash scripts/pretrain.sh 
```

After that, a checkpoint file will be stored in `./checkpoints/imp-v1-3b-stage1`.

### Stage-2: Multimodal instruction tuning

Please download the annotation file of the mixed instruction tuning data [llava_v1_5_mix665k.json](https://huggingface.co/datasets/liuhaotian/LLaVA-Instruct-150K/blob/main/llava_v1_5_mix665k.json), and download the images from constituting datasets:

- COCO: [train2017](http://images.cocodataset.org/zips/train2017.zip)
- GQA: [images](https://downloads.cs.stanford.edu/nlp/data/gqa/images.zip)
- OCR-VQA: [download script](https://drive.google.com/drive/folders/1_GYPY5UkUy7HIcR0zq3ZCFgeZN7BAfm_?usp=sharing), **save all files as `.jpg`**
- TextVQA: [train_val_images](https://dl.fbaipublicfiles.com/textvqa/images/train_val_images.zip)
- VisualGenome: [part1](https://cs.stanford.edu/people/rak248/VG_100K_2/images.zip), [part2](https://cs.stanford.edu/people/rak248/VG_100K_2/images2.zip)

After downloading all of them, organize the data as follows:

```
datasets
├── llava_v1_5_mix665k.json
└── finetune_images
    ├── coco
    │   └── train2017
    ├── gqa
    │   └── images
    ├── ocr_vqa
    │   └── images
    ├── textvqa
    │   └── train_images
    └── vg
        ├── VG_100K
        └── VG_100K_2
```

Then, you can start the training process by the following script. If you use your custom dataset, you can refer to `llava_v1_5_mix665k.json` to format your data.

``` shell
bash scripts/finetune_lora.sh
# bash scripts/finetune.sh # fully finetuning is not recommended
```
You will get a trained model `imp-v1-3b-stage2-lora` (a LoRA diff if you use `finetune_lora.sh`) under `./checkpoints/` when the training is done.

### Lora merging

After the above model training, the model checkpoint consists of base model and lora model. You can merge the lora model and base imp model into a single one by  scripts `merge.sh` in [merge](#customized-continue-finetuning).Our evaluation script supports both the lora model and merged model checkpoints. **However, if you want to fine-tune the model on your own custom dataset, only the merged model is supported.** 


</details>



## Evaluation
We follow the evaluation of [LLaVA-v1.5](https://github.com/haotian-liu/LLaVA/tree/main) and conduct experiments on 9 commonly-used benchmarks, including 5 academic VQA benchmarks and 4 popular MLLM benchmarks. All evaluation scripts are placed in the `scripts/eval` folder. 

Before preparing task-specific data, you should download [eval.zip](https://drive.google.com/file/d/1atZSBBrAX54yYpxtVVW33zFvcnaHeFPy/view?usp=sharing) and unzip it to `./playground/data/eval`. For more specific instructions, please refer to [LLaVA's Evaluation.md](https://github.com/haotian-liu/LLaVA/blob/main/docs/Evaluation.md). 

It is supported to evaluate your reproduced model checkpoints or our released model. For more detailed evaluation scripts, please refer to [Evaluation.md](./docs/Evaluation.md).

Using our provided model, you can reproduce the following results. Our model significantly outperforms existing MSLMs of similar model sizes, and is comparable with the strong LLaVA-v1.5-7b model. 

| Models | VQAv2 | GQA |VizWiz  | SQA(IMG) | TextVQA | POPE |  MME(P) | MMB  |MM-Vet|
|:--------:|:----:|:----:|:-------------:|:--------:|:-----:|:----:|:-------:|:-------:|:-------:|
| [LLaVA-v1.5-lora](https://github.com/haotian-liu/LLaVA) (7B) |79.10 | 63.00 |47.80 |  68.40 |58.20| 86.40 | 1476.9 | 66.10  |30.2|
| [TinyGPT-V](https://github.com/DLYuanGod/TinyGPT-V) (3B) | - | 33.60  | 24.80  |    -   |    -  | -| - | -  |-|
| [LLaVA-Phi](https://github.com/zhuyiche/llava-phi) (3B) | 71.40  | - | 35.90 |    68.40   |    48.60  | 85.00 | 1335.1 | 59.80 |28.9|
| [MobileVLM](https://github.com/Meituan-AutoML/MobileVLM) (3B) | - | 59.00  | - |    61.00   |    47.50   | 84.90 | 1288.9 | 59.60  |-|
| [MC-LLaVA](https://huggingface.co/visheratin/MC-LLaVA-3b) (3B) | 64.24 | 49.60  | 24.88 |    -   |    38.59   | 80.59 | - | -  |-|
| [**Imp-v1-3B**](https://huggingface.co/MILVLG/imp-v1-3b) | 79.45 | 58.55 | 50.09 |69.96| 59.38 | 88.02| 1434.0 | 66.49 |33.1|
| [**Imp-v1.5-2B-Qwen1.5**](https://huggingface.co/MILVLG/Imp-v1.5-2B-Qwen1.5) | 79.2  | 61.93 | 39.16 |66.14| 54.52 | 86.74| 1304.8 | 56.95 |33.5|
| [**Imp-v1.5-3B-Phi2**](https://huggingface.co/MILVLG/Imp-v1.5-3B-Phi2) | 81.18  | **63.54** | **54.13** |72.78| 59.84 | **88.87**| 1446.4 | 72.94  |43.3|
| [**Imp-v1.5-4B-Phi3**](https://huggingface.co/MILVLG/Imp-v1.5-4B-Phi3) | **81.46** | 63.51 | 51.16 |**78.28**| **60.16** | 86.86| **1507.7** | **73.28**  |**44.6**|

## Deployment
Based on MLC-LLM, we provide a lightweight deployment solution so that imp can inference efficiently on the mobile device.

  - After **4-bit** quantification, imp only takes up about **1.9G** of storage space and is fully capable of running on mobile phones.
  - All **Android** devices are supported and **IOS** will come soon.
  - **Textual** and **visual** modalities are supported.

  More details can be found in [MILVLG/mlc-imp](https://github.com/MILVLG/mlc-imp).

## License
This project is licensed under the Apache License 2.0 - see the [LICENSE](https://www.apache.org/licenses/LICENSE-2.0) file for details.

## About us
This project is maintained by the [MILVLG](https://github.com/MILVLG)@Hangzhou Dianzi University (HDU) led by Prof. Zhou Yu and Jun Yu, and is mainly developed by Zhenwei Shao and Xuecheng Ouyang. We hope our model may serve as a strong baseline to inspire future research on MSLM, as well as its derivative applications on mobile devices and robots. 

## Citation

If you use our model or refer our work in your studies, please cite:

```bibtex
@article{imp2024,
  title={Imp: Highly Capable Large Multimodal Models for Mobile Devices},
  author={Shao, Zhenwei and Yu, Zhou and Yu, Jun and Ouyang, Xuecheng and Lihao, Zheng and Zhenbiao, Gai and Mingyang, Wang and Jiajun, Ding},
  journal={arXiv preprint arXiv:2405.12107},
  year={2024}
}
```
