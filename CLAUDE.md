# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

STM32F746IGT 기반 **Binary 통신 시스템**. XBee DigiMesh를 통해 바이너리 패킷을 송수신하고, Fragment Protocol로 대용량 데이터를 분할 전송합니다.

- **타겟 MCU**: STM32F746IGT (ARM Cortex-M7, 192MHz)
- **통신**: UART1 (115200 baud) -> XBee DigiMesh
- **IDE**: STM32CubeIDE

## Build Commands

```bash
# Debug 빌드 (STM32CubeIDE 자동생성 Makefile 사용)
cd Debug && make all

# 클린 빌드
cd Debug && make clean && make all
```

빌드 결과물: `Debug/stm32f7_jsontest.elf`

## Architecture

```text
Application (device_mock.c / device_real.c)
    <-> App_* 함수 인터페이스
Communication (Lib/stm32_xbee_com/)
    - binary_com.c: Binary 명령 처리
    - xbee_api.c: XBee API Mode 2 파서
    - fragment_rx/tx.c: 대용량 메시지 분할/재조립
    - crc16.c: CRC 검증
    <->
UART Driver (uart_queue.c)
    <->
HAL Layer (STM32F7xx_HAL_Driver)
```

## Key Source Files

| 파일 | 역할 |
|------|------|
| `Core/Src/main.c` | 시스템 초기화 및 메인 루프 |
| `Core/Src/device_mock.c` | 테스트용 모의 디바이스 (`USE_MOCK_DEVICE` 정의 시) |
| `Core/Src/device_real.c` | 실제 구현을 위한 `__weak` 스텁 함수들 |
| `Lib/stm32_xbee_com/` | Binary 통신 라이브러리 (Git 서브모듈) |

## Device Implementation Pattern

`device_real.c`의 `App_*` 함수는 `__weak` 속성으로 선언됩니다. 실제 하드웨어 구현 시 오버라이드합니다.

```c
// device_real.c (기본 스텁)
__weak bool App_Ping(void) { return true; }
__weak bool App_Move(uint8_t motor_id, int32_t raw_pos) { return false; }

// 실제 구현 파일에서 오버라이드
bool App_Move(uint8_t motor_id, int32_t raw_pos) {
    // 실제 모터 제어 코드
}
```

테스트 시에는 `USE_MOCK_DEVICE` 매크로 정의로 `device_mock.c`를 사용합니다.

## Binary Protocol

- 요청 헤더(5B): `src_id(1) | tar_id(1) | cmd(1) | payload_len(2 LE)`
- 응답 헤더(6B): `src_id(1) | tar_id(1) | cmd(1) | status(1) | payload_len(2 LE)`

지원 명령은 `binary_com.h`의 `CMD_*` 정의를 기준으로 사용합니다.

## Submodule Management

```bash
# 서브모듈 초기화 (최초 클론 시)
git submodule update --init --recursive

# 서브모듈 업데이트
git submodule update --remote Lib/stm32_xbee_com
```

## Main Loop Timing

- 매 루프: `BIN_COM_Process()` - 수신 데이터 처리
- 100ms 주기: `BIN_COM_Tick()` - 타임아웃/재전송 처리
- 1000ms 주기: LED 토글 (LD_RUN, PE3)

## Preprocessor Defines

- `STM32F7`: MCU 시리즈 식별 (필수)
- `USE_MOCK_DEVICE`: 모의 디바이스 모드 활성화 (선택)

## Size Limits

- Fragment TX 버퍼: 4096 bytes
- 파일 목록: 64개
- 모터 수: 32개
