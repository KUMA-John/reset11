$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/reset.ps1"

$File = "$env:TEMP\reset.ps1"

Invoke-WebRequest -Uri $Url -OutFile $File

Unblock-File -Path $File

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

& $File