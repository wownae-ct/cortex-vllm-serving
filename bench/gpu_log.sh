#!/usr/bin/env bash
# 벤치마크 중 GPU 상태를 1초 간격으로 CSV에 기록합니다 (Ctrl+C로 종료).
# 사용: ./gpu_log.sh gpu/run3_fp8_c16.csv   (벤치 시작 전에 다른 터미널에서 실행)
# WSL에서는 nvidia-smi 가 /usr/lib/wsl/lib/ 아래에 있습니다.
set -euo pipefail
OUT="${1:-gpu_log.csv}"
mkdir -p "$(dirname "$OUT")"
nvidia-smi \
  --query-gpu=timestamp,memory.used,utilization.gpu,temperature.gpu,power.draw \
  --format=csv -l 1 > "$OUT"
