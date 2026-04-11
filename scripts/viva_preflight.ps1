param(
    [switch]$Open
)

$ErrorActionPreference = "Stop"

function Find-Executable {
    param(
        [string[]]$CommandNames,
        [string[]]$KnownPaths
    )

    foreach ($name in $CommandNames) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    foreach ($path in $KnownPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Write-Status {
    param(
        [string]$Label,
        [bool]$Ok,
        [string]$Detail
    )

    $tag = if ($Ok) { "OK" } else { "MISSING" }
    Write-Host ("[{0}] {1} - {2}" -f $tag, $Label, $Detail)
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

Write-Host "=== Viva Preflight ==="
Write-Host ("Repo: {0}" -f $repoRoot)

# Required files for demonstration
$requiredFiles = @(
    "README.md",
    "DATASET_SOURCE.txt",
    "Data Warehouse/LAPDCrimeDW_ETL/LAPDCrimeDW_ETL.sln",
    "Data Warehouse/LAPDCrimeDW_ETL/LoadStaging.dtsx",
    "Data Warehouse/LAPDCrimeDW_ETL/LoadDimensions.dtsx",
    "Data Warehouse/LAPDCrimeDW_ETL/LoadFact.dtsx",
    "Data Warehouse/LAPDCrimeDW_ETL/LoadAccumulating.dtsx",
    "LAPDCrimeCube/LAPDCrimeCube.sln",
    "LAPDCrimeCube/LAPDCrimeCube.cube",
    "Excel/Excel_LAPDCrimeDW_IT23203280.xlsx",
    "PowerBI/PowerBIReports.pbix",
    "VIVA_PREP_GUIDE.md"
)

Write-Host ""
Write-Host "-- Files --"
foreach ($relPath in $requiredFiles) {
    $fullPath = Join-Path $repoRoot $relPath
    $ok = Test-Path $fullPath
    Write-Status -Label $relPath -Ok $ok -Detail $(if ($ok) { "found" } else { "not found" })
}

# Submitted documents check (if present inside repo)
Write-Host ""
Write-Host "-- Submitted Docs In Repo --"
$docPatterns = @("*.pdf", "*.docx", "*.pptx")
$docFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Include $docPatterns |
    Where-Object { $_.FullName -notmatch "\\(bin|obj|\.git)\\" }

if ($docFiles.Count -gt 0) {
    Write-Status -Label "Documents" -Ok $true -Detail ("{0} file(s) detected" -f $docFiles.Count)
    $docFiles | ForEach-Object { Write-Host ("  - {0}" -f $_.FullName.Replace($repoRoot + "\\", "")) }
}
else {
    Write-Status -Label "Documents" -Ok $false -Detail "No PDF/DOCX/PPTX found in this repo"
}

# Tool checks
Write-Host ""
Write-Host "-- Tools --"
$ssmsPath = Find-Executable -CommandNames @("ssms") -KnownPaths @(
    "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe",
    "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe",
    "C:\Program Files\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"
)

$vsPath = Find-Executable -CommandNames @("devenv") -KnownPaths @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe"
)

$powerBIPath = Find-Executable -CommandNames @("PBIDesktop") -KnownPaths @(
    "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "C:\Program Files\Microsoft Power BI Desktop RS\bin\PBIDesktop.exe"
)

$excelPath = Find-Executable -CommandNames @("excel") -KnownPaths @(
    "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE",
    "C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE"
)

Write-Status -Label "SSMS" -Ok ($null -ne $ssmsPath) -Detail $(if ($ssmsPath) { $ssmsPath } else { "not detected" })
Write-Status -Label "Visual Studio" -Ok ($null -ne $vsPath) -Detail $(if ($vsPath) { $vsPath } else { "not detected" })
Write-Status -Label "Power BI Desktop" -Ok ($null -ne $powerBIPath) -Detail $(if ($powerBIPath) { $powerBIPath } else { "not detected" })
Write-Status -Label "Excel" -Ok ($null -ne $excelPath) -Detail $(if ($excelPath) { $excelPath } else { "not detected" })

# Warn about machine-specific absolute paths in SSIS connection strings
Write-Host ""
Write-Host "-- SSIS Path Warnings --"
$dtsxFiles = @(
    "Data Warehouse/LAPDCrimeDW_ETL/LoadStaging.dtsx",
    "Data Warehouse/LAPDCrimeDW_ETL/LoadDimensions.dtsx"
)

foreach ($rel in $dtsxFiles) {
    $full = Join-Path $repoRoot $rel
    if (-not (Test-Path $full)) {
        continue
    }

    $matches = Select-String -Path $full -Pattern 'ConnectionString="[A-Za-z]:\\' -AllMatches
    if ($matches) {
        Write-Status -Label $rel -Ok $false -Detail "Contains absolute local drive path(s); verify before viva"
    }
    else {
        Write-Status -Label $rel -Ok $true -Detail "No absolute drive path detected"
    }
}

if ($Open) {
    Write-Host ""
    Write-Host "-- Opening Materials --"

    $toOpen = @(
        "VIVA_PREP_GUIDE.md",
        "README.md",
        "Data Warehouse/LAPDCrimeDW_ETL/LAPDCrimeDW_ETL.sln",
        "LAPDCrimeCube/LAPDCrimeCube.sln",
        "Excel/Excel_LAPDCrimeDW_IT23203280.xlsx",
        "PowerBI/PowerBIReports.pbix"
    )

    foreach ($rel in $toOpen) {
        $full = Join-Path $repoRoot $rel
        if (Test-Path $full) {
            Start-Process $full
            Write-Host ("Opened: {0}" -f $rel)
        }
        else {
            Write-Host ("Skipped (missing): {0}" -f $rel)
        }
    }

    if ($ssmsPath) {
        Start-Process $ssmsPath
        Write-Host "Opened: SSMS"
    }
}

Write-Host ""
Write-Host "Preflight complete."
