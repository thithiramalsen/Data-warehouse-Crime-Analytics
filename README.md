# LAPD Crime Analytics Data Warehouse + Cube

This repository contains:

- A SQL Server Integration Services (SSIS) ETL project for loading a crime analytics data warehouse.
- A SQL Server Analysis Services (SSAS) multidimensional cube project for analysis.
- A Python helper script to extract lookup tables from LAPD public data.

The large source dataset is intentionally not committed to Git.

## Repository Layout

- `Data Warehouse/`
  - `Datasets/` (local data only, large raw CSV excluded from Git)
  - `LAPDCrimeDW_ETL/` (main SSIS project)
- `LAPDCrimeCube/` (SSAS cube project)
- `scripts/` (Python utilities)
- `requirements.txt` (Python dependencies)
- `DATASET_SOURCE.txt` (official LAPD dataset link and placement instructions)
 - `Excel/` (analysis workbooks and pivot reports)
 - `PowerBI/` (Power BI Desktop files and dashboards)

## Dataset Setup (Required)

1. Download the dataset from the official source listed in `DATASET_SOURCE.txt`.
2. Save the CSV with this file name:

	`Crime_Data_from_2020_to_2024_20260326.csv`

3. Place it at:

	`Data Warehouse/Datasets/Crime_Data_from_2020_to_2024_20260326.csv`

The Python helper also supports a legacy location:

`dataset/Crime_Data_from_2020_to_2024_20260326.csv`

The CSV is ignored by `.gitignore` so it stays local.

## Working with the Data Warehouse (SSIS)

Open:

- `Data Warehouse/LAPDCrimeDW_ETL/LAPDCrimeDW_ETL.sln`

Then run packages as needed (for example: staging, dimensions, fact, accumulating loads) from Visual Studio with SSIS installed.

## Working with the Cube (SSAS)

Open:

- `LAPDCrimeCube/LAPDCrimeCube.sln`

Then deploy/process from Visual Studio with SSAS project support.

## Python Lookup Extraction Helper

From repository root (PowerShell):

1. Optional virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Run extractor:

```powershell
python scripts\extract_lapd_lookups.py
```

Generated outputs are written to `output/`.

## Excel & Power BI

- `Excel/` contains analysis workbooks, pivot tables, and supporting spreadsheets used during exploration and reporting. Keep workbooks lightweight by sourcing the CSV from `Data Warehouse/Datasets/` and avoid embedding large data in files.
- `PowerBI/` contains Power BI Desktop (`.pbix`) files and related artifacts. Power BI reports should connect to the local CSV (or a local database build of the warehouse) rather than storing the raw CSV inside the `.pbix` whenever possible.

When sharing reports, include instructions or a data source file path (see `DATASET_SOURCE.txt`) so others can reproduce the connections locally.

## Git Notes

- Large raw CSV input is excluded from Git.
- Generated build artifacts and user-specific Visual Studio files are excluded.
- Existing warehouse and cube source files are preserved as-is.
