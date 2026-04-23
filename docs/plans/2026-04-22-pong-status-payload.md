# PONG Status Payload Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `CMD_PING` return a `CMD_PONG` payload containing state, init state, current motion time, and total motion time.

**Architecture:** Keep `App_Ping(void)` as the liveness check, and add a separate HAL data-provider struct/function for the PONG status snapshot. `binary_com.c` will call the new provider, serialize a fixed 10-byte payload in little-endian order, and send it in the normal binary response path. Mock and weak real implementations will supply safe default values.

**Tech Stack:** STM32 C firmware, `binary_com.c`, weak HAL functions in `device_hal.h`, mock device layer in `Core/Src/device_mock.c`.

### Task 1: Add the HAL contract for PONG payload data

**Files:**
- Modify: `Lib/stm32_json_com/Inc/device_hal.h`

**Step 1: Define the expected status payload shape**

Add:
- a motion/ping status enum for `0x00..0x04`
- a struct that contains `state`, `init_state`, `current_ms`, `total_ms`
- a new `bool App_GetPingStatus(AppPingStatus *out_status)` declaration

**Step 2: Keep the contract minimal**

Rules:
- preserve `App_Ping(void)` for readiness/liveness
- keep payload generation responsibility out of app code
- require `out_status != NULL`

### Task 2: Add a failing verification target in the code path

**Files:**
- Modify: `Lib/stm32_json_com/Src/binary_com.c`

**Step 1: Change `HandlePing()` expectations**

Before implementation, update the code path so the intended behavior is explicit:
- `CMD_PONG` success should no longer be sent with `payload_len = 0`
- payload length target is `10`

**Step 2: Verify the old code still shows the gap**

Run:
`rg -n "SendBinaryResponse\\(ctx, src_id, \\(uint8_t\\)CMD_PONG, STATUS_OK, NULL, 0u\\)|HandlePing|CMD_PONG" Lib\\stm32_json_com\\Src\\binary_com.c`

Expected:
- shows the old payload-less response before the final implementation pass

### Task 3: Implement PONG payload serialization

**Files:**
- Modify: `Lib/stm32_json_com/Src/binary_com.c`

**Step 1: Add a helper to serialize the status snapshot**

Write a small helper that appends:
- `state`
- `init_state`
- `current_ms` LE
- `total_ms` LE

**Step 2: Update `HandlePing()`**

Flow:
- `App_Ping()` must still gate the response
- if alive, call `App_GetPingStatus(&status)`
- if that succeeds, send `CMD_PONG` with 10-byte payload
- if that fails, send an error response

### Task 4: Implement default HAL providers

**Files:**
- Modify: `Core/Src/device_mock.c`
- Modify: `Core/Src/device_real.c`

**Step 1: Add weak/default real implementation**

Return a safe snapshot:
- `state = STOP`
- `init_state = 0`
- `current_ms = 0`
- `total_ms = 0`

**Step 2: Add mock implementation**

Return deterministic mock values, ideally reflecting recent motion commands enough to exercise the payload.

### Task 5: Verify the final code

**Files:**
- Verify: `Lib/stm32_json_com/Inc/device_hal.h`
- Verify: `Lib/stm32_json_com/Src/binary_com.c`
- Verify: `Core/Src/device_mock.c`
- Verify: `Core/Src/device_real.c`

**Step 1: Run verification searches**

Run:
`rg -n "App_GetPingStatus|APP_PING_STATE_|current_ms|total_ms|payload_len = 10|CMD_PONG" Lib\\stm32_json_com\\Inc\\device_hal.h Lib\\stm32_json_com\\Src\\binary_com.c Core\\Src\\device_mock.c Core\\Src\\device_real.c`

Expected:
- new HAL type/function exists
- `CMD_PONG` path no longer uses `NULL, 0u`
- serialization references the 10-byte payload fields

**Step 2: Run a targeted build or compile-equivalent verification if available**

Preferred:
- build the STM32 project if a non-interactive command exists in this repo

Fallback:
- use source-level verification if no build command is available in-session
