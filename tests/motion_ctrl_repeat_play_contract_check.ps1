$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/binary_com.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

if ($binaryComHeader -notmatch "MOTION_ACTION_REPEAT_PLAY\s*=\s*0x04") {
    throw "MotionAction enum must define REPEAT_PLAY=0x04"
}

if ($deviceHal -notmatch "bool\s+App_MotionRepeatPlay\s*\(\s*uint8_t\s+device_id\s*\)") {
    throw "device_hal.h must declare App_MotionRepeatPlay(uint8_t device_id)"
}

if ($binaryComSource -notmatch "case\s+MOTION_ACTION_REPEAT_PLAY:") {
    throw "CMD_MOTION_CTRL handler must dispatch MOTION_ACTION_REPEAT_PLAY"
}

if ($binaryComSource -notmatch "App_MotionRepeatPlay\s*\(\s*ctx->my_id\s*\)") {
    throw "RepeatPlay action must call App_MotionRepeatPlay(ctx->my_id)"
}

if ($deviceReal -notmatch "App_MotionRepeatPlay\s*\(\s*uint8_t\s+device_id\s*\)") {
    throw "device_real.c must provide a weak App_MotionRepeatPlay stub"
}

if ($deviceMock -notmatch "static\s+bool\s+g_mock_motion_repeat_play") {
    throw "Mock must track repeat-play mode"
}

if ($deviceMock -notmatch "bool\s+App_MotionRepeatPlay\s*\(\s*uint8_t\s+device_id\s*\)") {
    throw "device_mock.c must implement App_MotionRepeatPlay"
}

if ($deviceMock -notmatch "g_mock_motion_repeat_play\s*=\s*true\s*;") {
    throw "App_MotionRepeatPlay must enable repeat-play mode"
}

if ($deviceMock -notmatch "g_mock_motion_repeat_play\s*=\s*false\s*;") {
    throw "Stop/Play must clear repeat-play mode"
}

if ($deviceMock -notmatch "mock_ping_status\.current_ms\s*=\s*0u\s*;\s*mock_ping_status\.state\s*=\s*APP_PING_STATE_PLAYING") {
    throw "Mock playback must rewind to 0 and continue playing at the end when repeat mode is enabled"
}

Write-Host "CMD_MOTION_CTRL RepeatPlay contract check passed."
