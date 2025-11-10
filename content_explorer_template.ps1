# Base template used by Content Explorer exports.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module ExchangeOnlineManagement

$imports = Import-Csv "<path_to_auth_csv>"
Connect-IPPSSession -AppId $imports[0].AppId -CertificateThumbprint $imports[0].Thumbprint -Organization $imports[0].Organization

$SIT = "<sensitive_information_type>"
$Workload = "<workload>"
$pageSize = 100
$lastPageCookie = $null
$fileExportPath = "<export_path>.csv"
$performancePath = "<performance_path>.csv"

do {
    if (-not $lastPageCookie) {
        $results = Export-ContentExplorerData -TagName $SIT -TagType SensitiveInformationType -Workload $Workload -PageSize $pageSize -WarningAction SilentlyContinue
    } else {
        $results = Export-ContentExplorerData -TagName $SIT -TagType SensitiveInformationType -Workload $Workload -PageSize $pageSize -PageCookie $lastPageCookie -WarningAction SilentlyContinue
    }

    if ($results -ne $null) {
        $results[1..($results.Length - 1)] | Export-Csv -Path $fileExportPath -Append -NoTypeInformation
        $lastPageCookie = $results[0].PageCookie
    }
} while ($results[0].MorePagesAvailable -eq $true)
