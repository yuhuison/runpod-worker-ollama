FROM ghcr.io/ggml-org/llama.cpp:server-cuda

RUN apt-get update --yes --quiet && DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    bash curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download model files from HuggingFace during build
RUN mkdir -p /models && \
    curl -L -o /models/Qwen3.5-27B-heretic.Q6_K.gguf \
      "https://huggingface.co/mradermacher/Qwen3.5-27B-heretic-GGUF/resolve/main/Qwen3.5-27B-heretic.Q6_K.gguf" && \
    curl -L -o /models/Qwen3.5-27B-heretic.mmproj-f16.gguf \
      "https://huggingface.co/mradermacher/Qwen3.5-27B-heretic-GGUF/resolve/main/Qwen3.5-27B-heretic.mmproj-f16.gguf"

ENV LLAMA_ARG_MODEL="/models/Qwen3.5-27B-heretic.Q6_K.gguf"
ENV LLAMA_ARG_MMPROJ="/models/Qwen3.5-27B-heretic.mmproj-f16.gguf"
ENV LLAMA_ARG_CTX_SIZE=131072
ENV LLAMA_ARG_N_GPU_LAYERS=99
ENV LLAMA_ARG_FLASH_ATTN=on
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080
ENV LLAMA_ARG_N_PARALLEL=4
ENV LLAMA_ARG_THINK_BUDGET=0

EXPOSE 8080
