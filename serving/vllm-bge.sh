#!/bin/bash
exec /mnt/ai/vllm-cpu-env/bin/vllm serve /mnt/ai/models/bge-m3 \
  --served-model-name bge-m3 \
  --host 0.0.0.0 --port 8011 \
  --api-key "$CORTEX_LLM_API_KEY" \
  --runner pooling \
  --dtype bfloat16 \
  --max-model-len 8192 \
  --enforce-eager \
  --disable-uvicorn-access-log
