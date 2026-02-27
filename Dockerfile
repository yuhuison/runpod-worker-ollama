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

# Copy model files into the image (place GGUF files in ./models/ before building)
COPY ./models /models

# ===== llama-server configuration via LLAMA_ARG_* environment variables =====
# llama-server natively reads these env vars, no CLI args needed.

ENV LLAMA_ARG_MODEL="/models/model.gguf"
ENV LLAMA_ARG_MMPROJ=""
ENV LLAMA_ARG_CTX_SIZE=131072
ENV LLAMA_ARG_N_GPU_LAYERS=99
ENV LLAMA_ARG_FLASH_ATTN=on
ENV LLAMA_ARG_HOST=127.0.0.1
ENV LLAMA_ARG_PORT=8080
ENV LLAMA_ARG_N_PARALLEL=4
ENV LLAMA_ARG_THINK_BUDGET=0
ENV LLAMA_ARG_ALIAS=""

RUN pip install --no-cache-dir --break-system-packages -r requirements.txt && chmod +x /work/start.sh

ENTRYPOINT ["/bin/bash", "-c", "/work/start.sh"]
