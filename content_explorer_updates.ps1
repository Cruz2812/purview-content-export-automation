# Generates multiple Content Explorer export scripts from a template and a CSV config.

$templateFile = "<template_path>"
$configFile = "<config_csv>"
$outputDir = "<output_dir>"

$templateContent = Get-Content -Path $templateFile -Raw
$config = Import-Csv -Path $configFile

foreach ($entry in $config) {
    $fileName = $entry.FileName
    $sit = $entry.SIT
    $workload = $entry.Workload

    $scriptContent = @"
# Auto-generated Content Explorer script
\$SIT = '$sit'
\$Workload = '$workload'

$templateContent
"@

    if (-not $fileName.EndsWith(".ps1")) {
        $fileName += ".ps1"
    }
    $outputPath = Join-Path -Path $outputDir -ChildPath $fileName
    Set-Content -Path $outputPath -Value $scriptContent
    Write-Host "Updated: $fileName"
}

Write-Host "All scripts updated successfully."
