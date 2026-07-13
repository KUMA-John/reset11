#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 初始化設定腳本

.DESCRIPTION
    執行項目：
    1. 手動輸入電腦名稱
    2. 手動輸入 admin 帳號密碼
    3. 建立或更新指定的本機管理員帳號
    4. 安裝 PowerShell 7
    5. 安裝 PSWindowsUpdate
    6. 安裝所有 Windows Update
    7. 最後詢問是否重新啟動

.NOTES
    腳本內不包含任何明文密碼，可公開放置於 GitHub。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# 共用函式
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

    if ([string]::IsNullOrWhiteSpace($ComputerName)) {
        return $false
    }

    if ($ComputerName.Length -gt 15) {
        return $false
    }

    if ($ComputerName -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$' -and
        $ComputerName.Length -gt 1) {
        return $false
    }

    if ($ComputerName.Length -eq 1 -and
        $ComputerName -notmatch '^[A-Za-z0-9]$') {
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

    if ($UserName -match '[\\/\[\]:;|=,+*?<>@"]') {
        return $false
    }

    return $true
}

function Read-ConfirmedPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    while ($true) {
        $Password1 = Read-Host $Prompt -AsSecureString
        $Password2 = Read-Host "請再次輸入密碼" -AsSecureString

        $BSTR1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
            $Password1
        )

        $BSTR2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
            $Password2
        )

        try {
            $PlainPassword1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                $BSTR1
            )

            $PlainPassword2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                $BSTR2
            )

            if ([string]::IsNullOrWhiteSpace($PlainPassword1)) {
                Write-Warning "密碼不可為空白，請重新輸入。"
                continue
            }

            if ($PlainPassword1 -ne $PlainPassword2) {
                Write-Warning "兩次輸入的密碼不同，請重新輸入。"
                continue
            }

            return $Password1
        }
        finally {
            if ($BSTR1 -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)
            }

            if ($BSTR2 -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
            }

            $PlainPassword1 = $null
            $PlainPassword2 = $null
        }
    }
}

function Get-AdministratorsGroupName {
    # Administrators 群組的固定 SID
    # 避免不同語言版本 Windows 群組名稱不同

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

        Write-Host "已將 '$UserName' 加入 '$AdministratorsGroup' 群組。" `
            -ForegroundColor Green
    }
    else {
        Write-Host "帳號 '$UserName' 已經是本機管理員。" `
            -ForegroundColor Gray
    }
}

# ============================================================
# 檢查系統管理員權限
# ============================================================

if (-not (Test-IsAdministrator)) {
    Write-Host ""
    Write-Error "此腳本必須使用系統管理員身分執行。"
    Write-Host "請在 Windows PowerShell 上按右鍵，選擇「以系統管理員身分執行」。"
    exit 1
}

Clear-Host

Write-Host "============================================================" -ForegroundColor Green
Write-Host " Windows 11 初始化設定" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "目前電腦名稱：$env:COMPUTERNAME"
Write-Host "目前執行帳號：$env:USERDOMAIN\$env:USERNAME"
Write-Host ""
Write-Host "請先輸入本次初始化所需資料。" -ForegroundColor Yellow
Write-Host "所有密碼只保存在目前 PowerShell 工作階段，不會寫入腳本。" `
    -ForegroundColor Yellow

# ============================================================
# 腳本開始時收集所有輸入資料
# ============================================================

Write-Step "初始化資料輸入"

# ------------------------------------------------------------
# 輸入電腦名稱
# ------------------------------------------------------------

while ($true) {
    $InputComputerName = Read-Host `
        "請輸入新電腦名稱，直接按 Enter 保留目前名稱 [$env:COMPUTERNAME]"

    if ([string]::IsNullOrWhiteSpace($InputComputerName)) {
        $ComputerName = $env:COMPUTERNAME
        break
    }

    $ComputerName = $InputComputerName.Trim().ToUpperInvariant()

    if (-not (Test-ValidComputerName -ComputerName $ComputerName)) {
        Write-Warning "電腦名稱格式錯誤。"
        Write-Warning "限 1 至 15 個英文字母、數字或減號，且不可全部為數字。"
        continue
    }

    break
}

# ------------------------------------------------------------
# 輸入 admin 帳號密碼
# ------------------------------------------------------------

Write-Host ""
Write-Host "請輸入本機 admin 帳號的新密碼。" -ForegroundColor Yellow

$AdminPassword = Read-ConfirmedPassword `
    -Prompt "admin 新密碼"

# ------------------------------------------------------------
# 輸入預設使用者名稱
# ------------------------------------------------------------

Write-Host ""

while ($true) {
    $Account = Read-Host "請輸入要建立或更新的本機使用者名稱"

    if (-not (Test-ValidLocalUserName -UserName $Account)) {
        Write-Warning "帳號名稱格式錯誤。"
        Write-Warning "帳號不可為空白、不可超過 20 個字元，且不可包含 Windows 保留字元。"
        continue
    }

    $Account = $Account.Trim()
    break
}

# ------------------------------------------------------------
# 輸入預設使用者密碼
# ------------------------------------------------------------

Write-Host ""
Write-Host "請輸入帳號 '$Account' 的密碼。" -ForegroundColor Yellow

$AccountPassword = Read-ConfirmedPassword `
    -Prompt "$Account 新密碼"

Write-Host ""
Write-Host "初始化資料輸入完成，開始執行設定。" -ForegroundColor Green

$RestartRequired = $false

# ============================================================
# 1. 設定電腦名稱
# ============================================================

Write-Step "步驟 1：設定電腦名稱"

if ($ComputerName -ne $env:COMPUTERNAME) {
    try {
        Rename-Computer `
            -NewName $ComputerName `
            -Force `
            -ErrorAction Stop

        Write-Host "電腦名稱已設定為：$ComputerName" `
            -ForegroundColor Green

        Write-Host "重新啟動後，新電腦名稱才會完全生效。" `
            -ForegroundColor Yellow

        $RestartRequired = $true
    }
    catch {
        Write-Error "修改電腦名稱失敗：$($_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Host "保留目前電腦名稱：$ComputerName" `
        -ForegroundColor Gray
}

# ============================================================
# 2. 設定或建立 admin 帳號
# ============================================================

Write-Step "步驟 2：設定本機 admin 帳號"

$AdminAccountName = "admin"

try {
    $AdminAccount = Get-LocalUser `
        -Name $AdminAccountName `
        -ErrorAction SilentlyContinue

    if ($null -eq $AdminAccount) {
        Write-Host "找不到本機帳號 '$AdminAccountName'，準備建立。" `
            -ForegroundColor Yellow

        New-LocalUser `
            -Name $AdminAccountName `
            -Password $AdminPassword `
            -FullName "Local Administrator" `
            -Description "Local administrator account" `
            -AccountNeverExpires `
            -ErrorAction Stop

        Write-Host "已建立本機帳號：$AdminAccountName" `
            -ForegroundColor Green
    }
    else {
        Set-LocalUser `
            -Name $AdminAccountName `
            -Password $AdminPassword `
            -ErrorAction Stop

        Write-Host "已更新 '$AdminAccountName' 帳號密碼。" `
            -ForegroundColor Green
    }

    $CurrentAdminAccount = Get-LocalUser `
        -Name $AdminAccountName `
        -ErrorAction Stop

    if (-not $CurrentAdminAccount.Enabled) {
        Enable-LocalUser `
            -Name $AdminAccountName `
            -ErrorAction Stop

        Write-Host "已啟用 '$AdminAccountName' 帳號。" `
            -ForegroundColor Green
    }

    Add-UserToAdministrators `
        -UserName $AdminAccountName
}
catch {
    Write-Error "設定 '$AdminAccountName' 帳號失敗：$($_.Exception.Message)"
    exit 1
}

# 用完後清除變數參照
$AdminPassword = $null

# ============================================================
# 3. 建立或更新預設本機管理員帳號
# ============================================================

Write-Step "步驟 3：建立或更新本機管理員帳號"

try {
    $ExistingAccount = Get-LocalUser `
        -Name $Account `
        -ErrorAction SilentlyContinue

    if ($null -eq $ExistingAccount) {
        New-LocalUser `
            -Name $Account `
            -Password $AccountPassword `
            -FullName $Account `
            -Description "Local administrator account created by setup script" `
            -AccountNeverExpires `
            -ErrorAction Stop

        Write-Host "已建立本機帳號：$Account" `
            -ForegroundColor Green
    }
    else {
        Set-LocalUser `
            -Name $Account `
            -Password $AccountPassword `
            -ErrorAction Stop

        Write-Host "帳號 '$Account' 已存在，已更新密碼。" `
            -ForegroundColor Yellow
    }

    $CurrentAccount = Get-LocalUser `
        -Name $Account `
        -ErrorAction Stop

    if (-not $CurrentAccount.Enabled) {
        Enable-LocalUser `
            -Name $Account `
            -ErrorAction Stop

        Write-Host "已啟用帳號：$Account" `
            -ForegroundColor Green
    }

    Add-UserToAdministrators `
        -UserName $Account
}
catch {
    Write-Error "建立或更新本機帳號失敗：$($_.Exception.Message)"
    exit 1
}

# 用完後清除變數參照
$AccountPassword = $null

# ============================================================
# 4. 安裝或更新 PowerShell 7
# ============================================================

Write-Step "步驟 4：安裝或更新 PowerShell 7"

$WingetCommand = Get-Command `
    winget.exe `
    -ErrorAction SilentlyContinue

if ($null -eq $WingetCommand) {
    Write-Warning "找不到 winget.exe。"
    Write-Warning "請確認 Windows 11 已安裝 Microsoft App Installer。"
    Write-Warning "本次將略過 PowerShell 7 安裝。"
}
else {
    try {
        Write-Host "目前 winget 版本：" -ForegroundColor Gray
        winget --version

        Write-Host ""
        Write-Host "正在安裝或更新 PowerShell 7..." `
            -ForegroundColor Yellow

        winget upgrade `
            --id Microsoft.PowerShell `
            --exact `
            --source winget `
            --accept-source-agreements `
            --accept-package-agreements `
            --silent

        $WingetUpgradeExitCode = $LASTEXITCODE

        if ($WingetUpgradeExitCode -ne 0) {
            Write-Host "未偵測到可升級版本，嘗試安裝 PowerShell 7..." `
                -ForegroundColor Yellow

            winget install `
                --id Microsoft.PowerShell `
                --exact `
                --source winget `
                --accept-source-agreements `
                --accept-package-agreements `
                --silent

            $WingetInstallExitCode = $LASTEXITCODE

            if ($WingetInstallExitCode -eq 0) {
                Write-Host "PowerShell 7 安裝完成。" `
                    -ForegroundColor Green
            }
            else {
                Write-Warning "PowerShell 7 安裝命令回傳代碼：$WingetInstallExitCode"
            }
        }
        else {
            Write-Host "PowerShell 7 更新完成。" `
                -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "安裝或更新 PowerShell 7 時發生錯誤：$($_.Exception.Message)"
    }
}

# ============================================================
# 5. 設定 PowerShell 執行原則
# ============================================================

Write-Step "步驟 5：設定 PowerShell 執行原則"

try {
    Set-ExecutionPolicy `
        -ExecutionPolicy RemoteSigned `
        -Scope CurrentUser `
        -Force `
        -ErrorAction Stop

    Write-Host "CurrentUser 執行原則已設定為 RemoteSigned。" `
        -ForegroundColor Green
}
catch {
    Write-Warning "設定 PowerShell 執行原則失敗：$($_.Exception.Message)"
}

# ============================================================
# 6. 安裝 NuGet Package Provider
# ============================================================

Write-Step "步驟 6：安裝 NuGet Package Provider"

try {
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

        Write-Host "NuGet Package Provider 安裝完成。" `
            -ForegroundColor Green
    }
    else {
        Write-Host "NuGet Package Provider 已安裝，版本：$($NuGetProvider.Version)" `
            -ForegroundColor Gray
    }
}
catch {
    Write-Error "安裝 NuGet Package Provider 失敗：$($_.Exception.Message)"
    exit 1
}

# ============================================================
# 7. 設定 PSGallery
# ============================================================

Write-Step "步驟 7：設定 PowerShell Gallery"

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

    Write-Host "PSGallery 已設定完成。" `
        -ForegroundColor Green
}
catch {
    Write-Warning "設定 PSGallery 失敗：$($_.Exception.Message)"
}

# ============================================================
# 8. 安裝 PSWindowsUpdate
# ============================================================

Write-Step "步驟 8：安裝 PSWindowsUpdate"

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

        Write-Host "PSWindowsUpdate 安裝完成。" `
            -ForegroundColor Green
    }
    else {
        Write-Host "目前 PSWindowsUpdate 版本：$($InstalledModule.Version)" `
            -ForegroundColor Gray

        Update-Module `
            -Name PSWindowsUpdate `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Import-Module `
        PSWindowsUpdate `
        -Force `
        -ErrorAction Stop
}
catch {
    Write-Error "安裝或載入 PSWindowsUpdate 失敗：$($_.Exception.Message)"
    exit 1
}

# ============================================================
# 9. 掃描並安裝 Windows Update
# ============================================================

Write-Step "步驟 9：掃描並安裝 Windows Update"

try {
    Write-Host "正在掃描 Windows Update..." `
        -ForegroundColor Yellow

    $AvailableUpdates = Get-WindowsUpdate `
        -MicrosoftUpdate `
        -ErrorAction Stop

    if (
        $null -eq $AvailableUpdates -or
        @($AvailableUpdates).Count -eq 0
    ) {
        Write-Host "目前沒有可安裝的 Windows 更新。" `
            -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "找到以下更新：" `
            -ForegroundColor Yellow

        $AvailableUpdates |
            Select-Object KB, Size, Title |
            Format-Table -AutoSize

        Write-Host ""
        Write-Host "開始安裝所有 Windows Update..." `
            -ForegroundColor Yellow

        Install-WindowsUpdate `
            -MicrosoftUpdate `
            -AcceptAll `
            -IgnoreReboot `
            -Verbose `
            -ErrorAction Stop

        Write-Host "Windows Update 安裝程序完成。" `
            -ForegroundColor Green

        $RestartRequired = $true
    }
}
catch {
    Write-Warning "執行 Windows Update 時發生錯誤：$($_.Exception.Message)"
}

# ============================================================
# 10. 顯示執行結果
# ============================================================

Write-Step "初始化執行結果"

Write-Host "電腦名稱：" -NoNewline
Write-Host $ComputerName -ForegroundColor Green

Write-Host "本機 admin 帳號：" -NoNewline
Write-Host "已設定" -ForegroundColor Green

Write-Host "新增或更新帳號：" -NoNewline
Write-Host $Account -ForegroundColor Green

Write-Host "目前執行原則：" -NoNewline
Write-Host (Get-ExecutionPolicy -Scope CurrentUser) `
    -ForegroundColor Green

$PwshCommand = Get-Command `
    pwsh.exe `
    -ErrorAction SilentlyContinue

if ($null -ne $PwshCommand) {
    Write-Host "PowerShell 7 路徑：" -NoNewline
    Write-Host $PwshCommand.Source `
        -ForegroundColor Green
}
else {
    $DefaultPwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"

    if (Test-Path $DefaultPwshPath) {
        Write-Host "PowerShell 7 路徑：" -NoNewline
        Write-Host $DefaultPwshPath `
            -ForegroundColor Green
    }
    else {
        Write-Host "PowerShell 7：" -NoNewline
        Write-Host "目前工作階段尚未偵測到" `
            -ForegroundColor Yellow
    }
}

# ============================================================
# 11. 詢問重新啟動
# ============================================================

if ($RestartRequired) {
    Write-Host ""
    Write-Host "電腦名稱或 Windows Update 需要重新啟動後生效。" `
        -ForegroundColor Yellow

    $RestartChoice = Read-Host `
        "是否立即重新啟動？輸入 Y 立即重新啟動，其他鍵稍後手動重新啟動"

    if ($RestartChoice -match '^[Yy]$') {
        Write-Host "正在重新啟動電腦..." `
            -ForegroundColor Yellow

        Restart-Computer -Force
    }
    else {
        Write-Host "請稍後手動重新啟動電腦。" `
            -ForegroundColor Yellow
    }
}
else {
    Write-Host ""
    Write-Host "所有設定已完成，目前不需要重新啟動。" `
        -ForegroundColor Green
}