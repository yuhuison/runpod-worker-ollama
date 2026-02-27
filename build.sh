#!/bin/bash
set -euo pipefail

# ============================================================
# 在 RunPod Pod 上构建并推送包含模型的 Docker 镜像
#
# 使用方法:
#   1. 在 RunPod 上启动一个 Pod（挂载含模型的 Volume）
#   2. 克隆此仓库: git clone <repo-url> && cd <repo>
#   3. 修改下面的变量
#   4. 运行: bash build.sh
# ============================================================

# ===== 请修改以下变量 =====
# Docker Hub 用户名/镜像名
DOCKER_IMAGE="your-dockerhub-username/runpod-llama-server"
DOCKER_TAG="latest"

# 模型文件路径（Pod 上的绝对路径）
MODEL_FILE="/workspace/models/Qwen3.5-27B-heretic.Q6_K.gguf"
MMPROJ_FILE="/workspace/models/Qwen3.5-27B-heretic.mmproj-f16.gguf"
# ===========================

echo "=== Step 1: 准备 models 目录 ==="
mkdir -p models

echo "复制模型文件到构建目录（这可能需要几分钟）..."
cp -v "$MODEL_FILE" models/
if [ -n "$MMPROJ_FILE" ] && [ -f "$MMPROJ_FILE" ]; then
    cp -v "$MMPROJ_FILE" models/
fi

echo ""
echo "=== Step 2: 构建 Docker 镜像 ==="
# 获取模型文件名
MODEL_NAME=$(basename "$MODEL_FILE")
MMPROJ_NAME=$(basename "$MMPROJ_FILE")

docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t "${DOCKER_IMAGE}:${DOCKER_TAG}" \
    .

echo ""
echo "=== Step 3: 推送到 Docker Hub ==="
echo "请先登录: docker login"
docker push "${DOCKER_IMAGE}:${DOCKER_TAG}"

echo ""
echo "=== 完成! ==="
echo "镜像: ${DOCKER_IMAGE}:${DOCKER_TAG}"
echo ""
echo "在 RunPod Serverless 中使用以下环境变量:"
echo "  LLAMA_ARG_MODEL=/models/${MODEL_NAME}"
[ -n "$MMPROJ_NAME" ] && echo "  LLAMA_ARG_MMPROJ=/models/${MMPROJ_NAME}"
echo "  LLAMA_ARG_CTX_SIZE=131072"
echo "  LLAMA_ARG_N_GPU_LAYERS=99"
echo "  LLAMA_ARG_FLASH_ATTN=on"

# 清理复制的模型文件（可选，节省磁盘空间）
echo ""
read -p "是否删除构建目录中的模型副本? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf models/
    echo "已清理 models/ 目录"
fi
