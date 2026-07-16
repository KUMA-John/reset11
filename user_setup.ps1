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
        "C:\tools\snipaste\snipaste.exe"
        "$env:ChocolateyInstall\bin\Snipaste.exe"
        "$env:ProgramFiles\Snipaste\Snipaste.exe"
        "${env:ProgramFiles(x86)}\Snipaste\Snipaste.exe"
        "$env:LOCALAPPDATA\Snipaste\Snipaste.exe"
        "$env:ChocolateyInstall\lib\snipaste\tools\Snipaste.exe"
    )

    foreach ($CandidatePath in $CandidatePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($CandidatePath) -and
            (Test-Path -LiteralPath $CandidatePath -PathType Leaf)
        ) {
            return $CandidatePath
        }
    }

    $SearchRoots = @(
        "C:\tools"
        "$env:ChocolateyInstall\lib"
        "$env:LOCALAPPDATA"
        "$env:ProgramFiles"
        "${env:ProgramFiles(x86)}"
    )

    foreach ($SearchRoot in $SearchRoots) {
        if (
            [string]::IsNullOrWhiteSpace($SearchRoot) -or
            -not (Test-Path -LiteralPath $SearchRoot -PathType Container)
        ) {
            continue
        }

        $SnipasteExecutable = Get-ChildItem `
            -LiteralPath $SearchRoot `
            -Filter "Snipaste.exe" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $SnipasteExecutable) {
            return $SnipasteExecutable.FullName
        }
    }

    return $null
}

function Remove-StartupEntry {
    param (
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    $RunRegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($RegistryPath in $RunRegistryPaths) {
        if (-not (Test-Path $RegistryPath)) {
            continue
        }

        foreach ($Name in $Names) {
            try {
                $Property = Get-ItemProperty `
                    -Path $RegistryPath `
                    -Name $Name `
                    -ErrorAction SilentlyContinue

                if ($null -ne $Property) {
                    Remove-ItemProperty `
                        -Path $RegistryPath `
                        -Name $Name `
                        -Force `
                        -ErrorAction Stop

                    Write-Success (
                        "Removed startup registry entry '$Name' from $RegistryPath."
                    )
                }
            }
            catch {
                Write-Warning (
                    "Unable to remove startup registry entry " +
                    "'${Name}' from ${RegistryPath}: " +
                    $_.Exception.Message
                )
            }
        }
    }

    $StartupFolders = @(
        [Environment]::GetFolderPath("Startup")
        [Environment]::GetFolderPath("CommonStartup")
    )

    foreach ($StartupFolder in $StartupFolders) {
        if (
            [string]::IsNullOrWhiteSpace($StartupFolder) -or
            -not (Test-Path $StartupFolder)
        ) {
            continue
        }

        foreach ($Name in $Names) {
            Get-ChildItem `
                -Path $StartupFolder `
                -File `
                -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.BaseName -like "*$Name*"
                } |
                ForEach-Object {
                    try {
                        Remove-Item `
                            -Path $_.FullName `
                            -Force `
                            -ErrorAction Stop

                        Write-Success (
                            "Removed startup shortcut: " +
                            $_.FullName
                        )
                    }
                    catch {
                        Write-Warning (
                            "Unable to remove startup shortcut " +
                            "$($_.FullName): " +
                            $_.Exception.Message
                        )
                    }
                }
        }
    }
}

function Disable-StartupApprovedEntry {
    param (
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    # Binary value 03 means disabled in Startup Apps.
    $DisabledStartupValue = [byte[]](
        0x03, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    )

    $StartupApprovedPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    )

    foreach ($RegistryPath in $StartupApprovedPaths) {
        try {
            if (-not (Test-Path $RegistryPath)) {
                New-Item `
                    -Path $RegistryPath `
                    -Force | Out-Null
            }

            foreach ($Name in $Names) {
                New-ItemProperty `
                    -Path $RegistryPath `
                    -Name $Name `
                    -PropertyType Binary `
                    -Value $DisabledStartupValue `
                    -Force `
                    -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Warning (
                "Unable to update StartupApproved at ${RegistryPath}: " +
                $_.Exception.Message
            )
        }
    }
}

function Find-ApplicationExecutable {
    param (
        [Parameter(Mandatory)]
        [string[]]$CandidatePaths,

        [string[]]$SearchRoots = @(),

        [Parameter(Mandatory)]
        [string]$FileName
    )

    foreach ($CandidatePath in $CandidatePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($CandidatePath) -and
            (Test-Path $CandidatePath)
        ) {
            return $CandidatePath
        }
    }

    foreach ($SearchRoot in $SearchRoots) {
        if (
            [string]::IsNullOrWhiteSpace($SearchRoot) -or
            -not (Test-Path $SearchRoot)
        ) {
            continue
        }

        $FoundExecutable = Get-ChildItem `
            -Path $SearchRoot `
            -Filter $FileName `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $FoundExecutable) {
            return $FoundExecutable.FullName
        }
    }

    return $null
}

function Enable-ApplicationStartup {
    param (
        [Parameter(Mandatory)]
        [string]$ApplicationName,

        [Parameter(Mandatory)]
        [string]$ExecutablePath,

        [string]$Arguments = ""
    )

    if (-not (Test-Path $ExecutablePath)) {
        Write-Failure (
            "$ApplicationName executable was not found: " +
            $ExecutablePath
        )

        return
    }

    $StartupFolder = [Environment]::GetFolderPath("Startup")

    $ShortcutPath = Join-Path `
        -Path $StartupFolder `
        -ChildPath "$ApplicationName.lnk"

    New-WindowsShortcut `
        -TargetPath $ExecutablePath `
        -ShortcutPath $ShortcutPath `
        -Arguments $Arguments `
        -IconLocation "$ExecutablePath,0" | Out-Null
}

function Stop-ApplicationProcesses {
    param (
        [Parameter(Mandatory)]
        [string[]]$ProcessNames
    )

    foreach ($ProcessName in $ProcessNames) {
        Get-Process `
            -Name $ProcessName `
            -ErrorAction SilentlyContinue |
            Stop-Process `
                -Force `
                -ErrorAction SilentlyContinue
    }
}

function Find-DellCommandUpdateCli {
    $CandidatePaths = @(
        "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe"
        "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"
        "$env:ProgramFiles\Dell\CommandUpdate\DCU-CLI.exe"
        "${env:ProgramFiles(x86)}\Dell\CommandUpdate\DCU-CLI.exe"
    )

    foreach ($CandidatePath in $CandidatePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($CandidatePath) -and
            (Test-Path $CandidatePath)
        ) {
            return $CandidatePath
        }
    }

    return $null
}

function Get-OutlineClientExecutable {
    $CandidatePaths = @(
        "$env:LOCALAPPDATA\Programs\Outline Client\Outline Client.exe"
        "$env:LOCALAPPDATA\Programs\Outline\Outline.exe"
        "$env:LOCALAPPDATA\Outline\Outline.exe"
        "$env:LOCALAPPDATA\Programs\outline-client\Outline Client.exe"
        "$env:LOCALAPPDATA\Programs\outline-client\Outline.exe"
        "$env:ProgramFiles\Outline Client\Outline Client.exe"
        "$env:ProgramFiles\Outline\Outline.exe"
        "${env:ProgramFiles(x86)}\Outline Client\Outline Client.exe"
        "${env:ProgramFiles(x86)}\Outline\Outline.exe"
    )

    foreach ($CandidatePath in $CandidatePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($CandidatePath) -and
            (Test-Path -LiteralPath $CandidatePath -PathType Leaf)
        ) {
            return $CandidatePath
        }
    }

    $SearchRoots = @(
        "$env:LOCALAPPDATA\Programs"
        "$env:LOCALAPPDATA"
        "$env:ProgramFiles"
        "${env:ProgramFiles(x86)}"
    )

    $ExecutableNames = @(
        "Outline Client.exe"
        "Outline.exe"
    )

    foreach ($SearchRoot in $SearchRoots) {
        if (
            [string]::IsNullOrWhiteSpace($SearchRoot) -or
            -not (
                Test-Path `
                    -LiteralPath $SearchRoot `
                    -PathType Container
            )
        ) {
            continue
        }

        foreach ($ExecutableName in $ExecutableNames) {
            $FoundExecutable = Get-ChildItem `
                -LiteralPath $SearchRoot `
                -Filter $ExecutableName `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.FullName -match "Outline"
                } |
                Select-Object -First 1

            if ($null -ne $FoundExecutable) {
                return $FoundExecutable.FullName
            }
        }
    }

    return $null
}

function Test-OutlineClientInstalled {
    $OutlineExecutable = Get-OutlineClientExecutable

    if ($null -ne $OutlineExecutable) {
        return $true
    }

    $UninstallRegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($RegistryPath in $UninstallRegistryPaths) {
        try {
            $InstalledApplication = Get-ItemProperty `
                -Path $RegistryPath `
                -ErrorAction SilentlyContinue |
                Where-Object {
                    (
                        -not [string]::IsNullOrWhiteSpace(
                            $_.DisplayName
                        )
                    ) -and (
                        $_.DisplayName -match "^Outline(\s+Client)?$" -or
                        $_.DisplayName -like "Outline Client*"
                    )
                } |
                Select-Object -First 1

            if ($null -ne $InstalledApplication) {
                return $true
            }
        }
        catch {
            # Continue checking the other registry paths.
        }
    }

    return $false
}

function Test-IsDellComputer {
    try {
        $ComputerSystem = Get-CimInstance `
            -ClassName Win32_ComputerSystem `
            -ErrorAction Stop

        return (
            $ComputerSystem.Manufacturer -match "Dell"
        )
    }
    catch {
        return $false
    }
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
    "googlechrome"
    "firefox"
    "vcredist2015"
    
    "dotnetfx"
    "dotnet-8.0-runtime"
    "dotnet-8.0-desktopruntime"
    "picpick.portable"
    "7zip.install"
    "slack"
    "telegram"
    "snipaste"
    "element-desktop"
    "nircmd"
)

foreach ($Package in $ChocolateyPackages) {
    Install-ChocolateyPackage -PackageName $Package
}

Refresh-EnvironmentPath

$ChromePath = Find-ApplicationExecutable `
    -FileName "chrome.exe" `
    -CandidatePaths @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

$FirefoxPath = Find-ApplicationExecutable `
    -FileName "firefox.exe" `
    -CandidatePaths @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
    )

# ============================================================
# Open Surfshark browser extension pages
# ============================================================

Write-Step "Open Surfshark Browser Extensions"

$ChromeExtensionUrl =
    "https://chrome.google.com/webstore/detail/surfshark-vpn-extension/ailoabdmgclmfmhdagmlohpjlbpffblp?hl=en"

$FirefoxExtensionUrl =
    "https://addons.mozilla.org/zh-TW/firefox/addon/surfshark-vpn-proxy/"

if ($null -ne $ChromePath) {
    Start-Process `
        -FilePath $ChromePath `
        -ArgumentList $ChromeExtensionUrl

    Write-Success "Opened Surfshark extension in Google Chrome."
}
else {
    Write-Warning "Google Chrome executable could not be found."
}

if ($null -ne $FirefoxPath) {
    Start-Process `
        -FilePath $FirefoxPath `
        -ArgumentList $FirefoxExtensionUrl

    Write-Success "Opened Surfshark extension in Mozilla Firefox."
}
else {
    Write-Warning "Mozilla Firefox executable could not be found."
}

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
            --disable-interactivity
    
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WinGet sources were updated."
        }
        else {
            Write-Warning (
                "WinGet source update returned exit code " +
                "$LASTEXITCODE."
            )
        }
    }
    catch {
        Write-Warning (
            "Unable to update WinGet sources: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Failure "WinGet is still unavailable."
}


# ============================================================
# Install AnyDesk
# ============================================================

Write-Step "Install AnyDesk"

$AnyDeskInstalled = Install-WingetPackage `
    -PackageId "AnyDesk.AnyDesk" `
    -Source "winget"

if (-not $AnyDeskInstalled) {
    Write-Failure "AnyDesk installation failed."
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

$OutlineExecutable = Get-OutlineClientExecutable

if (
    (Test-OutlineClientInstalled) -and
    $null -ne $OutlineExecutable
) {
    Write-Skip "Outline Client is already installed."
    Write-Host "Outline executable: $OutlineExecutable"
}
elseif (Test-OutlineClientInstalled) {
    Write-Skip (
        "Outline Client appears to be installed, " +
        "but its executable path could not be determined."
    )
}
else {
    try {
        if (-not (
            Test-Path `
                -LiteralPath $SoftwareDirectory `
                -PathType Container
        )) {
            New-Item `
                -Path $SoftwareDirectory `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop | Out-Null
        }

        Write-Host "Downloading Outline Client..."

        Invoke-WebRequest `
            -Uri (
                "https://s3.amazonaws.com/" +
                "outline-releases/client/windows/stable/" +
                "Outline-Client.exe"
            ) `
            -OutFile $OutlineInstaller `
            -UseBasicParsing `
            -ErrorAction Stop

        Unblock-File `
            -LiteralPath $OutlineInstaller `
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

                Write-Host (
                    "Outline installer exit code: " +
                    $OutlineProcess.ExitCode
                )

                Start-Sleep -Seconds 3

                if (Test-OutlineClientInstalled) {
                    $OutlineInstalled = $true

                    $OutlineExecutable = `
                        Get-OutlineClientExecutable

                    Write-Success (
                        "Outline Client installation completed."
                    )

                    if ($null -ne $OutlineExecutable) {
                        Write-Host (
                            "Outline executable: " +
                            $OutlineExecutable
                        )
                    }
                }
                elseif ($OutlineProcess.ExitCode -eq 0) {
                    Write-Warning (
                        "The Outline installer returned exit code 0, " +
                        "but the installation could not be verified."
                    )
                }
            }
            catch {
                Write-Warning (
                    "Outline did not accept argument " +
                    "${SilentArgument}: " +
                    $_.Exception.Message
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
# Disable AnyDesk, Microsoft Teams, and OneDrive startup
# ============================================================

Write-Step "Disable Unwanted Startup Applications"

# Stop currently running processes first.
Stop-ApplicationProcesses -ProcessNames @(
    "AnyDesk"
    "ms-teams"
    "Teams"
    "OneDrive"
)

# Remove common registry and Startup folder entries.
Remove-StartupEntry -Names @(
    "AnyDesk"
    "AnyDesk.exe"
    "Teams"
    "Microsoft Teams"
    "MSTeams"
    "com.squirrel.Teams.Teams"
    "OneDrive"
    "Microsoft OneDrive"
)

# Mark common entries as disabled in Windows Startup Apps.
Disable-StartupApprovedEntry -Names @(
    "AnyDesk"
    "AnyDesk.exe"
    "Teams"
    "Microsoft Teams"
    "MSTeams"
    "com.squirrel.Teams.Teams"
    "OneDrive"
    "Microsoft OneDrive"
)

$AnyDeskService = Get-Service `
    -Name "AnyDesk" `
    -ErrorAction SilentlyContinue

if ($null -ne $AnyDeskService) {
    Stop-Service `
        -Name "AnyDesk" `
        -Force `
        -ErrorAction SilentlyContinue

    Set-Service `
        -Name "AnyDesk" `
        -StartupType Manual `
        -ErrorAction SilentlyContinue
}

# Remove OneDrive from the current user's Run registry explicitly.
$CurrentUserRunPath = `
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

if (Test-Path $CurrentUserRunPath) {
    Remove-ItemProperty `
        -Path $CurrentUserRunPath `
        -Name "OneDrive" `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-Success (
    "AnyDesk, Microsoft Teams, and OneDrive startup entries " +
    "were disabled where found."
)


# ============================================================
# Step 11: Configure Slack and Snipaste startup
# ============================================================

Write-Step "Configure Slack and Snipaste Startup"

$SlackPath = Find-ApplicationExecutable `
    -FileName "slack.exe" `
    -CandidatePaths @(
        "$env:LOCALAPPDATA\slack\slack.exe"
        "$env:LOCALAPPDATA\Programs\slack\slack.exe"
        "$env:ProgramFiles\Slack\slack.exe"
        "${env:ProgramFiles(x86)}\Slack\slack.exe"
    ) `
    -SearchRoots @(
        "$env:LOCALAPPDATA"
        "$env:ProgramFiles"
        "${env:ProgramFiles(x86)}"
        "$env:ChocolateyInstall\lib"
    )

if ($null -ne $SlackPath) {
    Enable-ApplicationStartup `
        -ApplicationName "Slack" `
        -ExecutablePath $SlackPath
}
else {
    Write-Failure "Slack executable could not be found."
}

$SnipastePath = Find-SnipasteExecutable

if ($null -ne $SnipastePath) {
    Enable-ApplicationStartup `
        -ApplicationName "Snipaste" `
        -ExecutablePath $SnipastePath
}
else {
    Write-Failure "Snipaste executable could not be found."
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
# Configure Windows 11 taskbar pins
# ============================================================

Write-Step "Configure Windows 11 Taskbar"

$CommonPrograms = [Environment]::GetFolderPath(
    "CommonPrograms"
)

$CurrentUserPrograms = [Environment]::GetFolderPath(
    "Programs"
)

$TaskbarShortcutDirectory = Join-Path `
    -Path $CommonPrograms `
    -ChildPath "Kuma Taskbar"

if (-not (Test-Path $TaskbarShortcutDirectory)) {
    New-Item `
        -Path $TaskbarShortcutDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

$ChromePath = Find-ApplicationExecutable `
    -FileName "chrome.exe" `
    -CandidatePaths @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    ) `
    -SearchRoots @()

$FirefoxPath = Find-ApplicationExecutable `
    -FileName "firefox.exe" `
    -CandidatePaths @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
    ) `
    -SearchRoots @()

$TelegramPath = Find-ApplicationExecutable `
    -FileName "Telegram.exe" `
    -CandidatePaths @(
        "$env:APPDATA\Telegram Desktop\Telegram.exe"
        "$env:LOCALAPPDATA\Programs\Telegram Desktop\Telegram.exe"
        "$env:ProgramFiles\Telegram Desktop\Telegram.exe"
        "${env:ProgramFiles(x86)}\Telegram Desktop\Telegram.exe"
    ) `
    -SearchRoots @(
        "$env:APPDATA"
        "$env:LOCALAPPDATA"
        "$env:ChocolateyInstall\lib"
    )

$ChromeShortcut = Join-Path `
    -Path $TaskbarShortcutDirectory `
    -ChildPath "Google Chrome.lnk"

$FirefoxShortcut = Join-Path `
    -Path $TaskbarShortcutDirectory `
    -ChildPath "Mozilla Firefox.lnk"

$TelegramShortcut = Join-Path `
    -Path $TaskbarShortcutDirectory `
    -ChildPath "Telegram.lnk"

if ($null -ne $ChromePath) {
    New-WindowsShortcut `
        -TargetPath $ChromePath `
        -ShortcutPath $ChromeShortcut `
        -IconLocation "$ChromePath,0" | Out-Null
}
else {
    Write-Failure "Google Chrome executable could not be found."
}

if ($null -ne $FirefoxPath) {
    New-WindowsShortcut `
        -TargetPath $FirefoxPath `
        -ShortcutPath $FirefoxShortcut `
        -IconLocation "$FirefoxPath,0" | Out-Null
}
else {
    Write-Failure "Mozilla Firefox executable could not be found."
}

if ($null -ne $TelegramPath) {
    New-WindowsShortcut `
        -TargetPath $TelegramPath `
        -ShortcutPath $TelegramShortcut `
        -IconLocation "$TelegramPath,0" | Out-Null
}
else {
    Write-Failure "Telegram executable could not be found."
}

$TaskbarLayoutDirectory = Join-Path `
    -Path $env:ProgramData `
    -ChildPath "KumaSetup"

$TaskbarLayoutPath = Join-Path `
    -Path $TaskbarLayoutDirectory `
    -ChildPath "TaskbarLayoutModification.xml"

if (-not (Test-Path $TaskbarLayoutDirectory)) {
    New-Item `
        -Path $TaskbarLayoutDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

$TaskbarXml = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
    <CustomTaskbarLayoutCollection PinListPlacement="Replace">
        <defaultlayout:TaskbarLayout>
            <taskbar:TaskbarPinList>
                <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Kuma Taskbar\Google Chrome.lnk" />
                <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Kuma Taskbar\Mozilla Firefox.lnk" />
                <taskbar:UWA AppUserModelID="Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe!App" />
                <taskbar:UWA AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
                <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Kuma Taskbar\Telegram.lnk" />
            </taskbar:TaskbarPinList>
        </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
'@

# Write UTF-8 with BOM for compatibility with Windows PowerShell 5.1.
$Utf8WithBom = New-Object System.Text.UTF8Encoding($true)

[System.IO.File]::WriteAllText(
    $TaskbarLayoutPath,
    $TaskbarXml,
    $Utf8WithBom
)

$TaskbarPolicyPath = `
    "HKCU:\Software\Policies\Microsoft\Windows\Explorer"

if (-not (Test-Path $TaskbarPolicyPath)) {
    New-Item `
        -Path $TaskbarPolicyPath `
        -Force | Out-Null
}

New-ItemProperty `
    -Path $TaskbarPolicyPath `
    -Name "StartLayoutFile" `
    -PropertyType String `
    -Value $TaskbarLayoutPath `
    -Force | Out-Null

New-ItemProperty `
    -Path $TaskbarPolicyPath `
    -Name "LockedStartLayout" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# Also copy the layout file to the current user's Shell folder.
$UserShellDirectory = Join-Path `
    -Path $env:LOCALAPPDATA `
    -ChildPath "Microsoft\Windows\Shell"

if (-not (Test-Path $UserShellDirectory)) {
    New-Item `
        -Path $UserShellDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

Copy-Item `
    -Path $TaskbarLayoutPath `
    -Destination (
        Join-Path `
            -Path $UserShellDirectory `
            -ChildPath "LayoutModification.xml"
    ) `
    -Force

Write-Success "Taskbar layout XML was created."
Write-Host "Taskbar layout: $TaskbarLayoutPath"

try {
    gpupdate.exe /target:user /force | Out-Null
}
catch {
    Write-Warning "User Group Policy refresh failed."
}

# Restart Explorer so the taskbar policy can be reloaded.
Get-Process `
    -Name "explorer" `
    -ErrorAction SilentlyContinue |
    Stop-Process `
        -Force `
        -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

Start-Process "explorer.exe"

Write-Warning (
    "If the taskbar is not updated immediately, sign out and sign in again."
)

# ============================================================
# Mute system audio
# ============================================================

Write-Step "Mute System Audio"

Refresh-EnvironmentPath

$NirCmdPath = Get-Command `
    -Name "nircmd.exe" `
    -ErrorAction SilentlyContinue

if ($null -ne $NirCmdPath) {
    & $NirCmdPath.Source mutesysvolume 1

    if ($LASTEXITCODE -eq 0) {
        Write-Success "System audio was muted."
    }
    else {
        Write-Failure (
            "NirCmd returned exit code $LASTEXITCODE."
        )
    }
}
else {
    $PossibleNirCmd = Get-ChildItem `
        -Path "$env:ChocolateyInstall\lib" `
        -Filter "nircmd.exe" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $PossibleNirCmd) {
        & $PossibleNirCmd.FullName mutesysvolume 1
        Write-Success "System audio was muted."
    }
    else {
        Write-Failure "nircmd.exe could not be found."
    }
}

# ============================================================
# Update installed applications
# ============================================================

Write-Step "Update Installed Applications"

# ------------------------------------------------------------
# Update Chocolatey itself
# ------------------------------------------------------------

if (Test-CommandAvailable -CommandName "choco.exe") {
    try {
        Write-Host "Updating Chocolatey..."

        choco upgrade chocolatey `
            -y `
            --no-progress

        if ($LASTEXITCODE -in @(0, 1641, 3010)) {
            Write-Success "Chocolatey update completed."
        }
        else {
            Write-Warning (
                "Chocolatey update returned exit code " +
                "$LASTEXITCODE."
            )
        }
    }
    catch {
        Write-Warning (
            "Chocolatey update failed: " +
            $_.Exception.Message
        )
    }

    # --------------------------------------------------------
    # Update all Chocolatey-managed applications
    # --------------------------------------------------------

    try {
        Write-Host "Updating all Chocolatey packages..."

        choco upgrade all `
            -y `
            --no-progress `
            --ignore-checksums=false

        if ($LASTEXITCODE -in @(0, 1641, 3010)) {
            Write-Success (
                "Chocolatey application updates completed."
            )

            if ($LASTEXITCODE -in @(1641, 3010)) {
                $RestartRecommended = $true
            }
        }
        else {
            Write-Warning (
                "Chocolatey package update returned exit code " +
                "$LASTEXITCODE."
            )
        }
    }
    catch {
        Write-Warning (
            "Chocolatey package update failed: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning "Chocolatey is unavailable."
}

# ------------------------------------------------------------
# Update all WinGet applications
# ------------------------------------------------------------

if (Test-CommandAvailable -CommandName "winget.exe") {
    try {
        Write-Host "Refreshing WinGet sources..."

        winget source update `
            --disable-interactivity
        
        $WingetSourceExitCode = $LASTEXITCODE
        
        if ($WingetSourceExitCode -eq 0) {
            Write-Success "WinGet sources were refreshed."
        }
        else {
            Write-Warning (
                "WinGet source update returned exit code " +
                "$WingetSourceExitCode."
            )
        }

        Write-Host "Showing available WinGet updates..."

        winget upgrade `
            --accept-source-agreements `
            --disable-interactivity

        Write-Host "Installing all WinGet updates..."

        winget upgrade `
            --all `
            --silent `
            --accept-source-agreements `
            --accept-package-agreements `
            --disable-interactivity `
            --include-unknown

        if ($LASTEXITCODE -eq 0) {
            Write-Success "WinGet application updates completed."
        }
        else {
            Write-Warning (
                "WinGet update returned exit code " +
                "$LASTEXITCODE."
            )
        }
    }
    catch {
        Write-Warning (
            "WinGet application update failed: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning "WinGet is unavailable."
}

# ============================================================
# Install and run Dell Command Update
# ============================================================

Write-Step "Install and Run Dell Command Update"

if (-not (Test-IsDellComputer)) {
    Write-Skip (
        "This computer is not identified as a Dell system. " +
        "Dell Command Update was skipped."
    )
}
else {
    Write-Success "Dell computer detected."

    # --------------------------------------------------------
    # Install or upgrade Dell Command Update
    # --------------------------------------------------------

    if (Test-CommandAvailable -CommandName "winget.exe") {
        try {
            $DellInstallArguments = @(
                "install"
                "--id"
                "Dell.CommandUpdate"
                "--exact"
                "--source"
                "winget"
                "--scope"
                "machine"
                "--silent"
                "--accept-source-agreements"
                "--accept-package-agreements"
                "--disable-interactivity"
            )

            & winget @DellInstallArguments

            $DellInstallExitCode = $LASTEXITCODE

            if ($DellInstallExitCode -eq 0) {
                Write-Success "Dell Command Update was installed."
            }
            else {
                Write-Host (
                    "Dell Command Update install returned exit code " +
                    "$DellInstallExitCode. Trying upgrade..."
                )

                $DellUpgradeArguments = @(
                    "upgrade"
                    "--id"
                    "Dell.CommandUpdate"
                    "--exact"
                    "--source"
                    "winget"
                    "--silent"
                    "--accept-source-agreements"
                    "--accept-package-agreements"
                    "--disable-interactivity"
                )

                & winget @DellUpgradeArguments

                $DellUpgradeExitCode = $LASTEXITCODE

                if ($DellUpgradeExitCode -eq 0) {
                    Write-Success (
                        "Dell Command Update upgrade completed."
                    )
                }
                else {
                    Write-Warning (
                        "Dell Command Update upgrade returned exit code " +
                        "$DellUpgradeExitCode."
                    )
                }
            }
        }
        catch {
            Write-Warning (
                "Unable to install or upgrade Dell Command Update: " +
                $_.Exception.Message
            )
        }
    }

    Refresh-EnvironmentPath
    Start-Sleep -Seconds 3

    $DellCommandUpdateCli = Find-DellCommandUpdateCli

    if ($null -eq $DellCommandUpdateCli) {
        Write-Failure "Dell Command Update CLI could not be found."
    }
    else {
        Write-Host "Dell Command Update CLI: $DellCommandUpdateCli"

        # Do not use ProgramData for DCU outputLog.
        $DellLogDirectory = "C:\KumaSetup\DellUpdate"

        try {
            if (-not (
                Test-Path `
                    -LiteralPath $DellLogDirectory `
                    -PathType Container
            )) {
                New-Item `
                    -Path $DellLogDirectory `
                    -ItemType Directory `
                    -Force `
                    -ErrorAction Stop | Out-Null
            }

            Write-Success (
                "Dell update log directory is ready: " +
                $DellLogDirectory
            )
        }
        catch {
            Write-Failure (
                "Unable to create Dell update log directory: " +
                $_.Exception.Message
            )
        }

        $DellScanLog = Join-Path `
            -Path $DellLogDirectory `
            -ChildPath "Dell-Scan.log"

        $DellApplyLog = Join-Path `
            -Path $DellLogDirectory `
            -ChildPath "Dell-Apply.log"

        # ----------------------------------------------------
        # Configure DCU
        # ----------------------------------------------------

        try {
            $DellConfigureArguments = @(
                "/configure"
                "-autoSuspendBitLocker=enable"
                "-scheduleManual"
            )

            & $DellCommandUpdateCli @DellConfigureArguments

            $DellConfigureExitCode = $LASTEXITCODE

            if ($DellConfigureExitCode -eq 0) {
                Write-Success "Dell Command Update was configured."
            }
            else {
                Write-Warning (
                    "Dell Command Update configuration returned exit code " +
                    "$DellConfigureExitCode."
                )
            }
        }
        catch {
            Write-Warning (
                "Dell Command Update configuration failed: " +
                $_.Exception.Message
            )
        }

        # ----------------------------------------------------
        # Scan Dell updates
        # ----------------------------------------------------

        Write-Host "Scanning for Dell updates..."

        try {
            if (Test-Path -LiteralPath $DellScanLog) {
                Remove-Item `
                    -LiteralPath $DellScanLog `
                    -Force `
                    -ErrorAction SilentlyContinue
            }

            $DellScanArguments = @(
                "/scan"
                "-outputLog=$DellScanLog"
            )

            & $DellCommandUpdateCli @DellScanArguments

            $DellScanExitCode = $LASTEXITCODE

            Write-Host (
                "Dell update scan exit code: " +
                $DellScanExitCode
            )

            if ($DellScanExitCode -eq 0) {
                Write-Success "Dell update scan completed."
            }
            else {
                Write-Warning (
                    "Dell update scan returned exit code " +
                    "$DellScanExitCode. Check: $DellScanLog"
                )
            }
        }
        catch {
            Write-Warning (
                "Dell update scan failed: " +
                $_.Exception.Message
            )

            $DellScanExitCode = -1
        }

        # ----------------------------------------------------
        # Apply Dell updates
        # ----------------------------------------------------

        Write-Host (
            "Applying Dell BIOS, firmware, driver, " +
            "and application updates..."
        )

        try {
            if (Test-Path -LiteralPath $DellApplyLog) {
                Remove-Item `
                    -LiteralPath $DellApplyLog `
                    -Force `
                    -ErrorAction SilentlyContinue
            }

            $DellApplyArguments = @(
                "/applyUpdates"
                "-updateType=bios,firmware,driver,application,others"
                "-updateSeverity=security,critical,recommended,optional"
                "-autoSuspendBitLocker=enable"
                "-reboot=disable"
                "-outputLog=$DellApplyLog"
            )

            & $DellCommandUpdateCli @DellApplyArguments

            $DellApplyExitCode = $LASTEXITCODE

            Write-Host (
                "Dell update apply exit code: " +
                $DellApplyExitCode
            )

            if ($DellApplyExitCode -eq 0) {
                Write-Success (
                    "Dell updates were applied successfully."
                )

                $RestartRecommended = $true
            }
            else {
                Write-Warning (
                    "Dell update installation returned exit code " +
                    "$DellApplyExitCode. Check: $DellApplyLog"
                )
            }
        }
        catch {
            Write-Warning (
                "Dell update installation failed: " +
                $_.Exception.Message
            )
        }

        # Clear the native process exit code so a noncritical DCU
        # result does not become the exit code of the whole script.
        $global:LASTEXITCODE = 0
    }
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

# Return success to the parent launcher.
$global:LASTEXITCODE = 0

exit 0