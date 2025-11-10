# Creates a compliance case and runs searches for each SIT, logging progress.

Connect-IPPSSession -UseRPSSession:$false

$time = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$caseName = "SIT_Case_" + $time
$outputFolder = "<output_path>"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}
$logFile = Join-Path $outputFolder "EDiscoveryLogFile.txt"

$SITs = Get-DlpSensitiveInformationType
$SITHash = @{}
$SITs.ForEach({ $SITHash.Add($_.Name, $_.Id) })

function Write-LogFile([string]$Message) {
    $final = ([DateTime]::UtcNow.ToString("s")) + ":" + $Message
    $final | Out-File $logFile -Append
}

Write-LogFile "BEGIN: Creating eDiscovery case $caseName"
New-ComplianceCase -Name $caseName | Out-Null
Write-LogFile "Case created."

foreach ($sit in $SITHash.GetEnumerator()) {
    $searchName = ($sit.Key -replace "'", "") + "_" + $caseName
    $query = "SensitiveType:$($sit.Value)"
    Write-LogFile "Creating search $searchName for $($sit.Key)"
    New-ComplianceSearch -Name $searchName -Case $caseName -ContentMatchQuery $query -SharePointLocation All | Out-Null
    Start-ComplianceSearch -Identity $searchName | Out-Null
    Write-LogFile "Started search $searchName"
}

Write-LogFile "END: Submitted all SIT searches."
