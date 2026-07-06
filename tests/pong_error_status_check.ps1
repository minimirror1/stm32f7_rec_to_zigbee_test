$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/binary_com.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

if ($binaryComSource -notmatch "#define\s+BIN_PONG_PAYLOAD_SIZE\s+12u") {
    throw "PONG payload size must be 12 bytes when error_status is included"
}

if ($deviceHal -notmatch "uint8_t\s+error_status;") {
    throw "AppPingStatus must expose error_status"
}

if ($deviceHal -notmatch "error_status\(1\)") {
    throw "AppPingStatus wire format comment must include error_status(1)"
}

if ($binaryComSource -notmatch "write_u8\(p,\s*status->error_status\)") {
    throw "PONG serialization must append error_status after power_status"
}

if ($binaryComHeader -notmatch "CMD_ERROR_CLEAR\s*=\s*0x06") {
    throw "CMD_ERROR_CLEAR must be defined as 0x06"
}

if ($deviceHal -notmatch "bool\s+App_ErrorClear\s*\(\s*void\s*\)") {
    throw "device_hal.h must declare App_ErrorClear(void)"
}

if ($binaryComSource -notmatch "static\s+void\s+HandleErrorClear") {
    throw "binary_com.c must implement HandleErrorClear"
}

if ($binaryComSource -notmatch "payload_len\s*!=\s*0u") {
    throw "CMD_ERROR_CLEAR must reject non-empty payloads"
}

if ($binaryComSource -notmatch "App_ErrorClear\s*\(\s*\)") {
    throw "CMD_ERROR_CLEAR handler must call App_ErrorClear()"
}

if ($binaryComSource -notmatch "case\s+CMD_ERROR_CLEAR:") {
    throw "CMD_ERROR_CLEAR must be dispatched"
}

if ($binaryComSource -notmatch "SendBinaryResponse\s*\([^;]*CMD_ERROR_CLEAR[^;]*BIN_STATUS_OK[^;]*NULL,\s*0u\s*\)") {
    throw "CMD_ERROR_CLEAR success response must be OK with zero-length payload"
}

if ($deviceReal -notmatch "App_ErrorClear\s*\(\s*void\s*\)" -or
    $deviceReal -notmatch "g_error_status\s*=\s*0x00u\s*;") {
    throw "Weak real App_ErrorClear must clear the error status latch"
}

if ($deviceReal -notmatch "out_status->error_status\s*=\s*g_error_status\s*;") {
    throw "Weak real App_GetPingStatus must report error_status"
}

if ($deviceMock -notmatch "\.error_status\s*=\s*0x00u") {
    throw "Mock AppPingStatus should initialize error_status to normal"
}

if ($deviceMock -notmatch "mock_ping_status\.error_status\s*=\s*0x00u\s*;") {
    throw "Mock App_ErrorClear must clear PONG error_status"
}

Write-Host "PONG error_status and ErrorClear contract check passed."
