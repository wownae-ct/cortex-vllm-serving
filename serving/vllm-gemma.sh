#!/bin/bash
exec /mnt/ai/vllm-env/bin/vllm serve /mnt/ai/models/gemma-4-12B-it-qat-w4a16-ct \
  --served-model-name gemma4-12b \
  --host 0.0.0.0 --port 8010 \
  --api-key "$CORTEX_LLM_API_KEY" \
  --max-model-len 16384 \
  --gpu-memory-utilization 0.90 \
  --kv-cache-dtype fp8 \
  --limit-mm-per-prompt '{"image": 4, "audio": 1, "video": 0}' \
  --reasoning-parser gemma4 \
  --tool-call-parser gemma4 --enable-auto-tool-choice \
  --disable-uvicorn-access-log
