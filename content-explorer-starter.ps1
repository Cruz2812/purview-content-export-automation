# Orchestrates monthly Content Explorer exports and restarts failed SIT exports.

$logDate = Get-Date -Format "MM.dd.yyyy"
Start-Transcript -Path "<logs_path>\ContentExplorer_$logDate.txt" -Append

$prodFolderPath = "<content_explorer_prod_path>"
$date = Get-Date
if ($date.Day -eq 6 -and (Test-Path $prodFolderPath)) {
    Get-ChildItem -Path $prodFolderPath | ForEach-Object {
        if ($_.CreationTime -lt $date) {
            Remove-Item -Path $_.FullName -Force -Recurse
        }
    }
}

$contentExplorerScriptPath = "<scripts_path>"
$scripts = Get-ChildItem -Path $contentExplorerScriptPath -Filter "*.ps1"

$performancePath = "<performance_path>"
$completedExportsPath = "<completed_exports_path>"

function Get-JobLookUp {
    param(
        [System.IO.FileSystemInfo]$ScriptPath,
        [System.IO.FileSystemInfo]$PerformanceReport,
        [string]$FailedName
    )

    $scriptRoot = "<scripts_path>"
    $perfRoot = "<performance_path>"
    $completedRoot = "<completed_exports_path>"

    $name = $null
    if ($ScriptPath) {
        $name = $ScriptPath.Name -replace ".ps1",""
    } elseif ($PerformanceReport) {
        $name = $PerformanceReport.Name -replace "_PerformanceReport.csv",""
    } elseif ($FailedName) {
        $name = $FailedName
    }

    return [PSCustomObject]@{
        Name                = $name
        SITScriptPath       = Join-Path $scriptRoot "$name.ps1"
        PerformanceReportPath = Join-Path $perfRoot "$name`_PerformanceReport.csv"
        CompletedSITPath    = Join-Path $completedRoot "$name.txt"
    }
}

if (-not (Test-Path -Path $performancePath)) {
    foreach ($script in $scripts) {
        Start-Job -Name ($script.BaseName) -FilePath $script.FullName
    }
} else {
    $performanceReports = Get-ChildItem -Path $performancePath -Filter "*.csv"
    foreach ($report in $performanceReports) {
        $lookup = Get-JobLookUp -PerformanceReport $report
        # If SIT not complete and MorePagesAvailable in report -> restart job (logic can be expanded)
    }
}

Stop-Transcript
