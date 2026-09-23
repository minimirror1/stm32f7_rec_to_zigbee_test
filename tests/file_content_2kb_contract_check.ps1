$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/binary_com.h")
$fragmentProtocol = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/fragment_protocol.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Src/binary_com.c")
$deviceHal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_xbee_com/Inc/device_hal.h")
$deviceReal = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_real.c")
$deviceMock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Core/Src/device_mock.c")

function Get-DefineValue([string]$text, [string]$name) {
    $m = [regex]::Match($text, "#define\s+$name\s+(\d+)")
    if (-not $m.Success) {
        throw "Missing numeric #define $name"
    }
    return [int]$m.Groups[1].Value
}

if ($deviceHal -notmatch "#define\s+APP_CONTENT_MAX_LEN\s+2048\b") {
    throw "APP_CONTENT_MAX_LEN must be 2048"
}

# Worst-case GET_FILE response / SAVE_FILE request must fit the 4096-byte frame.
$contentMax = Get-DefineValue $deviceHal "APP_CONTENT_MAX_LEN"
$pathMax = Get-DefineValue $deviceHal "APP_PATH_MAX_LEN"
$txBuffer = Get-DefineValue $binaryComHeader "BIN_TX_BUFFER_SIZE"
$respHeader = Get-DefineValue $binaryComHeader "BIN_RESP_HEADER_SIZE"
$reqHeader = Get-DefineValue $binaryComHeader "BIN_REQ_HEADER_SIZE"
$fragMax = Get-DefineValue $fragmentProtocol "FRAG_MAX_MESSAGE_SIZE"

$getFileResp = $respHeader + 2 + ($pathMax - 1) + 2 + ($contentMax - 1)
$saveFileReq = $reqHeader + 2 + ($pathMax - 1) + 2 + ($contentMax - 1)
if ($getFileResp -gt $txBuffer -or $getFileResp -gt $fragMax) {
    throw "Worst-case GET_FILE response ($getFileResp B) exceeds the 4096-byte frame ceiling"
}
if ($saveFileReq -gt $fragMax) {
    throw "Worst-case SAVE_FILE request ($saveFileReq B) exceeds FRAG_MAX_MESSAGE_SIZE"
}

if ($deviceHal -notmatch "int32_t\s+App_GetFileSize\s*\(\s*const\s+char\s*\*\s*path\s*\)\s*;") {
    throw "device_hal.h must declare int32_t App_GetFileSize(const char *path)"
}

if ($deviceHal -match "char\s+buffer\[512\]") {
    throw "App_VerifyFile example must not hardcode a 512-byte buffer"
}

if ($deviceReal -notmatch "int32_t\s+__attribute__\(\(weak\)\)\s+App_GetFileSize\s*\(\s*const\s+char\s*\*\s*path\s*\)\s*\{[^}]*return\s+-1\s*;") {
    throw "Weak real App_GetFileSize must return -1 (size unknown)"
}

if ($deviceMock -notmatch "int32_t\s+App_GetFileSize\s*\(\s*const\s+char\s*\*\s*path\s*\)") {
    throw "Mock must implement App_GetFileSize"
}

$getFileMatch = [regex]::Match($binaryComSource, "(?s)static\s+void\s+HandleGetFile\s*\([^)]*\)\s*\{.*?\n\}")
if (-not $getFileMatch.Success) {
    throw "binary_com.c must implement HandleGetFile"
}
$getFileBody = $getFileMatch.Value

$sizeCall = $getFileBody.IndexOf("App_GetFileSize(path_buf)")
$readCall = $getFileBody.IndexOf("App_GetFile(path_buf")
if ($sizeCall -lt 0 -or $readCall -lt 0 -or $sizeCall -gt $readCall) {
    throw "HandleGetFile must call App_GetFileSize(path_buf) before App_GetFile"
}

# Check only the guard between the size query and the read: HandleGetFile already
# has an unrelated "Response too large" error further down.
$guard = $getFileBody.Substring($sizeCall, $readCall - $sizeCall)

if ($guard -notmatch "if\s*\(\s*file_size\s*>=\s*\(int32_t\)APP_CONTENT_MAX_LEN\s*\)") {
    throw "HandleGetFile must reject exactly file_size >= APP_CONTENT_MAX_LEN (negative = unknown, not an error)"
}

if ($guard -notmatch "(?s)SendErrorResponse\s*\([^;]*CMD_GET_FILE[^;]*ERR_RESPONSE_TOO_LARGE[^;]*\)\s*;\s*return\s*;") {
    throw "Oversized GET_FILE must answer ERR_RESPONSE_TOO_LARGE and return before App_GetFile"
}

$mockSizeMatch = [regex]::Match($deviceMock, "(?s)int32_t\s+App_GetFileSize\s*\([^)]*\)\s*\{.*?\n\}")
if (-not $mockSizeMatch.Success -or
    $mockSizeMatch.Value -notmatch "IsMockMtStPath\s*\(\s*path\s*\)" -or
    $mockSizeMatch.Value -notmatch "mock_files\[i\]\.size") {
    throw "Mock App_GetFileSize must report MT_ST content length and listed file sizes"
}

Write-Host "File content 2KB contract check passed."
