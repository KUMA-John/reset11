$Errors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    "C:\Users\user\AppData\Local\Temp\user_setup.ps1",
    [ref]$null,
    [ref]$Errors
) | Out-Null

$Errors




powershell.exe -NoProfile -Command {
    $Errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        "C:\Users\user\AppData\Local\Temp\user_setup.ps1",
        [ref]$null,
        [ref]$Errors
    ) | Out-Null

    if ($Errors.Count -eq 0) {
        Write-Host "Syntax check passed." -ForegroundColor Green
    }
    else {
        $Errors | Format-List
        exit 1
    }
}