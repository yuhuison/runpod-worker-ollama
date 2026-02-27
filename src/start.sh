#!/bin/bash

cleanup() {
    echo "Cleaning up..."
    if [ -n "$LLAMA_PID" ]; then
        kill "$LLAMA_PID" 2>/dev/null
        wait "$LLAMA_PID" 2>/dev/null
    fi
    pkill -P $$
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Validate model file
if [ -z "$LLAMA_ARG_MODEL" ]; then
    echo "ERROR: LLAMA_ARG_MODEL is not set."
    exit 1
fi

if [ ! -f "$LLAMA_ARG_MODEL" ]; then
    echo "ERROR: Model file not found: $LLAMA_ARG_MODEL"
    echo "Files in model directory:"
    ls -la "$(dirname "$LLAMA_ARG_MODEL")" 2>/dev/null || echo "  Directory does not exist"
    exit 1
fi

echo "Starting llama-server..."
echo "  Model: $LLAMA_ARG_MODEL"
echo "  Context size: ${LLAMA_ARG_CTX_SIZE:-default}"
echo "  GPU layers: ${LLAMA_ARG_N_GPU_LAYERS:-default}"
echo "  Flash attention: ${LLAMA_ARG_FLASH_ATTN:-default}"
echo "  Port: ${LLAMA_ARG_PORT:-8080}"
echo "  Parallel slots: ${LLAMA_ARG_N_PARALLEL:-default}"
[ -n "$LLAMA_ARG_MMPROJ" ] && echo "  Multimodal projector: $LLAMA_ARG_MMPROJ"

# llama-server reads LLAMA_ARG_* env vars automatically
/app/llama-server 2>&1 | tee /work/llama-server.log &
LLAMA_PID=$!

# Health check: wait for server to be ready
echo "Waiting for llama-server to be ready..."
MAX_RETRIES=120
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ! kill -0 "$LLAMA_PID" 2>/dev/null; then
        echo "ERROR: llama-server process died. Last log lines:"
        tail -50 /work/llama-server.log 2>/dev/null
        exit 1
    fi

    HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${LLAMA_ARG_PORT:-8080}/health 2>/dev/null)
    if [ "$HEALTH" = "200" ]; then
        echo "llama-server is ready!"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $((RETRY_COUNT % 12)) -eq 0 ]; then
        echo "  Still waiting... (${RETRY_COUNT} retries, $((RETRY_COUNT * 5))s elapsed)"
    fi
    sleep 5
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: llama-server did not become ready within $((MAX_RETRIES * 5)) seconds."
    tail -50 /work/llama-server.log 2>/dev/null
    exit 1
fi

echo "Starting RunPod handler..."
python3 -u handler.py "$1"
