# cortex-vllm-serving

RTX 5070 Ti(16GB) 한 장에서 **Gemma 4 12B(QAT w4a16)**와 **bge-m3**를 vLLM으로 직접 서빙하고, VRAM·KV cache·동시성을 측정하며 설정을 조정한 기록입니다. 서빙 스크립트, systemd 유닛, 벤치 원자료(JSON), Grafana 대시보드를 파일로 확인할 수 있습니다.

## 먼저 읽을 것: 무엇을 검증했고, 무엇은 아닌가

| 검증한 것 | 근거 |
|---|---|
| 동시 1 → 16에서 출력 처리량 80 → 528 tok/s(약 6.6배), 동시 16까지 실패 0건 | [`bench/results/`](bench/results) |
| KV cache를 bf16 → fp8로 바꾸면 동시 16에서 처리량 404 → 528 tok/s(**+30.7%**), P99 TTFT 8,296 → 4,475 ms(−46%) | 같은 회차(run3) 결과 |
| 기동 실패를 공식 문서 수치가 아닌 기동 로그 실측으로 해결 | [troubleshooting/01](docs/troubleshooting/01-kv-cache-startup-failure.md) |

| 검증하지 않은 것 |
|---|
| fp8 KV의 **정확도 영향**(입력이 랜덤 토큰이라 품질 비교 불가) |
| 실제 프롬프트 분포·운영 트래픽에서의 성능. 합성 입력 1024/출력 256, 단일 GPU, 개인 랩 |
| 라우터(nginx) 오버헤드(모든 측정이 라우터 경유) |
| bf16·fp8 동시 16은 각 1회 측정 |

전체 목록은 [docs/limits.md](docs/limits.md)입니다.

## 구성

```
클라이언트 ─▶ nginx :8008 ─┬─ /v1/embeddings ▶ bge-m3 (CPU, :8011)
                           ├─ /metrics/bge, /metrics/gpu ▶ 각 exporter
                           └─ 그 외 ▶ Gemma 4 12B (GPU, :8010)
Prometheus ─▶ 라우터 경유 수집 ─▶ Grafana (대시보드 JSON 포함)
```

자세한 내용: [docs/architecture.md](docs/architecture.md)

## 저장소 구성

| 경로 | 내용 |
|---|---|
| `serving/` | `vllm-gemma.sh`, `vllm-bge.sh`, systemd 유닛 3개, `env.example`, nginx 라우터 예시 |
| `monitoring/` | Prometheus 수집 설정 예시, Grafana 대시보드(`vllm-dashboard.json`, 패널 26개) |
| `bench/` | `run_bench.sh`, `gpu_log.sh`, `summary.sh`, 결과 JSON 11개 |
| `docs/` | 구성, 벤치 방법, 결과, 한계, 트러블슈팅 3건 |

## 환경

WSL2(Ubuntu), vLLM 0.32.0(GPU·CPU 빌드), torch 2.13.0, transformers 5.19.0, NVIDIA GPU 16GB(Blackwell, fp8 KV 사용).

## 재현

1. 모델과 venv를 준비합니다(GPU용 venv에 `pip install vllm`, CPU용은 릴리스의 CPU wheel).
2. `serving/env.example`을 `.vllm.env`로 복사해 키를 채우고, 유닛의 `User=`와 경로를 환경에 맞게 바꿔 등록합니다.
3. `bench/run_bench.sh`로 측정하고 `bench/summary.sh`로 요약합니다([benchmark-method.md](docs/benchmark-method.md)).

> 이 저장소의 스크립트는 제 환경에서 쓰던 파일을 정리한 것이며, 깨끗한 환경에서의 재실행은 확인하지 않았습니다.

## 라이선스

MIT. 키·내부 주소 등 환경 정보는 포함하지 않았습니다(예시 파일은 플레이스홀더).
