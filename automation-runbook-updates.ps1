# Updates / imports PowerShell scripts as Azure Automation runbooks and links them to a monthly schedule.

Connect-AzAccount

$date = Get-Date -Format "MM.dd.yyyy"
$automationAccountName = "PurviewAutomation"
$resourceGroupName = "PurviewAutomationRG"
$scriptRoot = "<script_directory_path>"
$scripts = Get-ChildItem -Path $scriptRoot -Filter "*.ps1"

function Edit-Name {
    param([string]$RunbookName)
    $symbols = '[\\/:*?"<>|]'
    foreach ($c in $symbols.ToCharArray()) {
        $escaped = [Regex]::Escape($c)
        $RunbookName = $RunbookName -replace $escaped, ""
    }
    return $RunbookName
}

try {
    Get-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name "ContentExplorer_Monthly" -ResourceGroupName $resourceGroupName | Out-Null
}
catch {
    $TimeZone = "US/Eastern"
    New-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name "ContentExplorer_Monthly" `
        -TimeZone $TimeZone -StartTime (Get-Date).Date.AddHours(11).AddMinutes(50) `
        -MonthInterval 1 -DaysOfMonth 6 -ResourceGroupName $resourceGroupName | Out-Null
}

foreach ($script in $scripts) {
    $runbookName = [IO.Path]::GetFileNameWithoutExtension($script.Name)
    $runbookName = Edit-Name -RunbookName $runbookName

    Import-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name $runbookName -Path $script.FullName `
        -Published -ResourceGroupName $resourceGroupName -Type PowerShell -Description "Script updated: $date" -Force | Out-Null

    Register-AzAutomationScheduledRunbook -AutomationAccountName $automationAccountName -RunbookName $runbookName `
        -ScheduleName "ContentExplorer_Monthly" -ResourceGroupName $resourceGroupName | Out-Null
}
