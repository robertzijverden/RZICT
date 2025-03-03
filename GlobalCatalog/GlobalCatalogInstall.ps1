# 📂 Logbestand voor dit installatiescript
$InstallLog = 'C:\Logs\GlobalCatalog_Install.log'

# 🎯 Loggingfunctie voor installatiescript
function Write-InstallLog {
    param (
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    # Controleer of logmap bestaat
    $logDir = Split-Path -Path $InstallLog -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Logbericht maken
    $dateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$dateTime, $Level, $Message"

    # Log opslaan
    $logEntry | Out-File -FilePath $InstallLog -Append -Encoding utf8

    # Optioneel ook naar de console schrijven
    Write-Host "$Level:: $Message"
}

# 🛑 Controleer of het script met administratorrechten wordt uitgevoerd
$currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-InstallLog -Message 'Dit script moet worden uitgevoerd met administratorrechten!' -Level ERROR
    exit 1
}

# 📂 Pad naar de juiste modulemap
$GlobalPath = 'C:\Program Files\WindowsPowerShell\Modules\GlobalCatalog'
$GCPSM1 = Join-Path -Path $GlobalPath -ChildPath 'GlobalCatalog.psm1'
$GCPSD1 = Join-Path -Path $GlobalPath -ChildPath 'GlobalCatalog.psd1'

# 🎯 Nieuwe moduleversie
$NewModuleVersion = [version]'1.2'

# 🛠 Controleer huidige moduleversie
$CurrentModuleVersion = $null
if (Test-Path $GCPSD1) {
    $ModuleInfo = Import-PowerShellDataFile -Path $GCPSD1
    if ($ModuleInfo.ModuleVersion) {
        $CurrentModuleVersion = [version]$ModuleInfo.ModuleVersion
    }
}

# 🏁 Controleer of update nodig is
if ($CurrentModuleVersion -and $CurrentModuleVersion -ge $NewModuleVersion) {
    Write-InstallLog -Message "Module is al up-to-date (versie $CurrentModuleVersion)." -Level INFO
    exit 0
}

Write-InstallLog -Message "Updaten naar versie $NewModuleVersion..." -Level INFO

# 📂 Pad naar de backupmap
$BackupPath = 'C:\Program Files\WindowsPowerShell\Modules\GlobalCatalog_Backups'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path -Path $BackupPath -ChildPath "Backup_$Timestamp"

# 🎯 Back-up maken als de module al bestaat
if (Test-Path $GlobalPath) {
    if (-not (Test-Path $BackupPath)) {
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
    }

    Copy-Item -Path $GlobalPath -Destination $BackupDir -Recurse -Force
    Write-InstallLog -Message "Back-up gemaakt van de oude module naar: $BackupDir" -Level INFO
}

# 🛑 Oude module verwijderen als deze nog geladen is
if (Get-Module -Name 'GlobalCatalog') {
    Write-InstallLog -Message 'Oude moduleversie is geladen, verwijderen...' -Level WARNING
    Remove-Module GlobalCatalog -Force
    Start-Sleep -Seconds 2
}

# 📁 Controleer of de modulemap bestaat
if (-not (Test-Path $GlobalPath)) {
    New-Item -Path $GlobalPath -ItemType Directory -Force | Out-Null
}

# 📜 Inhoud van het PSM1 bestand
$GCPSM1Content = @"
# Standaard logbestand als er geen custom pad is gezet
`$Global:LogPath = "C:\Logs\GlobalCatalog.log"

function Write-Log {
    param (
        [string]`$Logger = `$MyInvocation.MyCommand.Name,
        [string]`$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]`$Level = 'INFO',
        [switch]`$EnableDebug
    )

    # Gebruik de globale variabele als logbestand, anders de standaardwaarde
    `$logFile = if (`$Global:LogPath) { `$Global:LogPath } else { "C:\Logs\GlobalCatalog.log" }

    if (!(Test-Path `$logFile)) {
        New-Item -ItemType File -Path `$logFile -Force | Out-Null
    }

    `$dateTime = Get-Date -Format "yyyy-MM-dd,HH:mm:ss"
    `$logEntry = "`$dateTime,`$Level,`$Logger,`$Message"
    `$logEntry | Out-File -FilePath `$logFile -Append -Encoding utf8

    if (`$EnableDebug -or `$Level -eq "DEBUG") {
        Write-Output `$logEntry
    }
}

# Exporteer de functie
Export-ModuleMember -Function Write-Log
"@

# 📜 Inhoud van het PSD1 bestand
$GCPSD1Content = @"
@{
    ModuleVersion     = "$NewModuleVersion"
    GUID              = "dce9309b-4091-479a-8d7e-40c56649bf68"
    Author            = "Robert van Zijverden"
    Description       = "Global Functiecatalogus"
    PowerShellVersion = "5.1"
    RootModule        = "GlobalCatalog.psm1"
    FunctionsToExport = @("Write-Log")
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
"@

# 📄 Schrijf de modulebestanden weg
$GCPSM1Content | Out-File -FilePath $GCPSM1 -Encoding utf8 -Force
$GCPSD1Content | Out-File -FilePath $GCPSD1 -Encoding utf8 -Force

# ✅ Controleer of de module correct is geïnstalleerd
if ((Test-Path $GCPSM1) -and (Test-Path $GCPSD1)) {
    Import-Module GlobalCatalog -Force -ErrorAction SilentlyContinue
    if ($?) {
        Write-InstallLog -Message "Module succesvol bijgewerkt naar versie $NewModuleVersion!" -Level INFO
        exit 0
    }
}
else {
    Write-InstallLog -Message 'Module-installatie mislukt, bestanden ontbreken!' -Level ERROR
    exit 1
}
