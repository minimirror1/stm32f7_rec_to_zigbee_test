$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_json_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_json_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

if ($binaryComSource -notmatch "#define\s+BIN_PONG_PAYLOAD_SIZE\s+11u") {
    throw "PONG payload size must be 11 bytes when power_status is included"
}

if ($deviceHal -notmatch "uint8_t\s+power_status;") {
    throw "AppPingStatus must expose power_status"
}

if ($deviceHal -notmatch "power_status\(1\)") {
    throw "AppPingStatus wire format comment must include power_status(1)"
}

if ($binaryComSource -notmatch "write_u8\(p,\s*status->power_status\)") {
    throw "PONG serialization must append power_status as the final byte"
}

if ($deviceReal -notmatch "out_status->power_status\s*=\s*0u;") {
    throw "Weak real App_GetPingStatus default must report power OFF"
}

if ($deviceMock -notmatch "\.power_status\s*=\s*1u") {
    throw "Mock AppPingStatus should report power ON"
}

Write-Host "PONG power_status contract check passed."
