$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$binaryComHeader = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_json_com/Inc/binary_com.h")
$binaryComSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "Lib/stm32_json_com/Src/binary_com.c")

if ($binaryComHeader -notmatch "BIN_STATUS_OK\s*=\s*0x00") {
    throw "Missing BIN_STATUS_OK = 0x00 in BinStatus"
}

if ($binaryComHeader -notmatch "BIN_STATUS_ERROR\s*=\s*0x01") {
    throw "Missing BIN_STATUS_ERROR = 0x01 in BinStatus"
}

if ($binaryComHeader -match "\bSTATUS_OK\b|\bSTATUS_ERROR\b") {
    throw "Legacy STATUS_OK/STATUS_ERROR names are still present in binary_com.h"
}

if ($binaryComSource -match "\bSTATUS_OK\b|\bSTATUS_ERROR\b") {
    throw "Legacy STATUS_OK/STATUS_ERROR names are still present in binary_com.c"
}

Write-Host "BinStatus enum check passed."
