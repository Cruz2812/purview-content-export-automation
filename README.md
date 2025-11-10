# Purview Content Export Automation

PowerShell runbooks to export Microsoft Purview / M365 data at scale, designed to run in Azure Automation on a recurring schedule.

## What this contains
- `start-content-explorer-exports.ps1` — master orchestrator that kicks off Content Explorer exports for all SITs/workloads, restarts failed jobs, and combines performance reports.
- `content-explorer-export-template.ps1` — base script that handles paging, page cookies, GUID-to-name decoding for labels/SITs, and CSV export.
- `update-automation-runbooks.ps1` — connects to Azure, finds all `.ps1` scripts in a folder, imports/updates them as Automation Runbooks, and binds them to a monthly schedule.
- `export-activity-explorer-data.ps1` — exports Activity Explorer data in pages, adds headers on non-first pages, and merges to a final CSV.
- `export-ediscovery-by-sit.ps1` — creates an eDiscovery case, iterates through Sensitive Information Types, and exports results.
- `export-odsp-audit-records.ps1` — pulls OneDrive/SharePoint audit records for specific record types and normalizes SIT GUIDs to names.

All file system paths have been de-identified. Replace `<Path>` with your storage/account path before running.

## Prerequisites
- PowerShell 7+ recommended
- `ExchangeOnlineManagement` and `Az` modules
- An Azure Automation Account (if running in Azure)
- Service principal or certificate-based auth with appropriate Purview/M365 permissions

## Usage
1. Update the parameter block at the top of the script(s) with:
   - `<Path>` for exports
   - Automation account name
   - Resource group
2. Run locally to validate.
3. Import into Azure Automation and attach to the schedule named in the script (`ContentExplorer_Monthly`).

## Why this exists
Large orgs hit paging, throttling, and GUID readability problems with Purview exports. These scripts:
- page through large result sets
- restart failed jobs
- output *human-readable* CSVs

## Future enhancements
- Add Graph-based token retrieval to remove interactive logins
- Add storage account upload step
- Add Power BI-ready schema
