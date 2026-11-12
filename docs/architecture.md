# 구성

RTX 5070 Ti(16GB) 한 장이 달린 WSL2 환경에서 LLM과 임베딩을 vLLM으로 직접 서빙합니다. 하드웨어는 Ryzen 9 9950X, RAM 96GB입니다.

## 트래픽 경로

```
클라이언트(에이전트 등)
   │  Authorization: Bearer <API key>
   ▼
라우터 nginx :8008  ── 내부망·VPN 대역만 허용, 그 외 444
   ├─ /v1/embeddings ─────────▶ vLLM bge-m3   (CPU, :8011)
   ├─ /metrics/bge   ─────────▶ vLLM bge-m3   /metrics
   ├─ /metrics/gpu   ─────────▶ nvidia_gpu_exporter (:9835) /metrics
   └─ 그 외(/v1/chat/completions 등) ▶ vLLM Gemma 4 12B (GPU, :8010)

Prometheus ──▶ 라우터 :8008 의 세 경로(vllm-gemma / vllm-bge / gpu)를 10초 간격으로 수집
Grafana    ──▶ Prometheus (대시보드 uid: cortex-vllm)
```

- nginx는 API 키를 넣거나 검사하지 않습니다. Authorization 헤더가 vLLM(`--api-key`)까지 그대로 전달됩니다. ([`serving/nginx/router.conf.example`](../serving/nginx/router.conf.example))
- 스트리밍(SSE) 응답을 위해 Gemma 경로는 `proxy_buffering off`, `proxy_read_timeout 600s`입니다.
- 벤치마크와 Prometheus 수집은 모두 **라우터를 경유**합니다. vLLM 직접 호출과의 차이는 측정하지 않았습니다.

## 구성 요소

| 구성 요소 | 내용 |
|---|---|
| LLM | Gemma 4 12B QAT w4a16(`gemma-4-12B-it-qat-w4a16-ct`), GPU, 포트 8010, 서빙 이름 `gemma4-12b` |
| 임베딩 | bge-m3, CPU, 포트 8011 (`--runner pooling`, `--enforce-eager`) |
| 서빙 | vLLM 0.32.0 (GPU·CPU 빌드 각각 별도 venv), torch 2.13.0, transformers 5.19.0 |
| 운영 | systemd 유닛 3개(`vllm-gemma`, `vllm-bge`, `nvidia-gpu-exporter`) + 실행 스크립트 |
| 모니터링 | Prometheus + Grafana(k3s 위), nvidia_gpu_exporter, vLLM 내장 `/metrics`, 대시보드 JSON(패널 26개) |

## Gemma 서빙 옵션과 이유

| 옵션 | 값 | 이유 |
|---|---|---|
| `--max-model-len` | 16384 | 에이전트용 긴 컨텍스트 유지(8K로 줄이는 선택지는 제외) |
| `--gpu-memory-utilization` | 0.90 | 임베딩을 CPU로 분리해 GPU를 Gemma 전용으로 쓰고 올림 |
| `--kv-cache-dtype` | fp8 | KV 용량 약 2배. 효과는 [results.md](results.md) |
| `--limit-mm-per-prompt` | image 4, audio 1, video 0 | 시작 시 멀티모달 프로파일링 메모리를 줄이려 video만 비활성화 |
| `--reasoning-parser` / `--tool-call-parser` | gemma4 | 추론·도구 호출 파싱 |

VRAM 예산은 공식 문서의 근사치가 아니라 기동 로그의 실측(가중치 8.28 GiB)으로 다시 계산했습니다. 과정은 [troubleshooting/01](troubleshooting/01-kv-cache-startup-failure.md)입니다.

## 모니터링 대시보드

`monitoring/grafana/vllm-dashboard.json`: KV 캐시 사용률, 처리 중·대기 요청, 토큰 처리량, TTFT·ITL(P50/P95), E2E·대기열 지연(P95), 완료·선점, 프리픽스 캐시 적중률, bge-m3 요청·토큰·지연, GPU 온도·전력·사용률·VRAM. 데이터소스는 변수(`${ds}`)로 지정돼 있어 Prometheus 데이터소스만 고르면 됩니다.
