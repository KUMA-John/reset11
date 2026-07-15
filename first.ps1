$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/reset.ps1"

$File = "$env:TEMP\reset.ps1"

Invoke-WebRequest -Uri $Url -OutFile $File

Unblock-File -Path $File

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

& $File









$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/user_setup.ps1"
$File = "$env:TEMP\user_setup.ps1"

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

    & $File

    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "user_setup.ps1 執行失敗，結束代碼：$LASTEXITCODE"
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
