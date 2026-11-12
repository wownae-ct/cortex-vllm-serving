# 02. systemd에서 `--limit-mm-per-prompt` 값 인식 실패

**증상**: `Value {image: 4, …} cannot be converted` 오류로 기동 직후 종료되고, 15초마다 재시작을 반복했습니다.

**원인**: systemd의 따옴표 처리가 JSON 값의 따옴표를 제거했습니다.

**조치**: 명령을 스크립트 파일([`serving/vllm-gemma.sh`](../../serving/vllm-gemma.sh))로 옮기고, 유닛의 `ExecStart`는 스크립트만 호출하도록 바꿨습니다. 유닛은 [`serving/systemd/vllm-gemma.service`](../../serving/systemd/vllm-gemma.service)입니다.
