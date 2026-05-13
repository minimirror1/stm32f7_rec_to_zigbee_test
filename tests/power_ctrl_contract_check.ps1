$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/binary_com.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

if ($binaryComHeader -notmatch "CMD_POWER_CTRL\s*=\s*0x05") {
    throw "CMD_POWER_CTRL must be defined as 0x05"
}

if ($binaryComHeader -notmatch "POWER_ACTION_OFF\s*=\s*0x00" -or
    $binaryComHeader -notmatch "POWER_ACTION_ON\s*=\s*0x01" -or
    $binaryComHeader -notmatch "POWER_ACTION_REBOOT\s*=\s*0x02") {
    throw "PowerAction enum must define OFF=0x00, ON=0x01, REBOOT=0x02"
}

if ($deviceHal -notmatch "bool\s+App_PowerControl\s*\(\s*uint8_t\s+action\s*\)") {
    throw "device_hal.h must declare App_PowerControl(uint8_t action)"
}

if ($binaryComSource -notmatch "static\s+void\s+HandlePowerCtrl") {
    throw "binary_com.c must implement HandlePowerCtrl"
}

if ($binaryComSource -notmatch "payload_len\s*!=\s*1u") {
    throw "CMD_POWER_CTRL must require a 1-byte payload"
}

if ($binaryComSource -notmatch "case\s+CMD_POWER_CTRL:") {
    throw "CMD_POWER_CTRL must be dispatched"
}

if ($binaryComSource -notmatch "App_PowerControl\s*\(\s*\(uint8_t\)action\s*\)") {
    throw "CMD_POWER_CTRL handler must call App_PowerControl(action)"
}

if ($binaryComSource -notmatch "SendBinaryResponse\s*\([^;]*CMD_POWER_CTRL[^;]*resp,\s*2u\s*\)") {
    throw "CMD_POWER_CTRL success response payload must be [action][accepted]"
}

if ($binaryComSource -notmatch "accepted\s*\?\s*0x01u\s*:\s*0x00u") {
    throw "CMD_POWER_CTRL accepted byte must be 0x01 on success and 0x00 when a valid action is not accepted"
}

if ($deviceReal -notmatch "power_output_off\s*\(\s*\)") {
    throw "device_real.c must implement power_output_off()"
}

if ($deviceReal -notmatch "power_output_on\s*\(\s*\)") {
    throw "device_real.c must implement power_output_on()"
}

if ($deviceReal -notmatch "HAL_GPIO_WritePin\s*\(\s*LD_PWERCTR_GPIO_Port\s*,\s*LD_PWERCTR_Pin\s*,\s*GPIO_PIN_RESET\s*\)") {
    throw "power_output_off() must drive LD_PWERCTR low"
}

if ($deviceReal -notmatch "HAL_GPIO_WritePin\s*\(\s*LD_PWERCTR_GPIO_Port\s*,\s*LD_PWERCTR_Pin\s*,\s*GPIO_PIN_SET\s*\)") {
    throw "power_output_on() must drive LD_PWERCTR high"
}

if ($deviceReal -notmatch "HAL_Delay\s*\(\s*POWER_REBOOT_DELAY_MS\s*\)") {
    throw "REBOOT must delay internally between OFF and ON"
}

if ($deviceReal -notmatch "out_status->power_status\s*=\s*g_power_status\s*;") {
    throw "PONG power_status must reflect the current real power output state"
}

if ($deviceMock -notmatch "mock_ping_status\.power_status\s*=\s*action") {
    throw "Mock App_PowerControl must update PONG power_status"
}

if ($deviceMock -match "UpdateMockPowerStatus\s*\(\s*\)\s*;") {
    throw "Mock PONG power_status must not auto-toggle after CMD_POWER_CTRL sets it"
}

Write-Host "CMD_POWER_CTRL contract check passed."
