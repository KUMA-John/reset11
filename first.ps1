$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/reset.ps1"

$File = "$env:TEMP\reset.ps1"

Invoke-WebRequest -Uri $Url -OutFile $File

Unblock-File -Path $File

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

& $File


$Url = "https://raw.githubusercontent.com/KUMA-John/reset11/master/user-setup.ps1"
$File = "$env:TEMP\user-setup.ps1"

Invoke-WebRequest `
    -Uri $Url `
    -OutFile $File `
    -UseBasicParsing

Unblock-File -Path $File

Set-ExecutionPolicy `
    -ExecutionPolicy Bypass `
    -Scope Process `
    -Force

& $File