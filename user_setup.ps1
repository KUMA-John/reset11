#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 user software setup script.

.DESCRIPTION
    This script performs the following tasks:

    1. Installs Chocolatey if it is not already installed.
    2. Enables Microsoft .NET Framework 3.5.
    3. Installs common applications through Chocolatey.
    4. Installs Microsoft Sticky Notes through Microsoft Store.
    5. Installs Microsoft Teams.
    6. Installs Google Japanese Input.
    7. Downloads and installs Outline Client.
    8. Creates a Calculator desktop shortcut.
    9. Creates a Snipaste startup shortcut.
    10. Configures display and sleep power settings.
    11. Opens the official Surfshark extension pages.
    12. Restarts the computer automatically unless Enter is pressed.

.NOTES
    Run this script from Windows PowerShell as Administrator.
    All comments and messages use ASCII characters only.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================
# Common functions
# ============================================================

function Write-Step {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Success {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[SKIP] $Message" -ForegroundColor DarkYellow
}

function Write-Failure {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[FAILED] $Message" -ForegroundColor Red
}

function Test-IsAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Refresh-EnvironmentPath {
    $MachinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::Machine
    )

    $UserPath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::User
    )

    $env:Path = "$MachinePath;$UserPath"
}

function Test-CommandAvailable {
    param (
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    return $null -ne (
        Get-Command $CommandName -ErrorAction SilentlyContinue
    )
}

function Install-ChocolateyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [string[]]$AdditionalArguments = @()
    )

    Write-Host "Checking Chocolatey package: $PackageName"

    $InstalledPackages = choco list --local-only --exact $PackageName `
        --limit-output 2>$null

    $AlreadyInstalled = $false

    if ($LASTEXITCODE -eq 0 -and $InstalledPackages) {
        $AlreadyInstalled = $InstalledPackages |
            Where-Object {
                $_ -match "^$([regex]::Escape($PackageName))\|"
            }

        if (-not $AlreadyInstalled) {
            $InstalledPackages = choco list --exact $PackageName `
                --limit-output 2>$null

            $AlreadyInstalled = $InstalledPackages |
                Where-Object {
                    $_ -match "^$([regex]::Escape($PackageName))\|"
                }
        }
    }

    if ($AlreadyInstalled) {
        Write-Skip "$PackageName is already installed."
        return
    }

    try {
        $Arguments = @(
            "install"
            $PackageName
            "-y"
            "--no-progress"
            "--limit-output"
        )

        if ($AdditionalArguments.Count -gt 0) {
            $Arguments += $AdditionalArguments
        }

        & choco @Arguments

        if ($LASTEXITCODE -in @(0, 1641, 3010)) {
            Write-Success "$PackageName was installed."
        }
        else {
            Write-Failure "$PackageName returned exit code $LASTEXITCODE."
        }
    }
    catch {
        Write-Failure (
            "Unable to install ${PackageName}: " +
            $_.Exception.Message
        )
    }
}

function Install-WingetPackage {
    param (
        [Parameter(Mandatory)]
        [string]$PackageId,

        [string]$Source = "winget"
    )

    if (-not (Test-CommandAvailable -CommandName "winget.exe")) {
        Write-Failure "winget.exe is not available."
        return $false
    }

    Write-Host "Checking WinGet package: $PackageId"

    & winget list `
        --id $PackageId `
        --exact `
        --accept-source-agreements `
        --disable-interactivity 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Skip "$PackageId is already installed."
        return $true
    }

    try {
        $Arguments = @(
            "install"
            "--id"
            $PackageId
            "--exact"
            "--source"
            $Source
            "--accept-source-agreements"
            "--accept-package-agreements"
            "--disable-interactivity"
            "--silent"
        )

        & winget @Arguments

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$PackageId was installed."
            return $true
        }

        Write-Failure (
            "$PackageId returned WinGet exit code $LASTEXITCODE."
        )

        return $false
    }
    catch {
        Write-Failure (
            "Unable to install ${PackageId}: " +
            $_.Exception.Message
        )

        return $false
    }
}

function New-WindowsShortcut {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [Parameter(Mandatory)]
        [string]$ShortcutPath,

        [string]$Arguments = "",

        [string]$WorkingDirectory = "",

        [string]$IconLocation = ""
    )

    try {
        $ShortcutDirectory = Split-Path `
            -Path $ShortcutPath `
            -Parent

        if (-not (Test-Path $ShortcutDirectory)) {
            New-Item `
                -Path $ShortcutDirectory `
                -ItemType Directory `
                -Force | Out-Null
        }

        $Shell = New-Object -ComObject WScript.Shell
        $Shortcut = $Shell.CreateShortcut($ShortcutPath)

        $Shortcut.TargetPath = $TargetPath

        if (-not [string]::IsNullOrWhiteSpace($Arguments)) {
            $Shortcut.Arguments = $Arguments
        }

        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
            $Shortcut.WorkingDirectory = $WorkingDirectory
        }
        else {
            $Shortcut.WorkingDirectory = Split-Path `
                -Path $TargetPath `
                -Parent
        }

        if (-not [string]::IsNullOrWhiteSpace($IconLocation)) {
            $Shortcut.IconLocation = $IconLocation
        }

        $Shortcut.Save()

        Write-Success "Shortcut created: $ShortcutPath"
        return $true
    }
    catch {
        Write-Failure (
            "Unable to create shortcut ${ShortcutPath}: " +
            $_.Exception.Message
        )

        return $false
    }
}

function Find-SnipasteExecutable {
    $CandidatePaths = @(
        "$env:ChocolateyInstall\bin\Snipaste.exe"
        "$env:ProgramFiles\Snipaste\Snipaste.exe"
        "${env:ProgramFiles(x86)}\Snipaste\Snipaste.exe"
        "$env:LOCALAPPDATA\Snipaste\Snipaste.exe"
        "$env:ChocolateyInstall\lib\snipaste\tools\Snipaste.exe"
    )

    foreach ($CandidatePath in $CandidatePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($CandidatePath) -and
            (Test-Path $CandidatePath)
        ) {
            return $CandidatePath
        }
    }

    $ChocolateySnipaste = Get-ChildItem `
        -Path "$env:ChocolateyInstall\lib" `
        -Filter "Snipaste.exe" `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $ChocolateySnipaste) {
        return $ChocolateySnipaste.FullName
    }

    return $null
}

# ============================================================
# Verify administrator privileges
# ============================================================

if (-not (Test-IsAdministrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Clear-Host

Write-Host "============================================================" -ForegroundColor Green
Write-Host " Windows 11 User Software Setup" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "User: $env:USERDOMAIN\$env:USERNAME"
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host ""

$RestartRecommended = $false

# ============================================================
# Step 1: Configure TLS and execution policy
# ============================================================

Write-Step "Step 1: Configure PowerShell Environment"

try {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor `
        [Net.SecurityProtocolType]::Tls12

    Set-ExecutionPolicy `
        -ExecutionPolicy Bypass `
        -Scope Process `
        -Force

    Write-Success "TLS 1.2 and process execution policy were configured."
}
catch {
    Write-Failure (
        "Unable to configure the PowerShell environment: " +
        $_.Exception.Message
    )
}

# ============================================================
# Step 2: Install Chocolatey
# ============================================================

Write-Step "Step 2: Install Chocolatey"

if (Test-CommandAvailable -CommandName "choco.exe") {
    Write-Skip "Chocolatey is already installed."
}
else {
    try {
        $ChocolateyInstallScript = (
            New-Object System.Net.WebClient
        ).DownloadString(
            "https://community.chocolatey.org/install.ps1"
        )

        Invoke-Expression $ChocolateyInstallScript

        Refresh-EnvironmentPath

        if (Test-CommandAvailable -CommandName "choco.exe") {
            Write-Success "Chocolatey was installed."
        }
        else {
            throw "Chocolatey was not found after installation."
        }
    }
    catch {
        Write-Error (
            "Chocolatey installation failed: " +
            $_.Exception.Message
        )

        exit 1
    }
}

choco --version

try {
    choco feature enable `
        -n allowGlobalConfirmation `
        --limit-output | Out-Null
}
catch {
    Write-Warning "Unable to enable Chocolatey global confirmation."
}

# ============================================================
# Step 3: Enable .NET Framework 3.5
# ============================================================

Write-Step "Step 3: Enable Microsoft .NET Framework 3.5"

try {
    $NetFx3Feature = Get-WindowsOptionalFeature `
        -Online `
        -FeatureName NetFx3 `
        -ErrorAction Stop

    if ($NetFx3Feature.State -eq "Enabled") {
        Write-Skip ".NET Framework 3.5 is already enabled."
    }
    else {
        Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName NetFx3 `
            -All `
            -NoRestart `
            -ErrorAction Stop | Out-Null

        Write-Success ".NET Framework 3.5 was enabled."
        $RestartRecommended = $true
    }
}
catch {
    Write-Failure (
        "Unable to enable .NET Framework 3.5: " +
        $_.Exception.Message
    )
}

# ============================================================
# Step 4: Install Chocolatey applications
# ============================================================

Write-Step "Step 4: Install Applications with Chocolatey"

$ChocolateyPackages = @(
    "vcredist2015"
    "dotnetfx"
    "dotnet-8.0-runtime"
    "firefox"
    "picpick.portable"
    "7zip.install"
    "slack"
    "telegram"
    "snipaste"
    "anydesk"
    "element-desktop"
    "googlechrome"
)

foreach ($Package in $ChocolateyPackages) {
    Install-ChocolateyPackage -PackageName $Package
}

Refresh-EnvironmentPath

# ============================================================
# Step 5: Verify or initialize WinGet
# ============================================================

Write-Step "Step 5: Verify Windows Package Manager"

if (-not (Test-CommandAvailable -CommandName "winget.exe")) {
    Write-Warning "winget.exe was not found. Attempting registration."

    try {
        Add-AppxPackage `
            -RegisterByFamilyName `
            -MainPackage `
            "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" `
            -ErrorAction Stop

        Start-Sleep -Seconds 3
        Refresh-EnvironmentPath
    }
    catch {
        Write-Failure (
            "Unable to register Windows Package Manager: " +
            $_.Exception.Message
        )
    }
}

if (Test-CommandAvailable -CommandName "winget.exe") {
    Write-Success "WinGet is available."
    winget --version

    try {
        winget source update `
            --accept-source-agreements `
            --disable-interactivity
    }
    catch {
        Write-Warning "Unable to update WinGet sources."
    }
}
else {
    Write-Failure "WinGet is still unavailable."
}

# ============================================================
# Step 6: Install Google Japanese Input
# ============================================================

Write-Step "Step 6: Install Google Japanese Input"

$JapaneseImeInstalled = Install-WingetPackage `
    -PackageId "Google.JapaneseIME" `
    -Source "winget"

if (-not $JapaneseImeInstalled) {
    Write-Warning "Opening the official Google Japanese Input page."

    Start-Process "https://www.google.co.jp/ime/"
}

# ============================================================
# Step 7: Install Microsoft Sticky Notes
# ============================================================

Write-Step "Step 7: Install Microsoft Sticky Notes"

$StickyNotesInstalled = Install-WingetPackage `
    -PackageId "9NBLGGH4QGHW" `
    -Source "msstore"

if (-not $StickyNotesInstalled) {
    Write-Warning "Opening Microsoft Sticky Notes in Microsoft Store."

    Start-Process `
        "ms-windows-store://pdp/?ProductId=9NBLGGH4QGHW"
}

# ============================================================
# Step 8: Install Microsoft Teams
# ============================================================

Write-Step "Step 8: Install Microsoft Teams"

# This package installs the new Teams client machine-wide.
Install-ChocolateyPackage `
    -PackageName "microsoft-teams-new-bootstrapper"

# ============================================================
# Step 9: Download and install Outline Client
# ============================================================

Write-Step "Step 9: Install Outline Client"

$SoftwareDirectory = "C:\Software"
$OutlineInstaller = Join-Path `
    -Path $SoftwareDirectory `
    -ChildPath "Outline-Client.exe"

try {
    if (-not (Test-Path $SoftwareDirectory)) {
        New-Item `
            -Path $SoftwareDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    Write-Host "Downloading Outline Client..."

    Invoke-WebRequest `
        -Uri "https://s3.amazonaws.com/outline-releases/client/windows/stable/Outline-Client.exe" `
        -OutFile $OutlineInstaller `
        -UseBasicParsing `
        -ErrorAction Stop

    Unblock-File `
        -Path $OutlineInstaller `
        -ErrorAction SilentlyContinue

    Write-Success "Outline Client was downloaded."

    $OutlineInstalled = $false

    $SilentArguments = @(
        "--silent"
        "/S"
        "/quiet"
    )

    foreach ($SilentArgument in $SilentArguments) {
        if ($OutlineInstalled) {
            break
        }

        try {
            Write-Host (
                "Trying Outline installation argument: " +
                $SilentArgument
            )

            $OutlineProcess = Start-Process `
                -FilePath $OutlineInstaller `
                -ArgumentList $SilentArgument `
                -Wait `
                -PassThru `
                -ErrorAction Stop

            if ($OutlineProcess.ExitCode -eq 0) {
                $OutlineInstalled = $true
                Write-Success "Outline Client installation completed."
            }
        }
        catch {
            Write-Warning (
                "Outline did not accept argument " +
                "${SilentArgument}: $($_.Exception.Message)"
            )
        }
    }

    if (-not $OutlineInstalled) {
        Write-Warning (
            "Silent installation could not be confirmed. " +
            "Opening the Outline installer."
        )

        Start-Process `
            -FilePath $OutlineInstaller `
            -ErrorAction Stop
    }
}
catch {
    Write-Failure (
        "Outline Client installation failed: " +
        $_.Exception.Message
    )
}

# ============================================================
# Step 10: Create the Calculator desktop shortcut
# ============================================================

Write-Step "Step 10: Create Calculator Desktop Shortcut"

$CalculatorPath = "$env:WINDIR\System32\calc.exe"
$PublicDesktop = [Environment]::GetFolderPath(
    "CommonDesktopDirectory"
)
$CalculatorShortcut = Join-Path `
    -Path $PublicDesktop `
    -ChildPath "Calculator.lnk"

if (Test-Path $CalculatorPath) {
    New-WindowsShortcut `
        -TargetPath $CalculatorPath `
        -ShortcutPath $CalculatorShortcut `
        -IconLocation "$CalculatorPath,0" | Out-Null
}
else {
    Write-Failure "Calculator executable was not found."
}

# ============================================================
# Step 11: Add Snipaste to the current user's startup folder
# ============================================================

Write-Step "Step 11: Configure Snipaste Startup"

$SnipastePath = Find-SnipasteExecutable

if ($null -eq $SnipastePath) {
    Write-Failure "Snipaste.exe could not be found."
}
else {
    $CurrentUserStartup = [Environment]::GetFolderPath(
        "Startup"
    )

    $SnipasteShortcut = Join-Path `
        -Path $CurrentUserStartup `
        -ChildPath "Snipaste.lnk"

    New-WindowsShortcut `
        -TargetPath $SnipastePath `
        -ShortcutPath $SnipasteShortcut `
        -IconLocation "$SnipastePath,0" | Out-Null
}

# ============================================================
# Step 12: Configure display and sleep timeouts
# ============================================================

Write-Step "Step 12: Configure Power Settings"

try {
    # Battery:
    # Turn off display after 5 minutes.
    # Put the computer to sleep after 30 minutes.

    powercfg.exe /change monitor-timeout-dc 5

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set the battery display timeout."
    }

    powercfg.exe /change standby-timeout-dc 30

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set the battery sleep timeout."
    }

    # AC power:
    # Turn off display after 30 minutes.
    # Put the computer to sleep after 5 hours.
    # The powercfg value is specified in minutes, so 5 hours is 300.

    powercfg.exe /change monitor-timeout-ac 30

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set the AC display timeout."
    }

    powercfg.exe /change standby-timeout-ac 300

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to set the AC sleep timeout."
    }

    Write-Success "Power settings were configured."

    Write-Host ""
    Write-Host "Battery display timeout: 5 minutes"
    Write-Host "Battery sleep timeout: 30 minutes"
    Write-Host "AC display timeout: 30 minutes"
    Write-Host "AC sleep timeout: 300 minutes"
}
catch {
    Write-Failure (
        "Unable to configure power settings: " +
        $_.Exception.Message
    )
}

# ============================================================
# Step 13: Open Surfshark browser extension pages
# ============================================================

Write-Step "Step 13: Configure Surfshark Browser Extensions"

$SurfsharkChromeUrl = `
    "https://chromewebstore.google.com/detail/surfshark-vpn-extension/ailoabdmgclmfmhdagmlohpjlbpffblp"

$SurfsharkFirefoxUrl = `
    "https://support.surfshark.com/hc/en-us/articles/360003090953-How-to-set-up-Surfshark-browser-extension-on-Firefox"

Write-Host (
    "Browser extension installation requires confirmation " +
    "inside each browser."
) -ForegroundColor Yellow

Write-Host (
    "The official Chrome and Firefox installation pages " +
    "will be opened."
) -ForegroundColor Yellow

try {
    Start-Process $SurfsharkChromeUrl
    Start-Sleep -Seconds 2
    Start-Process $SurfsharkFirefoxUrl

    Write-Success "Surfshark extension pages were opened."
}
catch {
    Write-Failure (
        "Unable to open Surfshark extension pages: " +
        $_.Exception.Message
    )
}

# ============================================================
# Step 14: Display results
# ============================================================

Write-Step "Step 14: Setup Results"

Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "User: $env:USERDOMAIN\$env:USERNAME"
Write-Host "Software directory: $SoftwareDirectory"
Write-Host "Calculator shortcut: $CalculatorShortcut"

if ($null -ne $SnipastePath) {
    Write-Host "Snipaste executable: $SnipastePath"
}

if ($RestartRecommended) {
    Write-Host ""
    Write-Host (
        "A restart is recommended because a Windows feature " +
        "was changed."
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Software setup has completed." -ForegroundColor Green

# ============================================================
# Step 15: Restart countdown
# ============================================================

Write-Step "Step 15: Restart Countdown"

Write-Host "The computer will restart automatically in 10 seconds." `
    -ForegroundColor Yellow

Write-Host "Press Enter within 10 seconds to cancel the restart." `
    -ForegroundColor Yellow

Write-Host ""

$RestartCancelled = $false
$CountdownSeconds = 10

try {
    for (
        $Remaining = $CountdownSeconds
        $Remaining -gt 0
        $Remaining--
    ) {
        Write-Host `
            "`rRestarting in $Remaining second(s). Press Enter to cancel.   " `
            -NoNewline `
            -ForegroundColor Yellow

        $SecondEndTime = (Get-Date).AddSeconds(1)

        while ((Get-Date) -lt $SecondEndTime) {
            if ([Console]::KeyAvailable) {
                $PressedKey = [Console]::ReadKey($true)

                if ($PressedKey.Key -eq [ConsoleKey]::Enter) {
                    $RestartCancelled = $true
                    break
                }
            }

            Start-Sleep -Milliseconds 100
        }

        if ($RestartCancelled) {
            break
        }
    }
}
catch {
    Write-Warning (
        "Interactive keyboard detection is not available. " +
        "The computer will restart after the timeout."
    )

    Start-Sleep -Seconds $CountdownSeconds
}

Write-Host ""

if ($RestartCancelled) {
    Write-Host "Automatic restart was cancelled." `
        -ForegroundColor Green
}
else {
    Write-Host "The countdown completed. Restarting now..." `
        -ForegroundColor Yellow

    Start-Sleep -Seconds 1
    Restart-Computer -Force
}