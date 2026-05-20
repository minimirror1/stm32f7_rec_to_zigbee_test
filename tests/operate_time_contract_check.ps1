$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/binary_com.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

if ($binaryComHeader -notmatch "CMD_SET_OPERATE_TIME\s*=\s*0x30" -or
    $binaryComHeader -notmatch "CMD_GET_OPERATE_TIME\s*=\s*0x31") {
    throw "Operate-time commands must be defined as SET=0x30 and GET=0x31"
}

if ($deviceHal -notmatch "#define\s+APP_OPERATE_TIME_PAYLOAD_SIZE\s+43u") {
    throw "device_hal.h must define the 43-byte operate-time payload size"
}

if ($deviceHal -notmatch "typedef\s+struct\s*\{[^}]*uint8_t\s+day_of_week;[^}]*uint16_t\s+open_minutes;[^}]*uint16_t\s+close_minutes;[^}]*\}\s+AppOperateTimeRow;" -or
    $deviceHal -notmatch "typedef\s+struct\s*\{[^}]*uint8_t\s+format_version;[^}]*int16_t\s+timezone_offset_min;[^}]*uint32_t\s+schedule_checksum;[^}]*uint8_t\s+day_count;[^}]*AppOperateTimeRow\s+rows\[7\];[^}]*\}\s+AppOperateTimeSchedule;") {
    throw "device_hal.h must define parsed operate-time row and schedule structs"
}

if ($deviceHal -notmatch "bool\s+App_SetOperateTime\s*\(\s*const\s+uint8_t\s*\*\s*payload\s*,\s*uint16_t\s+payload_len\s*\)" -or
    $deviceHal -notmatch "bool\s+App_GetOperateTime\s*\(\s*uint8_t\s*\*\s*out_payload\s*,\s*uint16_t\s+max_len\s*,\s*uint16_t\s*\*\s*out_len\s*\)") {
    throw "device_hal.h must declare operate-time storage APIs"
}

if ($binaryComSource -notmatch "#define\s+BIN_OPERATE_TIME_PAYLOAD_SIZE\s+APP_OPERATE_TIME_PAYLOAD_SIZE" -or
    $binaryComSource -notmatch "#define\s+BIN_OPERATE_TIME_FORMAT_VERSION\s+1u" -or
    $binaryComSource -notmatch "#define\s+BIN_OPERATE_TIME_DAY_COUNT\s+7u") {
    throw "binary_com.c must define operate-time payload constants"
}

if ($binaryComSource -notmatch "static\s+bool\s+ValidateOperateTimePayload") {
    throw "binary_com.c must validate operate-time payloads before storing"
}

if ($binaryComSource -notmatch "payload_len\s*!=\s*BIN_OPERATE_TIME_PAYLOAD_SIZE" -or
    $binaryComSource -notmatch "payload\[0\]\s*!=\s*BIN_OPERATE_TIME_FORMAT_VERSION" -or
    $binaryComSource -notmatch "payload\[7\]\s*!=\s*BIN_OPERATE_TIME_DAY_COUNT") {
    throw "SET_OPERATE_TIME must reject invalid length, format_version, and day_count"
}

if ($binaryComSource -notmatch "day_of_week\s*<\s*1u\s*\|\|\s*day_of_week\s*>\s*7u") {
    throw "SET_OPERATE_TIME must reject day_of_week outside 1..7"
}

if ($binaryComSource -notmatch "App_SetOperateTime\s*\(\s*payload\s*,\s*payload_len\s*\)") {
    throw "SET_OPERATE_TIME handler must store the exact received payload"
}

if ($binaryComSource -notmatch "read_u32le\s*\(\s*payload\s*\+\s*3u\s*\)" -or
    $binaryComSource -notmatch "write_u32le\s*\(\s*resp\s*,\s*schedule_checksum\s*\)") {
    throw "SET_OPERATE_TIME OK response must echo the little-endian schedule_checksum as 4 bytes"
}

if ($binaryComSource -notmatch "App_GetOperateTime\s*\(\s*resp\s*,\s*BIN_OPERATE_TIME_PAYLOAD_SIZE\s*,\s*&resp_len\s*\)") {
    throw "GET_OPERATE_TIME handler must read the stored 43-byte payload"
}

if ($binaryComSource -notmatch "case\s+CMD_SET_OPERATE_TIME:" -or
    $binaryComSource -notmatch "case\s+CMD_GET_OPERATE_TIME:") {
    throw "Operate-time commands must be dispatched"
}

if ($deviceMock -notmatch "static\s+uint8_t\s+g_mock_operate_time_payload\[APP_OPERATE_TIME_PAYLOAD_SIZE\]" -or
    $deviceMock -notmatch "static\s+AppOperateTimeSchedule\s+g_mock_operate_time_schedule" -or
    $deviceMock -notmatch "static\s+bool\s+g_mock_operate_time_valid\s*=\s*false") {
    throw "Mock device must store operate-time payload and parsed schedule in memory"
}

if ($deviceMock -notmatch "memcpy\s*\(\s*g_mock_operate_time_payload\s*,\s*payload\s*,\s*APP_OPERATE_TIME_PAYLOAD_SIZE\s*\)" -or
    $deviceMock -notmatch "\*out_len\s*=\s*APP_OPERATE_TIME_PAYLOAD_SIZE") {
    throw "Mock SET/GET must preserve and return the exact 43-byte payload"
}

if ($deviceMock -notmatch "static\s+bool\s+ParseMockOperateTimePayload" -or
    $deviceMock -notmatch "out_schedule->format_version\s*=\s*payload\[0\]" -or
    $deviceMock -notmatch "out_schedule->timezone_offset_min\s*=\s*\(int16_t\)MockReadU16Le\s*\(\s*payload\s*\+\s*1u\s*\)" -or
    $deviceMock -notmatch "out_schedule->schedule_checksum\s*=\s*MockReadU32Le\s*\(\s*payload\s*\+\s*3u\s*\)" -or
    $deviceMock -notmatch "out_schedule->day_count\s*=\s*payload\[7\]" -or
    $deviceMock -notmatch "out_schedule->rows\[i\]\.day_of_week\s*=\s*row\[0\]" -or
    $deviceMock -notmatch "out_schedule->rows\[i\]\.open_minutes\s*=\s*MockReadU16Le\s*\(\s*row\s*\+\s*1u\s*\)" -or
    $deviceMock -notmatch "out_schedule->rows\[i\]\.close_minutes\s*=\s*MockReadU16Le\s*\(\s*row\s*\+\s*3u\s*\)" -or
    $deviceMock -notmatch "ParseMockOperateTimePayload\s*\(\s*payload\s*,\s*payload_len\s*,\s*&g_mock_operate_time_schedule\s*\)") {
    throw "Mock SET must parse the 43-byte payload into AppOperateTimeSchedule fields"
}

if ($deviceReal -notmatch "bool\s+__attribute__\(\(weak\)\)\s+App_SetOperateTime" -or
    $deviceReal -notmatch "bool\s+__attribute__\(\(weak\)\)\s+App_GetOperateTime") {
    throw "Real device must provide weak operate-time storage stubs"
}

Write-Host "Operate-time protocol contract check passed."
