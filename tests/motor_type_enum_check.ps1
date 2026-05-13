$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

$expected = @(
    "APP_MOTOR_TYPE_NULL\s*=\s*0x00",
    "APP_MOTOR_TYPE_RC\s*=\s*0x01",
    "APP_MOTOR_TYPE_AC\s*=\s*0x02",
    "APP_MOTOR_TYPE_BL\s*=\s*0x03",
    "APP_MOTOR_TYPE_ZER\s*=\s*0x04",
    "APP_MOTOR_TYPE_DXL\s*=\s*0x05",
    "APP_MOTOR_TYPE_AC2\s*=\s*0x06"
)

foreach ($pattern in $expected) {
    if ($deviceHal -notmatch $pattern) {
        throw "Missing expected AppMotorType entry matching: $pattern"
    }
}

if ($deviceHal -match "APP_MOTOR_TYPE_SERVO|APP_MOTOR_TYPE_DC|APP_MOTOR_TYPE_STEPPER") {
    throw "Legacy motor type enum names are still present in device_hal.h"
}

if ($deviceMock -notmatch "APP_MOTOR_TYPE_RC" -or
    $deviceMock -notmatch "APP_MOTOR_TYPE_AC" -or
    $deviceMock -notmatch "APP_MOTOR_TYPE_BL") {
    throw "Mock motor data does not exercise RC, AC, and BL motor types"
}

Write-Host "AppMotorType enum check passed."
