#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 initial setup script.

.DESCRIPTION
    This script performs the following tasks:

    1. Prompts for a new computer name.
    2. Prompts for the local admin account password.
    3. Creates or updates an additional local administrator account.
    4. Installs or updates PowerShell 7.
    5. Configures the PowerShell execution policy.
    6. Installs the NuGet package provider.
    7. Configures PowerShell Gallery.
    8. Installs the PSWindowsUpdate module.
    9. Installs available Windows updates.
    10. Prompts for a system restart when required.

.NOTES
    Run this script from Windows PowerShell as Administrator.

    Passwords are entered interactively and are not stored in this script.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Test-IsAdministrator {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object `
        Security.Principal.WindowsPrincipal($CurrentIdentity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Test-ValidComputerName {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    # Windows computer name rules used by this script:
    # - Maximum length: 15 characters
    # - Letters, numbers, and hyphens only
    # - Cannot begin or end with a hyphen
    # - Cannot contain only numbers

    if ([string]::IsNullOrWhiteSpace($ComputerName)) {
        return $false
    }

    if ($ComputerName.Length -gt 15) {
        return $false
    }

    if (
        $ComputerName.Length -gt 1 -and
        $ComputerName -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$'
    ) {
        return $false
    }

    if (
        $ComputerName.Length -eq 1 -and
        $ComputerName -notmatch '^[A-Za-z0-9]$'
    ) {
        return $false
    }

    if ($ComputerName -match '^\d+$') {
        return $false
    }

    return $true
}

function Test-ValidLocalUserName {
    param (
        [Parameter(Mandatory)]
        [string]$UserName
    )

    if ([string]::IsNullOrWhiteSpace($UserName)) {
        return $false
    }

    if ($UserName.Length -gt 20) {
        return $false
    }

    # Reject characters that are not valid in Windows local user names.
    if ($UserName -match '[\\/\[\]:;|=,+*?<>@"]') {
        return $false
    }

    return $true
}

# ============================================================
# Password input function
# Password characters will be visible while typing.
# No confirmation is required.
# ============================================================

function Read-VisiblePassword {
    param (
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $PlainPassword = Read-Host $Prompt

        if ([string]::IsNullOrWhiteSpace($PlainPassword)) {
            Write-Warning "The password cannot be empty. Please try again."
            continue
        }

        return ConvertTo-SecureString `
            -String $PlainPassword `
            -AsPlainText `
            -Force
    }
}


function Get-AdministratorsGroupName {
    # Use the well-known SID for the local Administrators group.
    # This works even when Windows uses a localized group name.

    $AdministratorsSid = New-Object `
        System.Security.Principal.SecurityIdentifier("S-1-5-32-544")

    return $AdministratorsSid.Translate(
        [System.Security.Principal.NTAccount]
    ).Value.Split("\")[-1]
}

function Add-UserToAdministrators {
    param (
        [Parameter(Mandatory)]
        [string]$UserName
    )

    $AdministratorsGroup = Get-AdministratorsGroupName

    $ExistingMember = Get-LocalGroupMember `
        -Group $AdministratorsGroup `
        -ErrorAction Stop |
        Where-Object {
            $_.Name -match "\\$([regex]::Escape($UserName))$"
        }

    if ($null -eq $ExistingMember) {
        Add-LocalGroupMember `
            -Group $AdministratorsGroup `
            -Member $UserName `
            -ErrorAction Stop

        Write-Host `
            "User '$UserName' was added to the '$AdministratorsGroup' group." `
            -ForegroundColor Green
    }
    else {
        Write-Host `
            "User '$UserName' is already a local administrator." `
            -ForegroundColor Gray
    }
}

# ============================================================
# Verify administrator privileges
# ============================================================

if (-not (Test-IsAdministrator)) {
    Write-Host ""
    Write-Error "This script must be run as Administrator."
    Write-Host "Right-click Windows PowerShell and select 'Run as administrator'."
    exit 1
}

Clear-Host

Write-Host "============================================================" -ForegroundColor Green
Write-Host " Windows 11 Initial Setup" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Current computer name: $env:COMPUTERNAME"
Write-Host "Current account: $env:USERDOMAIN\$env:USERNAME"
Write-Host ""
Write-Host "Enter the information required for this setup." -ForegroundColor Yellow
Write-Host `
    "Passwords are kept only in the current PowerShell session." `
    -ForegroundColor Yellow
Write-Host `
    "Passwords are not written to the script or saved to disk." `
    -ForegroundColor Yellow

# ============================================================
# Collect setup information at the beginning
# ============================================================

Write-Step "Setup Information"

# ------------------------------------------------------------
# Prompt for the new computer name
# ------------------------------------------------------------

while ($true) {
    $InputComputerName = Read-Host `
        "Enter the new computer name, or press Enter to keep [$env:COMPUTERNAME]"

    if ([string]::IsNullOrWhiteSpace($InputComputerName)) {
        $ComputerName = $env:COMPUTERNAME
        break
    }

    $ComputerName = $InputComputerName.Trim().ToUpperInvariant()

    if (-not (Test-ValidComputerName -ComputerName $ComputerName)) {
        Write-Warning "The computer name is not valid."
        Write-Warning `
            "Use 1 to 15 letters, numbers, or hyphens. It cannot contain only numbers."
        continue
    }

    break
}

# ------------------------------------------------------------
# Prompt for the local admin account password
# ------------------------------------------------------------

Write-Host ""
Write-Host `
    "Enter the new password for the local admin account." `
    -ForegroundColor Yellow

    Write-Warning "The password will be visible while typing."

$AdminPassword = Read-VisiblePassword `
    -Prompt "Enter the new password for admin"

# ------------------------------------------------------------
# Prompt for an additional local user name
# ------------------------------------------------------------

Write-Host ""

while ($true) {
    $Account = Read-Host `
        "Enter the local user name to create or update"

    if (-not (Test-ValidLocalUserName -UserName $Account)) {
        Write-Warning "The user name is not valid."
        Write-Warning `
            "The name cannot be empty, exceed 20 characters, or contain reserved characters."
        continue
    }

    $Account = $Account.Trim()
    break
}

# ------------------------------------------------------------
# Prompt for the additional local user's password
# ------------------------------------------------------------

Write-Host ""
Write-Host "Enter the password for user '$Account'." `
    -ForegroundColor Yellow

Write-Warning "The password will be visible while typing."

$AccountPassword = Read-VisiblePassword `
    -Prompt "Enter the new password for $Account"

$RestartRequired = $false

# ============================================================
# Step 1: Change the computer name
# ============================================================

Write-Step "Step 1: Configure Computer Name"

if ($ComputerName -ne $env:COMPUTERNAME) {
    try {
        Rename-Computer `
            -NewName $ComputerName `
            -Force `
            -ErrorAction Stop

        Write-Host `
            "The computer name was changed to: $ComputerName" `
            -ForegroundColor Green

        Write-Host `
            "The new computer name will take full effect after a restart." `
            -ForegroundColor Yellow

        $RestartRequired = $true
    }
    catch {
        Write-Error `
            "Failed to change the computer name: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Host `
        "The current computer name will be kept: $ComputerName" `
        -ForegroundColor Gray
}

# ============================================================
# Step 2: Create or update the local admin account
# ============================================================

Write-Step "Step 2: Configure Local Admin Account"

$AdminAccountName = "admin"

try {
    $AdminAccount = Get-LocalUser `
        -Name $AdminAccountName `
        -ErrorAction SilentlyContinue

    if ($null -eq $AdminAccount) {
        Write-Host `
            "The local account '$AdminAccountName' does not exist. Creating it now." `
            -ForegroundColor Yellow

        New-LocalUser `
            -Name $AdminAccountName `
            -Password $AdminPassword `
            -FullName "Local Administrator" `
            -Description "Local administrator" `
            -AccountNeverExpires `
            -ErrorAction Stop

        Write-Host `
            "Local account '$AdminAccountName' was created." `
            -ForegroundColor Green
    }
    else {
        Set-LocalUser `
            -Name $AdminAccountName `
            -Password $AdminPassword `
            -ErrorAction Stop

        Write-Host `
            "The password for '$AdminAccountName' was updated." `
            -ForegroundColor Green
    }

    $CurrentAdminAccount = Get-LocalUser `
        -Name $AdminAccountName `
        -ErrorAction Stop

    if (-not $CurrentAdminAccount.Enabled) {
        Enable-LocalUser `
            -Name $AdminAccountName `
            -ErrorAction Stop

        Write-Host `
            "Account '$AdminAccountName' was enabled." `
            -ForegroundColor Green
    }

    Add-UserToAdministrators `
        -UserName $AdminAccountName
}
catch {
    Write-Error `
        "Failed to configure account '$AdminAccountName': $($_.Exception.Message)"
    exit 1
}

# Remove the password variable reference after use.
$AdminPassword = $null

# ============================================================
# Step 3: Create or update the additional administrator account
# ============================================================

Write-Step "Step 3: Configure Additional Local Administrator"

try {
    $ExistingAccount = Get-LocalUser `
        -Name $Account `
        -ErrorAction SilentlyContinue

    if ($null -eq $ExistingAccount) {
        New-LocalUser `
            -Name $Account `
            -Password $AccountPassword `
            -FullName $Account `
            -Description "Local administrator" `
            -AccountNeverExpires `
            -ErrorAction Stop

        Write-Host `
            "Local account '$Account' was created." `
            -ForegroundColor Green
    }
    else {
        Set-LocalUser `
            -Name $Account `
            -Password $AccountPassword `
            -ErrorAction Stop

        Write-Host `
            "Account '$Account' already exists. Its password was updated." `
            -ForegroundColor Yellow
    }

    $CurrentAccount = Get-LocalUser `
        -Name $Account `
        -ErrorAction Stop

    if (-not $CurrentAccount.Enabled) {
        Enable-LocalUser `
            -Name $Account `
            -ErrorAction Stop

        Write-Host `
            "Account '$Account' was enabled." `
            -ForegroundColor Green
    }

    Add-UserToAdministrators `
        -UserName $Account
}
catch {
    Write-Error `
        "Failed to create or update local account '$Account': $($_.Exception.Message)"
    exit 1
}

$AccountPassword = $null


# ============================================================
# Step 4: Install or update PowerShell 7
# ============================================================

Write-Step "Step 4: Install or Update PowerShell 7"

$WingetCommand = Get-Command `
    winget.exe `
    -ErrorAction SilentlyContinue

if ($null -eq $WingetCommand) {
    Write-Warning "winget.exe was not found."
    Write-Warning `
        "Make sure Microsoft App Installer is installed on Windows 11."
    Write-Warning "PowerShell 7 installation will be skipped."
}
else {
    try {
        Write-Host "Installed winget version:" -ForegroundColor Gray
        winget --version

        Write-Host ""
        Write-Host `
            "Checking for a PowerShell 7 upgrade..." `
            -ForegroundColor Yellow

        winget upgrade `
            --id Microsoft.PowerShell `
            --exact `
            --source winget `
            --accept-source-agreements `
            --accept-package-agreements `
            --silent `
            --disable-interactivity

        $WingetUpgradeExitCode = $LASTEXITCODE

        if ($WingetUpgradeExitCode -ne 0) {
            Write-Host `
                "No upgrade was completed. Attempting to install PowerShell 7..." `
                -ForegroundColor Yellow

            winget install `
                --id Microsoft.PowerShell `
                --exact `
                --source winget `
                --accept-source-agreements `
                --accept-package-agreements `
                --silent `
                --disable-interactivity

            $WingetInstallExitCode = $LASTEXITCODE

            if ($WingetInstallExitCode -eq 0) {
                Write-Host `
                    "PowerShell 7 installation completed." `
                    -ForegroundColor Green
            }
            else {
                Write-Warning `
                    "The PowerShell 7 install command returned exit code $WingetInstallExitCode."
            }
        }
        else {
            Write-Host `
                "PowerShell 7 upgrade completed." `
                -ForegroundColor Green
        }
    }
    catch {
        Write-Warning `
            "An error occurred while installing or updating PowerShell 7: $($_.Exception.Message)"
    }
}

# ============================================================
# Step 5: Configure the PowerShell execution policy
# ============================================================

Write-Step "Step 5: Configure PowerShell Execution Policy"

try {
    # RemoteSigned allows locally created scripts to run.
    # Files downloaded from the Internet may need to be unblocked.

    Set-ExecutionPolicy `
        -ExecutionPolicy RemoteSigned `
        -Scope CurrentUser `
        -Force `
        -ErrorAction Stop

    Write-Host `
        "The CurrentUser execution policy was set to RemoteSigned." `
        -ForegroundColor Green
}
catch {
    Write-Warning `
        "Failed to configure the PowerShell execution policy: $($_.Exception.Message)"
}

# ============================================================
# Step 6: Install the NuGet package provider
# ============================================================

Write-Step "Step 6: Install NuGet Package Provider"

try {
    # Enable TLS 1.2 for PowerShell Gallery connections.
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor `
        [Net.SecurityProtocolType]::Tls12

    $NuGetProvider = Get-PackageProvider `
        -Name NuGet `
        -ListAvailable `
        -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (
        $null -eq $NuGetProvider -or
        [version]$NuGetProvider.Version -lt [version]"2.8.5.201"
    ) {
        Install-PackageProvider `
            -Name NuGet `
            -MinimumVersion 2.8.5.201 `
            -Force `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host `
            "The NuGet package provider was installed." `
            -ForegroundColor Green
    }
    else {
        Write-Host `
            "NuGet package provider is already installed. Version: $($NuGetProvider.Version)" `
            -ForegroundColor Gray
    }
}
catch {
    Write-Error `
        "Failed to install the NuGet package provider: $($_.Exception.Message)"
    exit 1
}

# ============================================================
# Step 7: Configure PowerShell Gallery
# ============================================================

Write-Step "Step 7: Configure PowerShell Gallery"

try {
    $PSGallery = Get-PSRepository `
        -Name PSGallery `
        -ErrorAction SilentlyContinue

    if ($null -eq $PSGallery) {
        Register-PSRepository `
            -Default `
            -ErrorAction Stop

        $PSGallery = Get-PSRepository `
            -Name PSGallery `
            -ErrorAction Stop
    }

    if ($PSGallery.InstallationPolicy -ne "Trusted") {
        Set-PSRepository `
            -Name PSGallery `
            -InstallationPolicy Trusted `
            -ErrorAction Stop
    }

    Write-Host `
        "PowerShell Gallery configuration completed." `
        -ForegroundColor Green
}
catch {
    Write-Warning `
        "Failed to configure PowerShell Gallery: $($_.Exception.Message)"
}

# ============================================================
# Step 8: Install the PSWindowsUpdate module
# ============================================================

Write-Step "Step 8: Install PSWindowsUpdate Module"

try {
    $InstalledModule = Get-Module `
        -ListAvailable `
        -Name PSWindowsUpdate |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($null -eq $InstalledModule) {
        Install-Module `
            -Name PSWindowsUpdate `
            -Repository PSGallery `
            -Scope AllUsers `
            -Force `
            -AllowClobber `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host `
            "The PSWindowsUpdate module was installed." `
            -ForegroundColor Green
    }
    else {
        Write-Host `
            "Installed PSWindowsUpdate version: $($InstalledModule.Version)" `
            -ForegroundColor Gray

        try {
            Update-Module `
                -Name PSWindowsUpdate `
                -Force `
                -ErrorAction Stop

            Write-Host `
                "The PSWindowsUpdate module update check completed." `
                -ForegroundColor Green
        }
        catch {
            Write-Warning `
                "The existing PSWindowsUpdate module could not be updated: $($_.Exception.Message)"
        }
    }

    Import-Module `
        PSWindowsUpdate `
        -Force `
        -ErrorAction Stop
}
catch {
    Write-Error `
        "Failed to install or import PSWindowsUpdate: $($_.Exception.Message)"
    exit 1
}

# ============================================================
# Step 9: Scan for and install Windows updates
# ============================================================

Write-Step "Step 9: Scan for and Install Windows Updates"

try {
    Write-Host `
        "Scanning for available Windows updates..." `
        -ForegroundColor Yellow

    $AvailableUpdates = Get-WindowsUpdate `
        -MicrosoftUpdate `
        -ErrorAction Stop

    if (
        $null -eq $AvailableUpdates -or
        @($AvailableUpdates).Count -eq 0
    ) {
        Write-Host `
            "No available Windows updates were found." `
            -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host `
            "The following updates are available:" `
            -ForegroundColor Yellow

        $AvailableUpdates |
            Select-Object KB, Size, Title |
            Format-Table -AutoSize

        Write-Host ""
        Write-Host `
            "Installing all available Windows updates..." `
            -ForegroundColor Yellow

        Install-WindowsUpdate `
            -MicrosoftUpdate `
            -AcceptAll `
            -IgnoreReboot `
            -Verbose `
            -ErrorAction Stop

        Write-Host `
            "Windows Update installation completed." `
            -ForegroundColor Green

        $RestartRequired = $true
    }
}
catch {
    Write-Warning `
        "An error occurred while running Windows Update: $($_.Exception.Message)"
}

# ============================================================
# Step 10: Display the setup result
# ============================================================

Write-Step "Setup Results"

Write-Host "Computer name: " -NoNewline
Write-Host $ComputerName -ForegroundColor Green

Write-Host "Local admin account: " -NoNewline
Write-Host "Configured" -ForegroundColor Green

Write-Host "Additional local account: " -NoNewline
Write-Host $Account -ForegroundColor Green

Write-Host "CurrentUser execution policy: " -NoNewline
Write-Host `
    (Get-ExecutionPolicy -Scope CurrentUser) `
    -ForegroundColor Green

$PwshCommand = Get-Command `
    pwsh.exe `
    -ErrorAction SilentlyContinue

if ($null -ne $PwshCommand) {
    Write-Host "PowerShell 7 path: " -NoNewline
    Write-Host `
        $PwshCommand.Source `
        -ForegroundColor Green
}
else {
    $DefaultPwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"

    if (Test-Path $DefaultPwshPath) {
        Write-Host "PowerShell 7 path: " -NoNewline
        Write-Host `
            $DefaultPwshPath `
            -ForegroundColor Green
    }
    else {
        Write-Host "PowerShell 7: " -NoNewline
        Write-Host `
            "Not detected in the current session" `
            -ForegroundColor Yellow
    }
}

```powershell
# ============================================================
# Step 11: Restart countdown
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Setup Completed" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The computer will restart automatically in 10 seconds." `
    -ForegroundColor Yellow
Write-Host "Press Enter within 10 seconds to cancel the restart." `
    -ForegroundColor Yellow
Write-Host ""

$RestartCancelled = $false
$CountdownSeconds = 10

for ($Remaining = $CountdownSeconds; $Remaining -gt 0; $Remaining--) {
    Write-Host "`rRestarting in $Remaining second(s)... Press Enter to cancel.   " `
        -NoNewline `
        -ForegroundColor Yellow

    $EndTime = (Get-Date).AddSeconds(1)

    while ((Get-Date) -lt $EndTime) {
        if ([Console]::KeyAvailable) {
            $Key = [Console]::ReadKey($true)

            if ($Key.Key -eq [ConsoleKey]::Enter) {
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

Write-Host ""

if ($RestartCancelled) {
    Write-Host "Automatic restart was cancelled." `
        -ForegroundColor Green
}
else {
    Write-Host "The countdown has completed. Restarting now..." `
        -ForegroundColor Yellow

    Start-Sleep -Seconds 1

    Restart-Computer -Force
}
```
