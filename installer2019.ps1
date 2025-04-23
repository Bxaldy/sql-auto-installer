#Requires -RunAsAdministrator
#region Initialization
param(
    [string]$RootPath = "D:\SQL2019",
    [string]$InstanceName = "Test",
    [int]$Port,
    [string]$SetupFilesPath = "C:\Setup",
    [switch]$InstallSSMS
	[string]$SAPassword = 'password'
)

$ErrorActionPreference = 'Stop'
$logFile = Join-Path $PSScriptRoot "SQLInstall_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

#region Functions
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $Message"
    Write-Host $Message
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
#endregion

#region Preflight Checks
if (-not (Test-Admin)) {
    throw "This script must be run as administrator"
}

Write-Log "Starting SQL Server installation process"
#endregion

#region Module Management
if (-not (Get-Module -Name dbatools -ListAvailable)) {
    try {
        Write-Log "Installing dbatools module..."
        Install-Module -Name dbatools -Scope CurrentUser -Force -SkipPublisherCheck
    }
    catch {
        Write-Log "Failed to install dbatools: $_"
        exit 1
    }
}
Import-Module dbatools -Force
#endregion

#region Port Configuration
if (-not $Port) {
    $Port = Get-Random -Minimum 49152 -Maximum 65535  # IANA dynamic ports
    Write-Log "Generated random port: $Port"
}

try {
    $portTest = Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $Port -WarningAction SilentlyContinue
    if ($portTest.TcpTestSucceeded) {
        throw "Port $Port is already in use"
    }
}
catch {
    Write-Log "Port validation failed: $_"
    exit 1
}
#endregion

#region Filesystem Configuration
$directories = @(
    $RootPath,
    (Join-Path $RootPath "Data"),
    (Join-Path $RootPath "Log"),
    (Join-Path $RootPath "TempDB"),
    (Join-Path $RootPath "Backup")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        try {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Log "Created directory: $dir"
        }
        catch {
            Write-Log "Failed to create directory $dir : $_"
            exit 1
        }
    }
}
#endregion

#region SQL Installation
$saPasswordSecure = ConvertTo-SecureString $SAPassword -AsPlainText -Force
$saCredential = New-Object System.Management.Automation.PSCredential('sa', $saPasswordSecure)

$installParams = @{
    Version             = '2019'
    Path                = $SetupFilesPath
    Feature             = 'Engine'
    InstanceName        = $InstanceName
    SaCredential        = $saCredential
    AuthenticationMode  = 'Mixed'
    SqlCollation        = 'SQL_Romanian_CP1250_CS_AS'
    InstancePath        = $RootPath
    DataPath            = (Join-Path $RootPath "Data")
    LogPath             = (Join-Path $RootPath "Log")
    TempPath            = (Join-Path $RootPath "TempDB")
    BackupPath          = (Join-Path $RootPath "Backup")
    Port                = $Port
    AdminAccount        = 'Administrator'
    PerformVolumeMaintenanceTasks = $true
    Confirm             = $false
    EnableException     = $true
}

try {
    Write-Log "Starting SQL Server installation..."
    $installResult = Install-DbaInstance @installParams
    
    if ($installResult.Successful) {
        Write-Log "SQL Server installed successfully"
        Write-Log "Instance Name: $($installResult.InstanceName)"
        Write-Log "Version: $($installResult.Version)"
        Write-Log "Port: $Port"
    }
    else {
        throw "Installation failed: $($installResult.Notes)"
    }
}
catch {
    Write-Log "Critical installation error: $_"
    exit 1
}
#endregion

#region Firewall Configuration
try {
    Write-Log "Creating firewall rule for port $Port..."
    $firewallRuleName = "SQL_${InstanceName}_TCP_$Port"
    New-NetFirewallRule -DisplayName $firewallRuleName `
                        -Direction Inbound `
                        -Protocol TCP `
                        -LocalPort $Port `
                        -Action Allow `
                        -Enabled True | Out-Null
    Write-Log "Firewall rule '$firewallRuleName' created successfully"
}
catch {
    Write-Log "Failed to create firewall rule: $_"
    exit 1
}
#endregion

#region SSMS Installation
if ($InstallSSMS) {
    try {
        $ssmsInstaller = Join-Path $SetupFilesPath "SSMS-Setup.exe"
        if (Test-Path $ssmsInstaller) {
            Write-Log "Starting SSMS installation..."
            $ssmsProcess = Start-Process -FilePath $ssmsInstaller `
                                         -ArgumentList "/install /quiet /norestart" `
                                         -Wait `
                                         -PassThru
            
            if ($ssmsProcess.ExitCode -eq 0) {
                Write-Log "SSMS installed successfully"
            }
            else {
                Write-Log "SSMS installation failed with exit code $($ssmsProcess.ExitCode)"
            }
        }
        else {
            Write-Log "SSMS installer not found at $ssmsInstaller"
        }
    }
    catch {
        Write-Log "SSMS installation error: $_"
    }
}
#endregion

#region Post-Installation Validation
try {
    $serviceCheck = Get-DbaService -ComputerName $env:COMPUTERNAME -InstanceName $InstanceName
    $portCheck = Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $Port
    
    if ($serviceCheck.Status -eq 'Running' -and $portCheck.TcpTestSucceeded) {
        Write-Log "Validation successful - Service running and port accessible"
    }
    else {
        throw "Post-installation validation failed"
    }
}
catch {
    Write-Log "Post-installation validation error: $_"
    exit 1
}

Write-Log "Installation completed successfully"
exit 0