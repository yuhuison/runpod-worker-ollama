# Use llama.cpp server image with CUDA support (Ubuntu 22.04, CUDA 12.4)
FROM ghcr.io/ggml-org/llama.cpp:server-cuda

ENV PYTHONUNBUFFERED=1

WORKDIR /

# Install Python 3 and pip (server-cuda image does not include Python)
RUN apt-get update --yes --quiet && DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    bash \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

ADD ./src /work

# ===== llama-server configuration via LLAMA_ARG_* environment variables =====
# llama-server natively reads these env vars, no CLI args needed.

# Model path (GGUF file on the mounted RunPod volume)
ENV LLAMA_ARG_MODEL="/runpod-volume/models/model.gguf"
# Multimodal projector path (optional, leave empty to disable)
ENV LLAMA_ARG_MMPROJ=""
# Context size
ENV LLAMA_ARG_CTX_SIZE=131072
# Number of GPU layers to offload
ENV LLAMA_ARG_N_GPU_LAYERS=99
# Flash attention
ENV LLAMA_ARG_FLASH_ATTN=on
# Server host and port
ENV LLAMA_ARG_HOST=127.0.0.1
ENV LLAMA_ARG_PORT=8080
# Parallel request slots
ENV LLAMA_ARG_N_PARALLEL=4
# Reasoning/thinking budget (0 = disabled)
ENV LLAMA_ARG_THINK_BUDGET=0
# Model alias (used as model name in API responses, optional)
ENV LLAMA_ARG_ALIAS=""

RUN pip install --no-cache-dir --break-system-packages -r requirements.txt && chmod +x /work/start.sh

ENTRYPOINT ["/bin/bash", "-c", "/work/start.sh"]
