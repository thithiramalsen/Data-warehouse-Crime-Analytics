# LAPD dataset helpers

This repository provides a small utility to extract lookup tables from the LAPD crime CSV.

Quick start (PowerShell from repo root):

1. Create a virtual environment (optional):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Run the extractor:

```powershell
python scripts\extract_lapd_lookups.py
```

Outputs are written to the `output/` folder:

- `output/CrimeCategories.xlsx`
- `output/WeaponLookup.csv`

Notes:
- The raw CSV is expected at `dataset/Crime_Data_from_2020_to_2024_20260326.csv`
- The dataset CSV is large and is ignored by Git. If it was previously tracked, run:

```powershell
git rm --cached dataset/Crime_Data_from_2020_to_2024_20260326.csv
git commit -m "Stop tracking large dataset file"
```
