#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 user software setup script.

.DESCRIPTION
    This script performs the following tasks:

    1. Installs Chocolatey if it is not already installed
    2. Install Chocolatey
    3. Enables Microsoft .NET Framework 3.5
    4. Installs common applications through Chocolatey
    5. Verify or initialize WinGet
    6. Install Other software
    7. Creates desktop shortcut
    8. Creates and Remove startup shortcut
    9. Configures display and sleep power settings
    10. Configure Windows 11 taskbar pins for installed applications
    11. Display results
    12. Restarts the computer automatically unless Enter is pressed

.NOTES
    Run this script from Windows PowerShell as Administrator.
    All comments and messages use ASCII characters only.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================
# 0A: Common functions
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

function Test-ApplicationInstalled {
    param (
        [string[]]$DisplayNamePatterns = @(),

        [string[]]$ExecutablePaths = @(),

        [string[]]$AppxNamePatterns = @(),

        [string[]]$ServiceNames = @()
    )

    # --------------------------------------------------------
    # Check known executable paths
    # --------------------------------------------------------

    foreach ($ExecutablePath in $ExecutablePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($ExecutablePath) -and
            (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)
        ) {
            return $true
        }
    }

    # --------------------------------------------------------
    # Check installed application registry
    # --------------------------------------------------------

    $UninstallRegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($RegistryPath in $UninstallRegistryPaths) {
        try {
            $InstalledApplications = Get-ItemProperty `
                -Path $RegistryPath `
                -ErrorAction SilentlyContinue

            foreach ($DisplayNamePattern in $DisplayNamePatterns) {
                $Match = $InstalledApplications |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace(
                            $_.DisplayName
                        ) -and
                        $_.DisplayName -like $DisplayNamePattern
                    } |
                    Select-Object -First 1

                if ($null -ne $Match) {
                    return $true
                }
            }
        }
        catch {
            # Continue checking other installation sources.
        }
    }

    # --------------------------------------------------------
    # Check Microsoft Store / AppX packages
    # --------------------------------------------------------

    foreach ($AppxNamePattern in $AppxNamePatterns) {
        try {
            $AppxPackage = Get-AppxPackage `
                -Name $AppxNamePattern `
                -ErrorAction SilentlyContinue |
                Select-Object -First 1

            if ($null -ne $AppxPackage) {
                return $true
            }
        }
        catch {
            # Continue checking other installation sources.
        }
    }

    # --------------------------------------------------------
    # Check Windows services
    # --------------------------------------------------------

    foreach ($ServiceName in $ServiceNames) {
        try {
            $Service = Get-Service `
                -Name $ServiceName `
                -ErrorAction SilentlyContinue

            if ($null -ne $Service) {
                return $true
            }
        }
        catch {
            # Continue checking other installation sources.
        }
    }

    return $false
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

function Test-ApplicationInstalledByDisplayName {
    param (
        [Parameter(Mandatory)]
        [string[]]$DisplayNamePatterns
    )

    $UninstallRegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($RegistryPath in $UninstallRegistryPaths) {
        try {
            $InstalledApplications = Get-ItemProperty `
                -Path $RegistryPath `
                -ErrorAction SilentlyContinue

            foreach ($InstalledApplication in $InstalledApplications) {
                if (
                    [string]::IsNullOrWhiteSpace(
                        $InstalledApplication.DisplayName
                    )
                ) {
                    continue
                }

                foreach ($DisplayNamePattern in $DisplayNamePatterns) {
                    if (
                        $InstalledApplication.DisplayName -like `
                            $DisplayNamePattern
                    ) {
                        return $true
                    }
                }
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
# 0B: Verify administrator privileges
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
# 0C: Configure TLS and execution policy
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
# 2: Install Chocolatey
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
# 3: Enable .NET Framework 3.5
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
# 4A: Install Chocolatey applications
# ============================================================

Write-Step "Step 4A: Install Google Chrome and Mozilla Firefox"

$BrowserPackages = @(
    "googlechrome"
    "firefox"
    "7zip.install"
)

foreach ($Package in $BrowserPackages) {
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
        "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
    )

Write-Step "Open Surfshark Browser Extensions"

$ChromeExtensionUrl = `
    "https://chrome.google.com/webstore/detail/" +
    "surfshark-vpn-extension/" +
    "ailoabdmgclmfmhdagmlohpjlbpffblp?hl=en"

$FirefoxExtensionUrl = `
    "https://addons.mozilla.org/zh-TW/firefox/addon/" +
    "surfshark-vpn-proxy/"

if (
    -not [string]::IsNullOrWhiteSpace($ChromePath) -and
    (Test-Path -LiteralPath $ChromePath -PathType Leaf)
) {
    try {
        Start-Process `
            -FilePath $ChromePath `
            -ArgumentList @($ChromeExtensionUrl) `
            -ErrorAction Stop

        Write-Success (
            "Opened the Surfshark extension page in Google Chrome."
        )
    }
    catch {
        Write-Warning (
            "Unable to open the Surfshark extension page in Chrome: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning (
        "Google Chrome was not found, so its Surfshark page " +
        "was not opened."
    )
}

if (
    -not [string]::IsNullOrWhiteSpace($FirefoxPath) -and
    (Test-Path -LiteralPath $FirefoxPath -PathType Leaf)
) {
    try {
        Start-Process `
            -FilePath $FirefoxPath `
            -ArgumentList @($FirefoxExtensionUrl) `
            -ErrorAction Stop

        Write-Success (
            "Opened the Surfshark extension page in Mozilla Firefox."
        )
    }
    catch {
        Write-Warning (
            "Unable to open the Surfshark extension page in Firefox: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning (
        "Mozilla Firefox was not found, so its Surfshark page " +
        "was not opened."
    )
}

# ============================================================
# 4B: Install remaining Chocolatey applications
# ============================================================

Write-Step "Step 4B: Install Remaining Applications with Chocolatey"

$ChocolateyPackages = @(
    "vcredist2015"
    "dotnetfx"
    "dotnet-8.0-runtime"
    "dotnet-8.0-desktopruntime"
    "telegram"
    "element-desktop"
    "nircmd"
    "wireguard"
)

foreach ($Package in $ChocolateyPackages) {
    Install-ChocolateyPackage -PackageName $Package
}

Refresh-EnvironmentPath

# ============================================================
# 5: Verify or initialize WinGet
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
# 6A: Install AnyDesk
# ============================================================

Write-Step "Install AnyDesk"

$AnyDeskInstalled = Install-WingetPackage `
    -PackageId "AnyDesk.AnyDesk" `
    -Source "winget"

if (-not $AnyDeskInstalled) {
    Write-Failure "AnyDesk installation failed."
}




# ============================================================
# 6B: Install Google Japanese Input
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
# 6C: Install Microsoft Sticky Notes
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
# 6D: Install Microsoft Teams
# ============================================================

Write-Step "Step 8: Install Microsoft Teams"

# This package installs the new Teams client machine-wide.
Install-ChocolateyPackage `
    -PackageName "microsoft-teams-new-bootstrapper"

# ============================================================
# 6E: Download and install Outline Client
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
# 6F: Download and install Surfshark
# ============================================================

Write-Step "Step 10: Install Surfshark"

$SurfsharkInstaller = Join-Path `
    -Path $SoftwareDirectory `
    -ChildPath "SurfsharkSetup.exe"

$SurfsharkDownloadUrl = `
    "https://downloads.surfshark.com/windows/latest/SurfsharkSetup.exe"

$SurfsharkInstalled = `
    Test-ApplicationInstalledByDisplayName `
        -DisplayNamePatterns @(
            "Surfshark"
            "Surfshark*"
        )

if ($SurfsharkInstalled) {
    Write-Skip "Surfshark is already installed."
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

        Write-Host "Downloading Surfshark..."

        Invoke-WebRequest `
            -Uri $SurfsharkDownloadUrl `
            -OutFile $SurfsharkInstaller `
            -UseBasicParsing `
            -ErrorAction Stop

        Unblock-File `
            -LiteralPath $SurfsharkInstaller `
            -ErrorAction SilentlyContinue

        Write-Success "Surfshark was downloaded."

        Write-Host "Installing Surfshark silently..."

        $SurfsharkProcess = Start-Process `
            -FilePath $SurfsharkInstaller `
            -ArgumentList "/exenoui /qn" `
            -Wait `
            -PassThru `
            -ErrorAction Stop

        Write-Host (
            "Surfshark installer exit code: " +
            $SurfsharkProcess.ExitCode
        )

        Start-Sleep -Seconds 5

        $SurfsharkInstalled = `
            Test-ApplicationInstalledByDisplayName `
                -DisplayNamePatterns @(
                    "Surfshark"
                    "Surfshark*"
                )

        if ($SurfsharkInstalled) {
            Write-Success "Surfshark installation completed."

            if (
                $SurfsharkProcess.ExitCode -in @(
                    1641
                    3010
                )
            ) {
                $RestartRecommended = $true
            }
        }
        else {
            Write-Warning (
                "Silent Surfshark installation could not be verified. " +
                "Opening the installer interactively."
            )

            Start-Process `
                -FilePath $SurfsharkInstaller `
                -ErrorAction Stop
        }
    }
    catch {
        Write-Failure (
            "Surfshark installation failed: " +
            $_.Exception.Message
        )

        if (
            Test-Path `
                -LiteralPath $SurfsharkInstaller `
                -PathType Leaf
        ) {
            try {
                Write-Warning (
                    "Opening the downloaded Surfshark installer."
                )

                Start-Process `
                    -FilePath $SurfsharkInstaller `
                    -ErrorAction Stop
            }
            catch {
                Write-Failure (
                    "Unable to open the Surfshark installer: " +
                    $_.Exception.Message
                )
            }
        }
    }
}

# ============================================================
# 6G: Download and install Axure RP 10
# ============================================================

Write-Step "Step 11: Install Axure RP 10"

$AxureRp10Version = "10.0.0.3929"
$AxureRp10Build = "3929"

$AxureRp10Installer = Join-Path `
    -Path $SoftwareDirectory `
    -ChildPath "AxureRP-Setup-$AxureRp10Build.exe"

$AxureRp10DownloadUrl = (
    "https://axure.cachefly.net/versions/10-0/" +
    "AxureRP-Setup-$AxureRp10Build.exe"
)

$AxureRp10Installed = `
    Test-ApplicationInstalledByDisplayName `
        -DisplayNamePatterns @(
            "Axure RP 10"
            "Axure RP 10*"
        )

if ($AxureRp10Installed) {
    Write-Skip "Axure RP 10 is already installed."
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

        Write-Host (
            "Downloading Axure RP $AxureRp10Version..."
        )

        Invoke-WebRequest `
            -Uri $AxureRp10DownloadUrl `
            -OutFile $AxureRp10Installer `
            -UseBasicParsing `
            -ErrorAction Stop

        Unblock-File `
            -LiteralPath $AxureRp10Installer `
            -ErrorAction SilentlyContinue

        Write-Success (
            "Axure RP $AxureRp10Version was downloaded."
        )

        $AxureInstallLog = Join-Path `
            -Path $env:TEMP `
            -ChildPath "AxureRP10-Install.log"

        $AxureInstallArguments = @(
            "/passive"
            "/qr"
            "/norestart"
            "/log"
            "`"$AxureInstallLog`""
            "LaunchAxureRp=0"
        )

        Write-Host "Installing Axure RP 10 silently..."

        $AxureRp10Process = Start-Process `
            -FilePath $AxureRp10Installer `
            -ArgumentList $AxureInstallArguments `
            -Wait `
            -PassThru `
            -ErrorAction Stop

        Write-Host (
            "Axure RP 10 installer exit code: " +
            $AxureRp10Process.ExitCode
        )

        Start-Sleep -Seconds 5

        $AxureRp10Installed = `
            Test-ApplicationInstalledByDisplayName `
                -DisplayNamePatterns @(
                    "Axure RP 10"
                    "Axure RP 10*"
                )

        if ($AxureRp10Installed) {
            Write-Success "Axure RP 10 installation completed."

            if (
                $AxureRp10Process.ExitCode -in @(
                    1641
                    3010
                )
            ) {
                $RestartRecommended = $true
            }
        }
        else {
            Write-Warning (
                "Silent Axure RP 10 installation could not be " +
                "verified. Opening the installer interactively."
            )

            Start-Process `
                -FilePath $AxureRp10Installer `
                -ErrorAction Stop
        }
    }
    catch {
        Write-Failure (
            "Axure RP 10 installation failed: " +
            $_.Exception.Message
        )

        if (
            Test-Path `
                -LiteralPath $AxureRp10Installer `
                -PathType Leaf
        ) {
            try {
                Write-Warning (
                    "Opening the downloaded Axure RP 10 installer."
                )

                Start-Process `
                    -FilePath $AxureRp10Installer `
                    -ErrorAction Stop
            }
            catch {
                Write-Failure (
                    "Unable to open the Axure RP 10 installer: " +
                    $_.Exception.Message
                )
            }
        }
    }
}

# ============================================================
# 7A: Create the Calculator desktop shortcut
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
# 7B: Create Remote Desktop Connection shortcut
# ============================================================

Write-Step "Step 12: Create Remote Desktop Connection Shortcut"

$RemoteDesktopPath = Join-Path `
    -Path $env:WINDIR `
    -ChildPath "System32\mstsc.exe"

$PublicDesktop = [Environment]::GetFolderPath(
    "CommonDesktopDirectory"
)

$RemoteDesktopShortcut = Join-Path `
    -Path $PublicDesktop `
    -ChildPath "Remote Desktop Connection.lnk"

if (
    Test-Path `
        -LiteralPath $RemoteDesktopPath `
        -PathType Leaf
) {
    New-WindowsShortcut `
        -TargetPath $RemoteDesktopPath `
        -ShortcutPath $RemoteDesktopShortcut `
        -WorkingDirectory (
            Split-Path `
                -Path $RemoteDesktopPath `
                -Parent
        ) `
        -IconLocation "$RemoteDesktopPath,0" | Out-Null
}
else {
    Write-Failure (
        "Remote Desktop Connection executable was not found: " +
        $RemoteDesktopPath
    )
}

# ============================================================
# 8A: Disable installed AnyDesk, Microsoft Teams, and OneDrive
# startup entries
# ============================================================

Write-Step "Disable Installed Unwanted Startup Applications"

# ------------------------------------------------------------
# Detect AnyDesk
# ------------------------------------------------------------

$AnyDeskInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "AnyDesk*"
    ) `
    -ExecutablePaths @(
        "$env:ProgramFiles\AnyDesk\AnyDesk.exe"
        "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe"
        "$env:LOCALAPPDATA\AnyDesk\AnyDesk.exe"
        "$env:APPDATA\AnyDesk\AnyDesk.exe"
    ) `
    -ServiceNames @(
        "AnyDesk"
    )

if ($AnyDeskInstalled) {
    Write-Host "AnyDesk is installed. Disabling startup."

    Stop-ApplicationProcesses `
        -ProcessNames @(
            "AnyDesk"
        )

    Remove-StartupEntry `
        -Names @(
            "AnyDesk"
            "AnyDesk.exe"
        )

    Disable-StartupApprovedEntry `
        -Names @(
            "AnyDesk"
            "AnyDesk.exe"
        )

    $AnyDeskService = Get-Service `
        -Name "AnyDesk" `
        -ErrorAction SilentlyContinue

    if ($null -ne $AnyDeskService) {
        try {
            if ($AnyDeskService.Status -ne "Stopped") {
                Stop-Service `
                    -Name "AnyDesk" `
                    -Force `
                    -ErrorAction Stop
            }

            Set-Service `
                -Name "AnyDesk" `
                -StartupType Manual `
                -ErrorAction Stop

            Write-Success (
                "AnyDesk service startup type was set to Manual."
            )
        }
        catch {
            Write-Warning (
                "Unable to configure the AnyDesk service: " +
                $_.Exception.Message
            )
        }
    }

    Write-Success "AnyDesk startup was disabled."
}
else {
    Write-Skip (
        "AnyDesk is not installed. Startup configuration was skipped."
    )
}

# ------------------------------------------------------------
# Detect Microsoft Teams
# ------------------------------------------------------------

$TeamsInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Microsoft Teams*"
        "Teams Machine-Wide Installer*"
    ) `
    -ExecutablePaths @(
        "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\ms-teams.exe"
        "$env:ProgramFiles\WindowsApps\MSTeams_*\ms-teams.exe"
    ) `
    -AppxNamePatterns @(
        "MSTeams"
        "MicrosoftTeams"
    )

if ($TeamsInstalled) {
    Write-Host "Microsoft Teams is installed. Disabling startup."

    Stop-ApplicationProcesses `
        -ProcessNames @(
            "ms-teams"
            "Teams"
        )

    Remove-StartupEntry `
        -Names @(
            "Teams"
            "Microsoft Teams"
            "MSTeams"
            "com.squirrel.Teams.Teams"
        )

    Disable-StartupApprovedEntry `
        -Names @(
            "Teams"
            "Microsoft Teams"
            "MSTeams"
            "com.squirrel.Teams.Teams"
        )

    Write-Success "Microsoft Teams startup was disabled."
}
else {
    Write-Skip (
        "Microsoft Teams is not installed. " +
        "Startup configuration was skipped."
    )
}

# ------------------------------------------------------------
# Detect Microsoft OneDrive
# ------------------------------------------------------------

$OneDriveInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Microsoft OneDrive*"
    ) `
    -ExecutablePaths @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe"
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
        "$env:SystemRoot\System32\OneDriveSetup.exe"
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    )

if ($OneDriveInstalled) {
    Write-Host "Microsoft OneDrive is installed. Disabling startup."

    Stop-ApplicationProcesses `
        -ProcessNames @(
            "OneDrive"
        )

    Remove-StartupEntry `
        -Names @(
            "OneDrive"
            "Microsoft OneDrive"
        )

    Disable-StartupApprovedEntry `
        -Names @(
            "OneDrive"
            "Microsoft OneDrive"
        )

    $CurrentUserRunPath = `
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

    if (Test-Path $CurrentUserRunPath) {
        Remove-ItemProperty `
            -Path $CurrentUserRunPath `
            -Name "OneDrive" `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Write-Success "Microsoft OneDrive startup was disabled."
}
else {
    Write-Skip (
        "Microsoft OneDrive is not installed. " +
        "Startup configuration was skipped."
    )
}

# ============================================================
# 8B: Configure installed Slack and Snipaste startup
# ============================================================

Write-Step "Step 11: Configure Installed Slack and Snipaste Startup"

# ------------------------------------------------------------
# Detect and configure Slack
# ------------------------------------------------------------

$SlackInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Slack*"
    ) `
    -ExecutablePaths @(
        "$env:LOCALAPPDATA\slack\slack.exe"
        "$env:LOCALAPPDATA\Programs\slack\slack.exe"
        "$env:ProgramFiles\Slack\slack.exe"
        "${env:ProgramFiles(x86)}\Slack\slack.exe"
    ) `
    -AppxNamePatterns @(
        "*Slack*"
    )

if ($SlackInstalled) {
    $SlackPath = Find-ApplicationExecutable `
        -FileName "slack.exe" `
        -CandidatePaths @(
            "$env:LOCALAPPDATA\slack\slack.exe"
            "$env:LOCALAPPDATA\Programs\slack\slack.exe"
            "$env:ProgramFiles\Slack\slack.exe"
            "${env:ProgramFiles(x86)}\Slack\slack.exe"
        ) `
        -SearchRoots @(
            "$env:LOCALAPPDATA\slack"
            "$env:LOCALAPPDATA\Programs"
            "$env:ProgramFiles\Slack"
            "${env:ProgramFiles(x86)}\Slack"
            "$env:ChocolateyInstall\lib\slack"
        )

    if ($null -ne $SlackPath) {
        Enable-ApplicationStartup `
            -ApplicationName "Slack" `
            -ExecutablePath $SlackPath

        Write-Success "Slack startup was configured."
    }
    else {
        Write-Warning (
            "Slack appears to be installed, but slack.exe " +
            "could not be found. Startup was not configured."
        )
    }
}
else {
    $SlackPath = $null

    Write-Skip (
        "Slack is not installed. Startup configuration was skipped."
    )
}

# ------------------------------------------------------------
# Detect and configure Snipaste
# ------------------------------------------------------------

$SnipasteInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Snipaste*"
    ) `
    -ExecutablePaths @(
        "C:\tools\snipaste\Snipaste.exe"
        "C:\tools\snipaste\snipaste.exe"
        "$env:ChocolateyInstall\bin\Snipaste.exe"
        "$env:ProgramFiles\Snipaste\Snipaste.exe"
        "${env:ProgramFiles(x86)}\Snipaste\Snipaste.exe"
        "$env:LOCALAPPDATA\Snipaste\Snipaste.exe"
        "$env:ChocolateyInstall\lib\snipaste\tools\Snipaste.exe"
    ) `
    -AppxNamePatterns @(
        "*Snipaste*"
    )

if ($SnipasteInstalled) {
    $SnipastePath = Find-SnipasteExecutable

    if ($null -ne $SnipastePath) {
        Enable-ApplicationStartup `
            -ApplicationName "Snipaste" `
            -ExecutablePath $SnipastePath

        Write-Success "Snipaste startup was configured."
    }
    else {
        Write-Warning (
            "Snipaste appears to be installed, but Snipaste.exe " +
            "could not be found. Startup was not configured."
        )
    }
}
else {
    $SnipastePath = $null

    Write-Skip (
        "Snipaste is not installed. Startup configuration was skipped."
    )
}

# ============================================================
# 9: Configure display and sleep timeouts
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
# 10: Configure Windows 11 taskbar pins for installed applications
# ============================================================

Write-Step "Configure Windows 11 Taskbar for Installed Applications"

$CommonPrograms = [Environment]::GetFolderPath(
    "CommonPrograms"
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

# This array contains only applications that were actually detected.
$TaskbarPinEntries = @()

# ------------------------------------------------------------
# Detect Google Chrome
# ------------------------------------------------------------

$ChromeInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Google Chrome*"
    ) `
    -ExecutablePaths @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

if ($ChromeInstalled) {
    $ChromePath = Find-ApplicationExecutable `
        -FileName "chrome.exe" `
        -CandidatePaths @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        ) `
        -SearchRoots @()

    if ($null -ne $ChromePath) {
        $ChromeShortcut = Join-Path `
            -Path $TaskbarShortcutDirectory `
            -ChildPath "Google Chrome.lnk"

        $ChromeShortcutCreated = New-WindowsShortcut `
            -TargetPath $ChromePath `
            -ShortcutPath $ChromeShortcut `
            -IconLocation "$ChromePath,0"

        if ($ChromeShortcutCreated) {
            $TaskbarPinEntries += (
                '                <taskbar:DesktopApp ' +
                'DesktopApplicationLinkPath="' +
                '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\' +
                'Programs\Kuma Taskbar\Google Chrome.lnk" />'
            )

            Write-Success "Google Chrome was added to the taskbar layout."
        }
    }
    else {
        Write-Warning (
            "Google Chrome appears to be installed, but chrome.exe " +
            "could not be found."
        )
    }
}
else {
    Write-Skip (
        "Google Chrome is not installed. Taskbar pin was skipped."
    )
}

# ------------------------------------------------------------
# Detect Mozilla Firefox
# ------------------------------------------------------------

$FirefoxInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Mozilla Firefox*"
    ) `
    -ExecutablePaths @(
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
        "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
    )

if ($FirefoxInstalled) {
    $FirefoxPath = Find-ApplicationExecutable `
        -FileName "firefox.exe" `
        -CandidatePaths @(
            "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
            "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
            "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
        ) `
        -SearchRoots @()

    if ($null -ne $FirefoxPath) {
        $FirefoxShortcut = Join-Path `
            -Path $TaskbarShortcutDirectory `
            -ChildPath "Mozilla Firefox.lnk"

        $FirefoxShortcutCreated = New-WindowsShortcut `
            -TargetPath $FirefoxPath `
            -ShortcutPath $FirefoxShortcut `
            -IconLocation "$FirefoxPath,0"

        if ($FirefoxShortcutCreated) {
            $TaskbarPinEntries += (
                '                <taskbar:DesktopApp ' +
                'DesktopApplicationLinkPath="' +
                '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\' +
                'Programs\Kuma Taskbar\Mozilla Firefox.lnk" />'
            )

            Write-Success "Mozilla Firefox was added to the taskbar layout."
        }
    }
    else {
        Write-Warning (
            "Mozilla Firefox appears to be installed, but firefox.exe " +
            "could not be found."
        )
    }
}
else {
    Write-Skip (
        "Mozilla Firefox is not installed. Taskbar pin was skipped."
    )
}

# ------------------------------------------------------------
# Detect Microsoft Sticky Notes
# ------------------------------------------------------------

$StickyNotesInstalledForTaskbar = Test-ApplicationInstalled `
    -AppxNamePatterns @(
        "Microsoft.MicrosoftStickyNotes"
    )

if ($StickyNotesInstalledForTaskbar) {
    $TaskbarPinEntries += (
        '                <taskbar:UWA ' +
        'AppUserModelID="' +
        'Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe!App" />'
    )

    Write-Success "Microsoft Sticky Notes was added to the taskbar layout."
}
else {
    Write-Skip (
        "Microsoft Sticky Notes is not installed. " +
        "Taskbar pin was skipped."
    )
}

# ------------------------------------------------------------
# Detect Windows Calculator
# ------------------------------------------------------------

$CalculatorInstalledForTaskbar = Test-ApplicationInstalled `
    -ExecutablePaths @(
        "$env:WINDIR\System32\calc.exe"
    ) `
    -AppxNamePatterns @(
        "Microsoft.WindowsCalculator"
    )

if ($CalculatorInstalledForTaskbar) {
    $TaskbarPinEntries += (
        '                <taskbar:UWA ' +
        'AppUserModelID="' +
        'Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />'
    )

    Write-Success "Windows Calculator was added to the taskbar layout."
}
else {
    Write-Skip (
        "Windows Calculator is not installed. Taskbar pin was skipped."
    )
}

# ------------------------------------------------------------
# Detect Telegram
# ------------------------------------------------------------

$TelegramInstalled = Test-ApplicationInstalled `
    -DisplayNamePatterns @(
        "Telegram Desktop*"
        "Telegram*"
    ) `
    -ExecutablePaths @(
        "$env:APPDATA\Telegram Desktop\Telegram.exe"
        "$env:LOCALAPPDATA\Programs\Telegram Desktop\Telegram.exe"
        "$env:ProgramFiles\Telegram Desktop\Telegram.exe"
        "${env:ProgramFiles(x86)}\Telegram Desktop\Telegram.exe"
    ) `
    -AppxNamePatterns @(
        "*Telegram*"
    )

if ($TelegramInstalled) {
    $TelegramPath = Find-ApplicationExecutable `
        -FileName "Telegram.exe" `
        -CandidatePaths @(
            "$env:APPDATA\Telegram Desktop\Telegram.exe"
            "$env:LOCALAPPDATA\Programs\Telegram Desktop\Telegram.exe"
            "$env:ProgramFiles\Telegram Desktop\Telegram.exe"
            "${env:ProgramFiles(x86)}\Telegram Desktop\Telegram.exe"
        ) `
        -SearchRoots @(
            "$env:APPDATA\Telegram Desktop"
            "$env:LOCALAPPDATA\Programs\Telegram Desktop"
            "$env:ChocolateyInstall\lib\telegram"
        )

    if ($null -ne $TelegramPath) {
        $TelegramShortcut = Join-Path `
            -Path $TaskbarShortcutDirectory `
            -ChildPath "Telegram.lnk"

        $TelegramShortcutCreated = New-WindowsShortcut `
            -TargetPath $TelegramPath `
            -ShortcutPath $TelegramShortcut `
            -IconLocation "$TelegramPath,0"

        if ($TelegramShortcutCreated) {
            $TaskbarPinEntries += (
                '                <taskbar:DesktopApp ' +
                'DesktopApplicationLinkPath="' +
                '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\' +
                'Programs\Kuma Taskbar\Telegram.lnk" />'
            )

            Write-Success "Telegram was added to the taskbar layout."
        }
    }
    else {
        Write-Warning (
            "Telegram appears to be installed, but Telegram.exe " +
            "could not be found."
        )
    }
}
else {
    Write-Skip (
        "Telegram is not installed. Taskbar pin was skipped."
    )
}

# ------------------------------------------------------------
# Create taskbar layout only when applications were detected
# ------------------------------------------------------------

if ($TaskbarPinEntries.Count -eq 0) {
    Write-Skip (
        "No supported applications were detected. " +
        "The taskbar layout was not changed."
    )
}
else {
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

    $TaskbarPinXml = $TaskbarPinEntries -join "`r`n"

    $TaskbarXml = @"
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
$TaskbarPinXml
            </taskbar:TaskbarPinList>
        </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@

    # Write UTF-8 with BOM for Windows PowerShell 5.1.
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
    Write-Host "Detected taskbar entries: $($TaskbarPinEntries.Count)"

    try {
        gpupdate.exe /target:user /force | Out-Null
    }
    catch {
        Write-Warning "User Group Policy refresh failed."
    }

    Get-Process `
        -Name "explorer" `
        -ErrorAction SilentlyContinue |
        Stop-Process `
            -Force `
            -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 3

    Start-Process "explorer.exe"

    Write-Warning (
        "If the taskbar is not updated immediately, " +
        "sign out and sign in again."
    )
}

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
# 11: Display results
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