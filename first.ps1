$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/reset.ps1"

$File = "$env:TEMP\reset.ps1"

Invoke-WebRequest -Uri $Url -OutFile $File

Unblock-File -Path $File

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

& $File







# ============================================================
# PM version
# ============================================================

$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/user_setup_pm.ps1"

$FileName = [System.IO.Path]::GetFileName(([Uri]$Url).AbsolutePath)
$File = Join-Path -Path $env:TEMP -ChildPath $FileName

# 軟體名稱必須符合 user_setup_pm.ps1 中
# ApplicationDefinitions 的 DisplayName。
$ApplicationNames = @(
    "Google Chrome"
    "Mozilla Firefox"
    "Surfshark"
    "Outline Client"
    "Microsoft Sticky Notes"
    "Calculator"
    "Telegram Desktop"
    "Axure RP 10"
    "WireGuard"
)

# 執行前先清除舊檔案
if (Test-Path -LiteralPath $File) {
    Remove-Item `
        -LiteralPath $File `
        -Force `
        -ErrorAction Stop
}

try {
    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $File `
        -UseBasicParsing `
        -ErrorAction Stop

    Unblock-File `
        -LiteralPath $File `
        -ErrorAction Stop

    Set-ExecutionPolicy `
        -ExecutionPolicy Bypass `
        -Scope Process `
        -Force

    & $File `
    # -ApplicationNames $ApplicationNames

    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "執行失敗，結束代碼：$LASTEXITCODE"
    }
}
finally {
    # 執行完成或發生錯誤後，移除暫存腳本
    if (Test-Path -LiteralPath $File) {
        Remove-Item `
            -LiteralPath $File `
            -Force `
            -ErrorAction SilentlyContinue
    }
}
