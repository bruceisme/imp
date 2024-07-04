#!/bin/bash
# uncomment the following lines to shutoff the internet access
# export HF_HUB_OFFLINE=True
# export HF_DATASETS_OFFLINE=1
# export TRANSFORMERS_OFFLINE=1
export IMP_SILIENT_OTHERS=true

gpu_list="${CUDA_VISIBLE_DEVICES:-0}"
IFS=',' read -ra GPULIST <<< "$gpu_list"

CHUNKS=${#GPULIST[@]}
GQADIR="./playground/data/eval/gqa/data"


SPLIT="eval"

# merge eval
# MODEL_CKPT="milvlg/imp-v1-3b"
# MODEL_CKPT="/data/ouyangxc/labs/hg/imp-2b/old_phi_2ep/imp-v1-3b_1005ocr" # eval your own checkpoint
MODEL_CKPT="/data/ouyangxc/github/imp/checkpoints/imp-qwen1.5-aok-epoch2/"
EVAL_CKPT="cot_qwen1_5_74_epoch2"
MODEL_PATH=$MODEL_CKPT
# MODEL_PATH="./checkpoints/$MODEL_CKPT" # eval your own checkpoint

for IDX in $(seq 0 $((CHUNKS-1))); do
    LOCAL_RANK=$IDX CUDA_VISIBLE_DEVICES=${GPULIST[$IDX]} python -m imp_llava.eval.model_vqa_loader \
        --model-path $MODEL_PATH \
        --question-file /data/ouyangxc/github/CoT-V/datasets/aok/custom/aok_cot_eval.jsonl \
        --image-folder /data/ouyangxc/data/coco2017/  \
        --answers-file ./playground/data/eval/aok/answers/$SPLIT/$EVAL_CKPT/${CHUNKS}_${IDX}.jsonl \
        --num-chunks $CHUNKS \
        --chunk-idx $IDX \
        --temperature 0 \
        --conv-mode qwen2 &
done

wait

# lora eval
# MODEL_CKPT="imp-qwen1.5-2b-lora-0429"
# # MODEL_CKPT="llava-phi2-lora-0427-1005_withocr"
# EVAL_CKPT="${MODEL_CKPT//\//_}_1"
# MODEL_BASE=/data/llm_common/Qwen1.5-1.8B-Chat/

# # for IDX in $(seq 0 $((CHUNKS-1))); do
# #     LOCAL_RANK=$IDX CUDA_VISIBLE_DEVICES=${GPULIST[$IDX]} python -m imp_llava.eval.model_vqa_loader \
# #         --model-path ./checkpoints/$MODEL_CKPT \
# #         --model-base $MODEL_BASE  \
# #         --question-file ./playground/data/eval/gqa/$SPLIT.jsonl \
# #         --image-folder /data/ouyangxc/data/gqa/images  \
# #         --answers-file ./playground/data/eval/gqa/answers/$SPLIT/$EVAL_CKPT/${CHUNKS}_${IDX}.jsonl \
# #         --num-chunks $CHUNKS \
# #         --chunk-idx $IDX \
# #         --temperature 0 \
# #         --conv-mode qwen2 &
# # done

wait

output_file=./playground/data/eval/aok/answers/$SPLIT/$EVAL_CKPT/merge.jsonl

# Clear out the output file if it exists.
> "$output_file"

# Loop through the indices and concatenate each file.
for IDX in $(seq 0 $((CHUNKS-1))); do
    cat ./playground/data/eval/aok/answers/$SPLIT/$EVAL_CKPT/${CHUNKS}_${IDX}.jsonl >> "$output_file"
done

