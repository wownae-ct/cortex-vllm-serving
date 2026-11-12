#!/bin/bash
# 사용: ./summary.sh            → 전체
#       ./summary.sh run3       → 3차만
#       ./summary.sh c16        → 동시 16만
cd "$(dirname "$0")/results" || exit 1
{
  echo "회차 KV 동시 성공 출력(tok/s) TTFT평균(ms) TTFT_P99(ms) TPOT(ms)"
  # 파일명이 <회차>_<kv>_c<동시수>.json 으로 고정돼 있어 ls 출력 순회가 안전하다
  # shellcheck disable=SC2045,SC2012
  for f in $(ls *.json | grep -- "${1:-.}" | sort -t_ -k3.2n -k1,1 -k2,2); do
    IFS=_ read -r run kv c <<< "${f%.json}"
    jq -r --arg r "$run" --arg k "$kv" --arg c "${c#c}" \
      '"\($r) \($k) \($c) \(.completed) \(.output_throughput|floor) \(.mean_ttft_ms|floor) \(.p99_ttft_ms|floor) \(.mean_tpot_ms*10|floor/10)"' "$f"
  done
} | column -t
