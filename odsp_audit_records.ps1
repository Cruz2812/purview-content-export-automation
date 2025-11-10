# Export ODSP-related audit records for specific record types and decode SIT GUIDs.
Import-Module ExchangeOnlineManagement

Connect-ExchangeOnline

$records = @(
    'ComplianceDLPSharePointClassification',
    'MIPLabel',
    'LabelContentExplorer',
    'SensitivityLabelPolicyMatch',
    'SensitivityLabelAction',
    'SensitivityLabeledFileAction'
)

$SITs = Get-DlpSensitiveInformationType
$SITHash = @{}
$SITs.ForEach({ $SITHash.Add($_.Id, $_.Name) })
Write-Host "Found $($SITHash.Count) Sensitive Information Types."

foreach ($record in $records) {
    $date = Get-Date -Format "MM.dd.yyyy"
    $basePath = "<output_path>\$date"
    if (-not (Test-Path -Path $basePath)) {
        New-Item -ItemType Directory -Path $basePath | Out-Null
    }
    $logFile = Join-Path $basePath "ODSP_AuditLog_$record.txt"
    $outputFile = Join-Path $basePath "ODSP_AuditLog_$record.csv"

    [DateTime]$start = [DateTime]::UtcNow.AddDays(-1)
    [DateTime]$end = [DateTime]::UtcNow
    $resultSize = 5000
    $intervalMinutes = 60

    function Write-LogFile([string]$Message) {
        $final = ([DateTime]::UtcNow.ToString("s")) + ": " + $Message
        $final | Out-File $logFile -Append
    }

    Write-LogFile "BEGIN: $record between $start and $end"
    $totalCount = 0
    [DateTime]$currentStart = $start

    while ($true) {
        $currentEnd = $currentStart.AddMinutes($intervalMinutes)
        if ($currentEnd -gt $end) { $currentEnd = $end }
        if ($currentStart -eq $currentEnd) { break }

        $sessionID = [Guid]::NewGuid().ToString()
        $results = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd -RecordType $record -SessionId $sessionID -SessionCommand ReturnLargeSet -ResultSize $resultSize

        if (($results | Measure-Object).Count -ne 0) {
            foreach ($result in $results) {
                $auditJson = $result.AuditData | ConvertFrom-Json
                if ($auditJson.ClassificationInfo -and $auditJson.ClassificationInfo.SensitiveInformation) {
                    foreach ($si in $auditJson.ClassificationInfo.SensitiveInformation) {
                        if ($SITHash.ContainsKey($si.SensitiveType)) {
                            $si.SensitiveType = $SITHash[$si.SensitiveType]
                        }
                    }
                    $result.AuditData = $auditJson | ConvertTo-Json -Compress
                }
            }
            $results | Export-Csv -Path $outputFile -Append -NoTypeInformation
            $totalCount += $results.Count
            Write-LogFile "INFO: Retrieved $($results.Count) for $record"
        }

        if ($currentEnd -eq $end) { break }
        $currentStart = $currentEnd
    }

    Write-LogFile "END: Retrieved $totalCount total records for $record"
}
