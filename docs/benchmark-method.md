# 벤치마크 방법

[`bench/run_bench.sh`](../bench/run_bench.sh)가 `vllm bench serve`를 동시 요청 수별로 실행합니다. 셸에서 직접 돌리던 반복문을 파일로 정리한 것입니다.

| 항목 | 값 |
|---|---|
| 클라이언트 | `vllm bench serve`, `--backend openai-chat` |
| 데이터 | `--dataset-name random`, 입력 1024 토큰, 출력 256 토큰 |
| 요청 수 | 동시 수 × 10 (동시 1·4·8·16 → 10·40·80·160) |
| 요청 속도 | 제한 없음(`inf`), 동시 수로만 제어 |
| 경로 | 라우터(nginx) 경유 |
| 실행 간격 | 10~30초 sleep |
| 결과 | JSON(`bench/results/`), 파일명 `<회차>_<kv>_c<동시수>.json` |

## 회차

| 회차 | 내용 |
|---|---|
| run1 | fp8 KV, 동시 1·4·8 |
| run2 | run1 반복(30초 간격), 동시 1·4·8 |
| run3 | bf16 KV 동시 1·4·8·16, fp8 KV 동시 16 |

fp8의 동시 1·4·8은 run2 결과를, 동시 16은 run3 결과를 bf16(run3)과 비교합니다. **같은 회차에서 fp8·bf16을 모두 돌린 것은 동시 16뿐**입니다.

## 지표

| 지표 | 의미 |
|---|---|
| 출력 처리량(tok/s) | 모든 요청의 출력 토큰 합 ÷ 소요 시간 |
| TTFT | 요청부터 첫 토큰까지. 평균과 P99 |
| TPOT | 첫 토큰 이후 토큰당 시간(ms). 작을수록 한 사용자의 생성 속도가 빠름 |
| 완료 수 | `completed` / `num_prompts`. 11개 결과 모두 100% |

## 재현

`bench/summary.sh`가 결과 JSON을 표로 요약합니다(`./summary.sh`, `./summary.sh c16`). GPU 상태를 함께 보려면 벤치 전에 다른 터미널에서 `bench/gpu_log.sh <출력.csv>`를 실행합니다(`nvidia-smi`를 1초 간격으로 기록).

```bash
export CORTEX_LLM_API_KEY=...          # 값은 저장소에 두지 않습니다
BASE_URL=http://ROUTER_HOST:8008 RUN=run3 KV=fp8 ./bench/run_bench.sh 16
```
