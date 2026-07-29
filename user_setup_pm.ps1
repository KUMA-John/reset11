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
# Application definitions
#
# Applications are processed in array order within each
# installation group.
#
# ChocolateyFirst applications are installed first.
# Surfshark extension pages are opened next.
# ChocolateyRemaining applications are installed afterward.
# ============================================================

$ApplicationDefinitions = @(

    # ========================================================
    # Chocolatey first group
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Google Chrome"
        DisplayNamePatterns       = @(
            "Google Chrome*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        )
        ExecutableName            = "chrome.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\Google\Chrome"
            "${env:ProgramFiles(x86)}\Google\Chrome"
            "$env:LOCALAPPDATA\Google\Chrome"
        )

        InstallType               = "ChocolateyFirst"
        ChocoName                 = "googlechrome"
        WingetId                 = $null
        WingetSource             = $null
        MsStoreId                = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Google Chrome"

        CreateTaskbarShortcut     = $true
        TaskbarShortcutName       = "Google Chrome"

        StartupAction             = $null
        StartupNames              = @(
            "Google Chrome"
            "Chrome"
        )
        ProcessNames              = @(
            "chrome"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Mozilla Firefox"
        DisplayNamePatterns       = @(
            "Mozilla Firefox*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
            "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
            "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
        )
        ExecutableName            = "firefox.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\Mozilla Firefox"
            "${env:ProgramFiles(x86)}\Mozilla Firefox"
            "$env:LOCALAPPDATA\Mozilla Firefox"
        )

        InstallType               = "ChocolateyFirst"
        ChocoName                 = "firefox"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Mozilla Firefox"

        CreateTaskbarShortcut     = $true
        TaskbarShortcutName       = "Mozilla Firefox"

        StartupAction             = $null
        StartupNames              = @(
            "Mozilla Firefox"
            "Firefox"
        )
        ProcessNames              = @(
            "firefox"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "7-Zip"
        DisplayNamePatterns       = @(
            "7-Zip*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\7-Zip\7zFM.exe"
            "${env:ProgramFiles(x86)}\7-Zip\7zFM.exe"
        )
        ExecutableName            = "7zFM.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\7-Zip"
            "${env:ProgramFiles(x86)}\7-Zip"
        )

        InstallType               = "ChocolateyFirst"
        ChocoName                 = "7zip.install"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "7-Zip"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "7-Zip"

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    # ========================================================
    # Chocolatey remaining group
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Microsoft Visual C++ Redistributable 2015"
        DisplayNamePatterns       = @(
            "Microsoft Visual C++ 2015*"
            "Microsoft Visual C++ 2015-2022*"
        )
        ExecutablePaths           = @()
        ExecutableName            = $null
        SearchRoots               = @()

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "vcredist2015"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Microsoft .NET Framework"
        DisplayNamePatterns       = @(
            "Microsoft .NET Framework*"
        )
        ExecutablePaths           = @()
        ExecutableName            = $null
        SearchRoots               = @()

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "dotnetfx"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Microsoft .NET 8 Runtime"
        DisplayNamePatterns       = @(
            "Microsoft .NET Runtime - 8*"
            "Microsoft .NET Runtime 8*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\dotnet\dotnet.exe"
            "${env:ProgramFiles(x86)}\dotnet\dotnet.exe"
        )
        ExecutableName            = "dotnet.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\dotnet"
            "${env:ProgramFiles(x86)}\dotnet"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "dotnet-8.0-runtime"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Microsoft .NET 8 Desktop Runtime"
        DisplayNamePatterns       = @(
            "Microsoft Windows Desktop Runtime - 8*"
            "Microsoft .NET Desktop Runtime 8*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\dotnet\dotnet.exe"
            "${env:ProgramFiles(x86)}\dotnet\dotnet.exe"
        )
        ExecutableName            = "dotnet.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\dotnet"
            "${env:ProgramFiles(x86)}\dotnet"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "dotnet-8.0-desktopruntime"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Telegram Desktop"
        DisplayNamePatterns       = @(
            "Telegram Desktop*"
            "Telegram*"
        )
        ExecutablePaths           = @(
            "$env:APPDATA\Telegram Desktop\Telegram.exe"
            "$env:LOCALAPPDATA\Programs\Telegram Desktop\Telegram.exe"
            "$env:ProgramFiles\Telegram Desktop\Telegram.exe"
            "${env:ProgramFiles(x86)}\Telegram Desktop\Telegram.exe"
        )
        ExecutableName            = "Telegram.exe"
        SearchRoots               = @(
            "$env:APPDATA\Telegram Desktop"
            "$env:LOCALAPPDATA\Programs"
            "$env:ProgramFiles\Telegram Desktop"
            "${env:ProgramFiles(x86)}\Telegram Desktop"
            "$env:ChocolateyInstall\lib\telegram"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "telegram"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Telegram"

        CreateTaskbarShortcut     = $true
        TaskbarShortcutName       = "Telegram"

        StartupAction             = $null
        StartupNames              = @(
            "Telegram"
            "Telegram Desktop"
        )
        ProcessNames              = @(
            "Telegram"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @(
            "*Telegram*"
        )
    }

    [pscustomobject]@{
        DisplayName               = "Element Desktop"
        DisplayNamePatterns       = @(
            "Element*"
            "Element Desktop*"
        )
        ExecutablePaths           = @(
            "$env:LOCALAPPDATA\element-desktop\Element.exe"
            "$env:LOCALAPPDATA\Programs\Element\Element.exe"
            "$env:ProgramFiles\Element\Element.exe"
            "${env:ProgramFiles(x86)}\Element\Element.exe"
        )
        ExecutableName            = "Element.exe"
        SearchRoots               = @(
            "$env:LOCALAPPDATA\element-desktop"
            "$env:LOCALAPPDATA\Programs"
            "$env:ProgramFiles\Element"
            "${env:ProgramFiles(x86)}\Element"
            "$env:ChocolateyInstall\lib\element-desktop"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "element-desktop"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Element"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Element"

        StartupAction             = $null
        StartupNames              = @(
            "Element"
            "Element Desktop"
        )
        ProcessNames              = @(
            "Element"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "NirCmd"
        DisplayNamePatterns       = @(
            "NirCmd*"
            "NirSoft NirCmd*"
        )
        ExecutablePaths           = @(
            "$env:ChocolateyInstall\bin\nircmd.exe"
            "$env:ChocolateyInstall\lib\nircmd\tools\nircmd.exe"
            "$env:WINDIR\nircmd.exe"
        )
        ExecutableName            = "nircmd.exe"
        SearchRoots               = @(
            "$env:ChocolateyInstall\bin"
            "$env:ChocolateyInstall\lib\nircmd"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "nircmd"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "WireGuard"
        DisplayNamePatterns       = @(
            "WireGuard*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\WireGuard\wireguard.exe"
            "${env:ProgramFiles(x86)}\WireGuard\wireguard.exe"
        )
        ExecutableName            = "wireguard.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\WireGuard"
            "${env:ProgramFiles(x86)}\WireGuard"
        )

        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "wireguard"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "WireGuard"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "WireGuard"

        StartupAction             = $null
        StartupNames              = @(
            "WireGuard"
        )
        ProcessNames              = @(
            "wireguard"
        )
        ServiceNames              = @(
            "WireGuardManager"
        )
        AppxNamePatterns          = @()
    }

    # ========================================================
    # WinGet applications
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "AnyDesk"
        DisplayNamePatterns       = @(
            "AnyDesk*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\AnyDesk\AnyDesk.exe"
            "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe"
            "$env:LOCALAPPDATA\AnyDesk\AnyDesk.exe"
            "$env:APPDATA\AnyDesk\AnyDesk.exe"
        )
        ExecutableName            = "AnyDesk.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\AnyDesk"
            "${env:ProgramFiles(x86)}\AnyDesk"
            "$env:LOCALAPPDATA\AnyDesk"
            "$env:APPDATA\AnyDesk"
        )

        InstallType               = "WinGet"
        ChocoName                 = $null
        WingetId                  = "AnyDesk.AnyDesk"
        WingetSource              = "winget"
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "AnyDesk"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "AnyDesk"

        StartupAction             = $false
        StartupNames              = @(
            "AnyDesk"
            "AnyDesk.exe"
        )
        ProcessNames              = @(
            "AnyDesk"
        )
        ServiceNames              = @(
            "AnyDesk"
        )
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Google Japanese Input"
        DisplayNamePatterns       = @(
            "Google Japanese Input*"
            "Google 日本語入力*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\Google\Google Japanese Input\GoogleIMEJaTool.exe"
            "${env:ProgramFiles(x86)}\Google\Google Japanese Input\GoogleIMEJaTool.exe"
        )
        ExecutableName            = "GoogleIMEJaTool.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\Google"
            "${env:ProgramFiles(x86)}\Google"
        )

        InstallType               = "WinGet"
        ChocoName                 = $null
        WingetId                  = "Google.JapaneseIME"
        WingetSource              = "winget"
        MsStoreId                 = $null

        # This URL is used as a fallback page if WinGet fails.
        InstallerDirectDownload  = "https://www.google.co.jp/ime/"
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = $null

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = $null

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @()
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    # ========================================================
    # Microsoft Store applications
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Microsoft Sticky Notes"
        DisplayNamePatterns       = @(
            "Microsoft Sticky Notes*"
        )
        ExecutablePaths           = @()
        ExecutableName            = $null
        SearchRoots               = @()

        InstallType               = "MsStore"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = "msstore"
        MsStoreId                 = "9NBLGGH4QGHW"
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Sticky Notes"

        CreateTaskbarShortcut     = $true
        TaskbarShortcutName       = "Sticky Notes"

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @(
            "Microsoft.Notes"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @(
            "Microsoft.MicrosoftStickyNotes"
        )
    }

    # ========================================================
    # Chocolatey application installed outside the two batches
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Microsoft Teams"
    
        DisplayNamePatterns       = @(
            "Microsoft Teams*"
            "Teams Machine-Wide Installer*"
        )
    
        ExecutablePaths           = @(
            "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\ms-teams.exe"
        )
    
        ExecutableName            = "ms-teams.exe"
    
        SearchRoots               = @(
            "$env:LOCALAPPDATA\Microsoft"
            "$env:ProgramFiles\WindowsApps"
        )
    
        InstallType               = "ChocolateyRemaining"
        ChocoName                 = "microsoft-teams-new-bootstrapper"
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()
    
        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Microsoft Teams"
    
        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Microsoft Teams"
    
        StartupAction             = $false
    
        StartupNames              = @(
            "Teams"
            "Microsoft Teams"
            "MSTeams"
            "com.squirrel.Teams.Teams"
        )
    
        ProcessNames              = @(
            "ms-teams"
            "Teams"
        )
    
        ServiceNames              = @()
    
        AppxNamePatterns          = @(
            "MSTeams"
            "MicrosoftTeams"
        )
    }

    # ========================================================
    # Direct download applications
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Outline Client"
        DisplayNamePatterns       = @(
            "Outline"
            "Outline Client"
            "Outline Client*"
        )
        ExecutablePaths           = @(
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
        ExecutableName            = "Outline Client.exe"
        SearchRoots               = @(
            "$env:LOCALAPPDATA\Programs"
            "$env:LOCALAPPDATA"
            "$env:ProgramFiles"
            "${env:ProgramFiles(x86)}"
        )

        InstallType               = "DirectDownload"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = (
            "https://s3.amazonaws.com/" +
            "outline-releases/client/windows/stable/" +
            "Outline-Client.exe"
        )
        InstallerFileName        = "Outline-Client.exe"
        InstallerArguments       = @(
            "--silent"
            "/S"
            "/quiet"
        )

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Outline Client"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Outline Client"

        StartupAction             = $null
        StartupNames              = @(
            "Outline"
            "Outline Client"
        )
        ProcessNames              = @(
            "Outline"
            "Outline Client"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Surfshark"
        DisplayNamePatterns       = @(
            "Surfshark"
            "Surfshark*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\Surfshark\Surfshark.exe"
            "${env:ProgramFiles(x86)}\Surfshark\Surfshark.exe"
            "$env:LOCALAPPDATA\Programs\Surfshark\Surfshark.exe"
        )
        ExecutableName            = "Surfshark.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\Surfshark"
            "${env:ProgramFiles(x86)}\Surfshark"
            "$env:LOCALAPPDATA\Programs\Surfshark"
        )

        InstallType               = "DirectDownload"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = (
            "https://downloads.surfshark.com/" +
            "windows/latest/SurfsharkSetup.exe"
        )
        InstallerFileName        = "SurfsharkSetup.exe"
        InstallerArguments       = @(
            "/exenoui"
            "/qn"
        )

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Surfshark"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Surfshark"

        StartupAction             = $null
        StartupNames              = @(
            "Surfshark"
        )
        ProcessNames              = @(
            "Surfshark"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Axure RP 10"
        DisplayNamePatterns       = @(
            "Axure RP 10"
            "Axure RP 10*"
        )
        ExecutablePaths           = @(
            "$env:ProgramFiles\Axure\Axure RP 10\AxureRP10.exe"
            "${env:ProgramFiles(x86)}\Axure\Axure RP 10\AxureRP10.exe"
        )
        ExecutableName            = "AxureRP10.exe"
        SearchRoots               = @(
            "$env:ProgramFiles\Axure"
            "${env:ProgramFiles(x86)}\Axure"
        )

        InstallType               = "DirectDownload"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = (
            "https://axure.cachefly.net/versions/10-0/" +
            "AxureRP-Setup-3929.exe"
        )
        InstallerFileName        = "AxureRP-Setup-3929.exe"
        InstallerArguments       = @(
            "/passive"
            "/qr"
            "/norestart"
            "LaunchAxureRp=0"
        )

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Axure RP 10"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Axure RP 10"

        StartupAction             = $null
        StartupNames              = @(
            "Axure RP 10"
        )
        ProcessNames              = @(
            "AxureRP10"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    # ========================================================
    # Built-in Windows applications
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Calculator"
        DisplayNamePatterns       = @(
            "Windows Calculator*"
        )
        ExecutablePaths           = @(
            "$env:WINDIR\System32\calc.exe"
        )
        ExecutableName            = "calc.exe"
        SearchRoots               = @(
            "$env:WINDIR\System32"
        )

        InstallType               = "BuiltIn"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $true
        DesktopShortcutName       = "Calculator"

        CreateTaskbarShortcut     = $true
        TaskbarShortcutName       = "Calculator"

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @(
            "CalculatorApp"
            "Calculator"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @(
            "Microsoft.WindowsCalculator"
        )
    }

    [pscustomobject]@{
        DisplayName               = "Remote Desktop Connection"
        DisplayNamePatterns       = @()
        ExecutablePaths           = @(
            "$env:WINDIR\System32\mstsc.exe"
        )
        ExecutableName            = "mstsc.exe"
        SearchRoots               = @(
            "$env:WINDIR\System32"
        )

        InstallType               = "BuiltIn"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $true
        DesktopShortcutName       = "Remote Desktop Connection"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Remote Desktop Connection"

        StartupAction             = $null
        StartupNames              = @()
        ProcessNames              = @(
            "mstsc"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    # ========================================================
    # Detect-only applications
    #
    # These applications are not installed by this array.
    # They are configured only when already installed.
    # ========================================================

    [pscustomobject]@{
        DisplayName               = "Microsoft OneDrive"
        DisplayNamePatterns       = @(
            "Microsoft OneDrive*"
        )
        ExecutablePaths           = @(
            "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
            "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe"
            "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
            "$env:SystemRoot\System32\OneDriveSetup.exe"
            "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        )
        ExecutableName            = "OneDrive.exe"
        SearchRoots               = @(
            "$env:LOCALAPPDATA\Microsoft\OneDrive"
            "$env:ProgramFiles\Microsoft OneDrive"
            "${env:ProgramFiles(x86)}\Microsoft OneDrive"
        )

        InstallType               = "DetectOnly"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Microsoft OneDrive"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Microsoft OneDrive"

        StartupAction             = $false
        StartupNames              = @(
            "OneDrive"
            "Microsoft OneDrive"
        )
        ProcessNames              = @(
            "OneDrive"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @()
    }

    [pscustomobject]@{
        DisplayName               = "Slack"
        DisplayNamePatterns       = @(
            "Slack*"
        )
        ExecutablePaths           = @(
            "$env:LOCALAPPDATA\slack\slack.exe"
            "$env:LOCALAPPDATA\Programs\slack\slack.exe"
            "$env:ProgramFiles\Slack\slack.exe"
            "${env:ProgramFiles(x86)}\Slack\slack.exe"
        )
        ExecutableName            = "slack.exe"
        SearchRoots               = @(
            "$env:LOCALAPPDATA\slack"
            "$env:LOCALAPPDATA\Programs"
            "$env:ProgramFiles\Slack"
            "${env:ProgramFiles(x86)}\Slack"
            "$env:ChocolateyInstall\lib\slack"
        )

        InstallType               = "DetectOnly"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Slack"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Slack"

        StartupAction             = $true
        StartupNames              = @(
            "Slack"
        )
        ProcessNames              = @(
            "slack"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @(
            "*Slack*"
        )
    }

    [pscustomobject]@{
        DisplayName               = "Snipaste"
        DisplayNamePatterns       = @(
            "Snipaste*"
        )
        ExecutablePaths           = @(
            "C:\tools\snipaste\Snipaste.exe"
            "C:\tools\snipaste\snipaste.exe"
            "$env:ChocolateyInstall\bin\Snipaste.exe"
            "$env:ProgramFiles\Snipaste\Snipaste.exe"
            "${env:ProgramFiles(x86)}\Snipaste\Snipaste.exe"
            "$env:LOCALAPPDATA\Snipaste\Snipaste.exe"
            "$env:ChocolateyInstall\lib\snipaste\tools\Snipaste.exe"
        )
        ExecutableName            = "Snipaste.exe"
        SearchRoots               = @(
            "C:\tools"
            "$env:ChocolateyInstall\lib"
            "$env:LOCALAPPDATA"
            "$env:ProgramFiles"
            "${env:ProgramFiles(x86)}"
        )

        InstallType               = "DetectOnly"
        ChocoName                 = $null
        WingetId                  = $null
        WingetSource              = $null
        MsStoreId                 = $null
        InstallerDirectDownload  = $null
        InstallerFileName        = $null
        InstallerArguments       = @()

        CreateDesktopShortcut     = $false
        DesktopShortcutName       = "Snipaste"

        CreateTaskbarShortcut     = $false
        TaskbarShortcutName       = "Snipaste"

        StartupAction             = $true
        StartupNames              = @(
            "Snipaste"
            "Snipaste.exe"
        )
        ProcessNames              = @(
            "Snipaste"
        )
        ServiceNames              = @()
        AppxNamePatterns          = @(
            "*Snipaste*"
        )
    }
)


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

function Find-ApplicationExecutableFromDefinition {
    param (
        [Parameter(Mandatory)]
        [psobject]$Application
    )

    foreach ($ExecutablePath in $Application.ExecutablePaths) {
        if (
            -not [string]::IsNullOrWhiteSpace($ExecutablePath) -and
            (
                Test-Path `
                    -LiteralPath $ExecutablePath `
                    -PathType Leaf
            )
        ) {
            return $ExecutablePath
        }
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $Application.ExecutableName
        )
    ) {
        return $null
    }

    foreach ($SearchRoot in $Application.SearchRoots) {
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

        $Executable = Get-ChildItem `
            -LiteralPath $SearchRoot `
            -Filter $Application.ExecutableName `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -ne $Executable) {
            return $Executable.FullName
        }
    }

    return $null
}

function Disable-ApplicationServices {
    param (
        [Parameter(Mandatory)]
        [psobject]$Application
    )

    foreach ($ServiceName in $Application.ServiceNames) {
        if ([string]::IsNullOrWhiteSpace($ServiceName)) {
            continue
        }

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction SilentlyContinue

        if ($null -eq $Service) {
            continue
        }

        try {
            if ($Service.Status -ne "Stopped") {
                Stop-Service `
                    -Name $ServiceName `
                    -Force `
                    -ErrorAction Stop
            }

            Set-Service `
                -Name $ServiceName `
                -StartupType Manual `
                -ErrorAction Stop

            Write-Success (
                $Application.DisplayName +
                " service '$ServiceName' was set to Manual."
            )
        }
        catch {
            Write-Warning (
                "Unable to configure service " +
                "'${ServiceName}' for " +
                $Application.DisplayName +
                ": " +
                $_.Exception.Message
            )
        }
    }
}

function Get-ApplicationDefinition {
    param (
        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $Application = $ApplicationDefinitions |
        Where-Object {
            $_.DisplayName -eq $DisplayName
        } |
        Select-Object -First 1

    if ($null -eq $Application) {
        throw (
            "Application definition was not found: " +
            $DisplayName
        )
    }

    return $Application
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

Write-Step "Step 4A: Install ChocolateyFirst Applications"

$ChocolateyFirstApplications = $ApplicationDefinitions |
    Where-Object {
        $_.InstallType -eq "ChocolateyFirst"
    }

foreach ($Application in $ChocolateyFirstApplications) {
    Install-ChocolateyPackage `
        -PackageName $Application.ChocoName | Out-Null
}

Refresh-EnvironmentPath

# ============================================================
# 4A.1: Open Surfshark extension pages after browsers install
# ============================================================

Write-Step "Step 4A.1: Open Surfshark Browser Extension Pages"

$ChromeExtensionUrl = (
    "https://chrome.google.com/webstore/detail/" +
    "surfshark-vpn-extension/" +
    "ailoabdmgclmfmhdagmlohpjlbpffblp?hl=en"
)

$FirefoxExtensionUrl = (
    "https://addons.mozilla.org/zh-TW/firefox/addon/" +
    "surfshark-vpn-proxy/"
)

$ChromeApplication = Get-ApplicationDefinition `
    -DisplayName "Google Chrome"

$FirefoxApplication = Get-ApplicationDefinition `
    -DisplayName "Mozilla Firefox"

$ChromePath = Find-ApplicationExecutableFromDefinition `
    -Application $ChromeApplication

$FirefoxPath = Find-ApplicationExecutableFromDefinition `
    -Application $FirefoxApplication

if ($null -ne $ChromePath) {
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
            "Unable to open the Surfshark page in Chrome: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning (
        "Google Chrome was not found. " +
        "Its Surfshark extension page was not opened."
    )
}

if ($null -ne $FirefoxPath) {
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
            "Unable to open the Surfshark page in Firefox: " +
            $_.Exception.Message
        )
    }
}
else {
    Write-Warning (
        "Mozilla Firefox was not found. " +
        "Its Surfshark extension page was not opened."
    )
}

# ============================================================
# 4B: Install remaining Chocolatey applications
# ============================================================

Write-Step "Step 4B: Install ChocolateyRemaining Applications"

$ChocolateyRemainingApplications = $ApplicationDefinitions |
    Where-Object {
        $_.InstallType -eq "ChocolateyRemaining"
    }

foreach ($Application in $ChocolateyRemainingApplications) {
    Install-ChocolateyPackage `
        -PackageName $Application.ChocoName | Out-Null
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
# 6A: Install applications with WinGet
# ============================================================

$WinGetApplications = $ApplicationDefinitions |
    Where-Object {
        $_.InstallType -eq "WinGet"
    }

foreach ($Application in $WinGetApplications) {
    if ([string]::IsNullOrWhiteSpace($Application.WingetId)) {
        Write-Warning (
            $Application.DisplayName +
            " has no WinGet package ID."
        )

        continue
    }

    $Installed = Install-WingetPackage `
        -PackageId $Application.WingetId `
        -Source $Application.WingetSource

    if (-not $Installed) {
        Write-Warning (
            $Application.DisplayName +
            " installation failed."
        )

        if (
            -not [string]::IsNullOrWhiteSpace(
                $Application.InstallerDirectDownload
            )
        ) {
            Start-Process `
                -FilePath $Application.InstallerDirectDownload
        }
    }
}

# ============================================================
# 6B: Install applications with MsStore
# ============================================================

$MsStoreApplications = $ApplicationDefinitions |
    Where-Object {
        $_.InstallType -eq "MsStore"
    }

foreach ($Application in $MsStoreApplications) {
    if ([string]::IsNullOrWhiteSpace($Application.MsStoreId)) {
        Write-Warning (
            $Application.DisplayName +
            " has no Microsoft Store ID."
        )

        continue
    }

    $Installed = Install-WingetPackage `
        -PackageId $Application.MsStoreId `
        -Source "msstore"

    if (-not $Installed) {
        Write-Warning (
            "Opening " +
            $Application.DisplayName +
            " in Microsoft Store."
        )

        Start-Process (
            "ms-windows-store://pdp/?ProductId=" +
            $Application.MsStoreId
        )
    }
}

# ============================================================
# 6C: Download and install Client
# ============================================================

Write-Step "Step 6C: Download and install Client"


$Application = Get-ApplicationDefinition `
    -DisplayName "Surfshark"

$InstallerPath = Join-Path `
    -Path $SoftwareDirectory `
    -ChildPath $Application.InstallerFileName

Invoke-WebRequest `
    -Uri $Application.InstallerDirectDownload `
    -OutFile $InstallerPath `
    -UseBasicParsing `
    -ErrorAction Stop

$Process = Start-Process `
    -FilePath $InstallerPath `
    -ArgumentList $Application.InstallerArguments `
    -Wait `
    -PassThru `
    -ErrorAction Stop

# ============================================================
# 7A: Create the Calculator desktop shortcut
# ============================================================

Write-Step "Step 7A. Create Desktop Shortcuts"

$PublicDesktop = [Environment]::GetFolderPath(
    "CommonDesktopDirectory"
)

foreach ($Application in $ApplicationDefinitions) {
    if (-not $Application.CreateDesktopShortcut) {
        continue
    }

    $ExecutablePath = `
        Find-ApplicationExecutableFromDefinition `
            -Application $Application

    if ($null -eq $ExecutablePath) {
        Write-Warning (
            $Application.DisplayName +
            " executable was not found. " +
            "Desktop shortcut was skipped."
        )

        continue
    }

    $ShortcutPath = Join-Path `
        -Path $PublicDesktop `
        -ChildPath (
            $Application.DesktopShortcutName +
            ".lnk"
        )

    New-WindowsShortcut `
        -TargetPath $ExecutablePath `
        -ShortcutPath $ShortcutPath `
        -IconLocation "$ExecutablePath,0" | Out-Null
}

# ============================================================
# 8: Configure application startup
# ============================================================

Write-Step "Step 8: Configure Application Startup"

foreach ($Application in $ApplicationDefinitions) {
    if ($null -eq $Application.StartupAction) {
        continue
    }

    $ApplicationInstalled = Test-ApplicationInstalled `
        -DisplayNamePatterns $Application.DisplayNamePatterns `
        -ExecutablePaths $Application.ExecutablePaths `
        -AppxNamePatterns $Application.AppxNamePatterns `
        -ServiceNames $Application.ServiceNames

    if (-not $ApplicationInstalled) {
        Write-Skip (
            $Application.DisplayName +
            " is not installed. " +
            "Startup configuration was skipped."
        )

        continue
    }

    if ($Application.StartupAction -eq $true) {
        $ExecutablePath = `
            Find-ApplicationExecutableFromDefinition `
                -Application $Application

        if ($null -eq $ExecutablePath) {
            Write-Warning (
                $Application.DisplayName +
                " is installed, but its executable " +
                "could not be found."
            )

            continue
        }

        Enable-ApplicationStartup `
            -ApplicationName $Application.DisplayName `
            -ExecutablePath $ExecutablePath

        Write-Success (
            $Application.DisplayName +
            " startup was enabled."
        )

        continue
    }

    if ($Application.StartupAction -eq $false) {
        if ($Application.ProcessNames.Count -gt 0) {
            Stop-ApplicationProcesses `
                -ProcessNames $Application.ProcessNames
        }

        if ($Application.StartupNames.Count -gt 0) {
            Remove-StartupEntry `
                -Names $Application.StartupNames

            Disable-StartupApprovedEntry `
                -Names $Application.StartupNames
        }

        if ($Application.ServiceNames.Count -gt 0) {
            Disable-ApplicationServices `
                -Application $Application
        }

        Write-Success (
            $Application.DisplayName +
            " startup was disabled."
        )
    }
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
foreach ($Application in $ApplicationDefinitions) {
    if (-not $Application.CreateTaskbarShortcut) {
        continue
    }

    $ApplicationInstalled = Test-ApplicationInstalled `
        -DisplayNamePatterns $Application.DisplayNamePatterns `
        -ExecutablePaths $Application.ExecutablePaths `
        -AppxNamePatterns $Application.AppxNamePatterns `
        -ServiceNames $Application.ServiceNames

    if (-not $ApplicationInstalled) {
        Write-Skip (
            $Application.DisplayName +
            " is not installed. Taskbar pin was skipped."
        )

        continue
    }

    if (
        -not [string]::IsNullOrWhiteSpace(
            $Application.AppUserModelId
        )
    ) {
        $TaskbarPinEntries += (
            '                <taskbar:UWA ' +
            'AppUserModelID="' +
            $Application.AppUserModelId +
            '" />'
        )

        Write-Success (
            $Application.DisplayName +
            " was added to the taskbar layout."
        )

        continue
    }

    $ExecutablePath = `
        Find-ApplicationExecutableFromDefinition `
            -Application $Application

    if ($null -eq $ExecutablePath) {
        Write-Warning (
            $Application.DisplayName +
            " is installed, but its executable was not found."
        )

        continue
    }

    $ShortcutPath = Join-Path `
        -Path $TaskbarShortcutDirectory `
        -ChildPath (
            $Application.TaskbarShortcutName +
            ".lnk"
        )

    $ShortcutCreated = New-WindowsShortcut `
        -TargetPath $ExecutablePath `
        -ShortcutPath $ShortcutPath `
        -IconLocation "$ExecutablePath,0"

    if ($ShortcutCreated) {
        $TaskbarPinEntries += (
            '                <taskbar:DesktopApp ' +
            'DesktopApplicationLinkPath="' +
            '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\' +
            'Programs\Kuma Taskbar\' +
            $Application.TaskbarShortcutName +
            '.lnk" />'
        )

        Write-Success (
            $Application.DisplayName +
            " was added to the taskbar layout."
        )
    }
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