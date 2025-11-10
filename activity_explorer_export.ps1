# Exports Activity Explorer data in pages and decodes label GUIDs.

Connect-IPPSSession -UseRPSSession:$false

$date = Get-Date -Format "MM.dd.yyyy"
$endDate = Get-Date
$startDate = $endDate.AddDays(-30)

$page = 1
$pageSize = 5000
$maxRetry = 5
$delaySeconds = 5
$lastPageCookie = $null

$basePath = "<output_path>\ActivityExplorer\$date"
if (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}

$headers = "Activity, Happened, RecordIdentity, Workload, User, FilePath, HowApplied, HowAppliedDetail, LabelEventType, ClientIP, FileExtension, FileType, SensitivityLabel, OldSensitivityLabel, SensitivityLabelPolicyId"

do {
    if (-not $lastPageCookie) {
        $results = Export-ActivityExplorerData -StartTime $startDate -EndTime $endDate -OutputFormat csv -PageSize $pageSize
    } else {
        $results = Export-ActivityExplorerData -StartTime $startDate -EndTime $endDate -OutputFormat csv -PageSize $pageSize -PageCookie $lastPageCookie
    }

    if ($results -ne $null) {
        $csvPath = Join-Path $basePath "Export_Page_${page}_$date.csv"
        if ($page -eq 1 -and $results.ResultData.Substring(0,9) -ne "Activity,") {
            $results.ResultData = $headers + "`r`n" + $results.ResultData
        }
        $results.ResultData | Out-File -FilePath $csvPath -Encoding UTF8
        $lastPageCookie = $results.WaterMark
        $page++
    } else {
        Start-Sleep -Seconds $delaySeconds
    }
}
while ($results -and -not $results.LastPage)
