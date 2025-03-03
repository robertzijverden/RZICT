@{
    ModuleVersion = '1.2'
    GUID          = 'dce9309b-4091-479a-8d7e-40c56649bf68'
    Author        = 'Robert van Zijverden'
    Description   = 'Global Functiecatalogus'
}

# Standaard logbestand als er geen custom pad is gezet
$Global:LogPath = 'C:\Logs\GlobalCatalog.log'

function Write-Log {
    param (
        [string]$Logger = $MyInvocation.MyCommand.Name,
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',
        [switch]$EnableDebug
    )

    # Gebruik de globale variabele als logbestand, anders de standaardwaarde
    $logFile = if ($Global:LogPath) {
        $Global:LogPath 
    }
    else {
        'C:\Logs\GlobalCatalog.log' 
    }

    if (!(Test-Path $logFile)) {
        New-Item -ItemType File -Path $logFile -Force | Out-Null
    }

    $dateTime = Get-Date -Format 'yyyy-MM-dd,HH:mm:ss'
    $logEntry = "$dateTime,$Level,$Logger,$Message"
    $logEntry | Out-File -FilePath $logFile -Append -Encoding utf8

    if ($EnableDebug -or $Level -eq 'DEBUG') {
        Write-Output $logEntry
    }
}

# Exporteer de functie
Export-ModuleMember -Function Write-Log
