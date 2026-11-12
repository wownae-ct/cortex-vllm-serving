# 03. CPU 임베딩 서빙에서 "Torch not compiled with CUDA enabled"

**원인**: CPU 전용 venv에 Triton(NVIDIA 백엔드)이 설치되어 있었고, WSL이 GPU 드라이버를 노출해 Triton이 CUDA 경로를 타면서 CPU 빌드 torch와 충돌했습니다.

**조치**: Triton 제거(`uv pip uninstall triton`), `--enforce-eager`, `CUDA_VISIBLE_DEVICES=""`. 유닛에는 `Environment=CUDA_VISIBLE_DEVICES=`가 들어 있습니다([`serving/systemd/vllm-bge.service`](../../serving/systemd/vllm-bge.service)). CPU wheel 이름도 `manylinux_2_39`로 맞췄습니다(문서의 `_2_35`는 404).
