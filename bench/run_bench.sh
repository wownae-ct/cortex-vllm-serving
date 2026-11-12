#!/usr/bin/env bash
# vllm bench serve 로 동시 요청 수별 처리량·지연을 측정합니다.
# 셸에서 직접 돌리던 반복문을 파일로 정리한 것이며, 결과 파일명은 summary.sh 형식(<회차>_<kv>_c<동시수>.json)입니다.
#
# 사용 예:
#   BASE_URL=http://ROUTER_HOST:8008 RUN=run3 KV=fp8 ./run_bench.sh          # 동시 1 4 8 16
#   BASE_URL=http://ROUTER_HOST:8008 RUN=run3 KV=bf16 ./run_bench.sh 16       # 동시 16만
#
# 조건: 합성(random) 입력 1024 토큰 / 출력 256 토큰, 요청 수 = 동시수 x 10, 요청 속도 제한 없음(inf).
# 주의: 기본값은 라우터(nginx) 경유 측정입니다. vLLM 직접(127.0.0.1:8010) 측정과 구분해 기록하세요.
set -euo pipefail

BASE_URL="${BASE_URL:?BASE_URL 이 필요합니다 (예: http://ROUTER_HOST:8008)}"
: "${CORTEX_LLM_API_KEY:?CORTEX_LLM_API_KEY 환경변수가 필요합니다}"
export OPENAI_API_KEY="$CORTEX_LLM_API_KEY"   # bench 클라이언트가 읽는 인증 변수 (실측 당시에도 이 방식으로 주입)

MODEL="${MODEL:-gemma4-12b}"
TOKENIZER="${TOKENIZER:-/mnt/ai/models/gemma-4-12B-it-qat-w4a16-ct}"
RUN="${RUN:-run}"
KV="${KV:-fp8}"
SLEEP="${SLEEP:-30}"                       # 실행 사이 대기(초). 앞 실행의 영향을 줄이기 위함
OUT="$(cd "$(dirname "$0")" && pwd)/results"
mkdir -p "$OUT"

if [ "$#" -eq 0 ]; then set -- 1 4 8 16; fi

for c in "$@"; do
  vllm bench serve \
    --backend openai-chat \
    --base-url "$BASE_URL" \
    --model "$MODEL" \
    --tokenizer "$TOKENIZER" \
    --dataset-name random \
    --random-input-len 1024 --random-output-len 256 \
    --num-prompts $((c * 10)) \
    --max-concurrency "$c" \
    --save-result --result-dir "$OUT" \
    --result-filename "${RUN}_${KV}_c${c}.json"
  sleep "$SLEEP"
done
