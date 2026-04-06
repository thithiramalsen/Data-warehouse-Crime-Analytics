from pathlib import Path
from datetime import datetime

import pandas as pd


def categorize_crime(code: int) -> tuple[str, str]:
    if code in {110, 113}:
        return "Violent Crime", "Homicide"
    if code in {121, 122}:
        return "Violent Crime", "Sexual Assault"
    if code in {210, 220}:
        return "Violent Crime", "Robbery"
    if code in {230, 231, 235, 236}:
        return "Violent Crime", "Aggravated Assault"
    if code in {622, 623, 624, 625, 626, 627, 860}:
        return "Violent Crime", "Simple Assault"
    if code in {310, 320, 330, 331, 410}:
        return "Property Crime", "Burglary"
    if code in {480, 485, 487, 510, 520, 522}:
        return "Property Crime", "Vehicle/Bike Theft"
    if code in {350, 351, 352, 353, 440, 441, 442, 443, 444, 445, 446}:
        return "Property Crime", "Petty Theft"
    if code in {341, 343, 345, 349, 668}:
        return "Property Crime", "Grand Theft"
    if code in {354, 649, 651, 652, 653, 654, 660, 662, 664, 666}:
        return "Financial Crime", "Fraud/Forgery"
    if code in {760, 810, 812, 813, 814, 815, 820, 821, 822, 830, 840, 850}:
        return "Sex Crime", "Sex Offenses"
    if code in {900, 901, 902, 903, 904, 906}:
        return "Public Order", "Court Orders"
    if code in {910, 920, 922}:
        return "Violent Crime", "Kidnapping"
    if code in {647, 740, 745}:
        return "Property Crime", "Vandalism"
    return "Other Crime", "Miscellaneous"


def categorize_weapon(code: int) -> str:
    if 100 <= code <= 125:
        return "Firearm"
    if 200 <= code <= 223:
        return "Blade/Cutting"
    if 300 <= code <= 312:
        return "Blunt/Physical Object"
    if code == 400:
        return "Physical Force"
    return "Other/Unknown"


def fallback_output_path(path: Path) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return path.with_name(f"{path.stem}_{timestamp}{path.suffix}")


def main() -> None:
    # repo root is two levels up from this script when located in scripts/
    root_dir = Path(__file__).resolve().parents[1]
    dataset_filename = "Crime_Data_from_2020_to_2024_20260326.csv"
    candidate_input_paths = [
        root_dir / "Data Warehouse" / "Datasets" / dataset_filename,
        root_dir / "dataset" / dataset_filename,
    ]
    input_csv = next((path for path in candidate_input_paths if path.exists()), candidate_input_paths[0])

    if not input_csv.exists():
        searched_paths = "\n".join(f"- {path}" for path in candidate_input_paths)
        raise FileNotFoundError(
            "Dataset CSV not found. Place the file in one of these locations:\n"
            f"{searched_paths}"
        )

    output_dir = root_dir / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    crime_output = output_dir / "CrimeCategories.xlsx"
    weapon_output = output_dir / "WeaponLookup.csv"

    print("Loading dataset...")
    df = pd.read_csv(input_csv, low_memory=False)

    print("Columns found:")
    print(df.columns.tolist())

    crime_df = df[["Crm Cd", "Crm Cd Desc"]].copy()
    crime_df["Crm Cd"] = pd.to_numeric(crime_df["Crm Cd"], errors="coerce")
    crime_df = crime_df.dropna(subset=["Crm Cd", "Crm Cd Desc"]).drop_duplicates()
    crime_df["Crm Cd"] = crime_df["Crm Cd"].astype("int64")
    crime_df.columns = ["crime_code", "crime_description"]
    crime_df = crime_df.sort_values("crime_code").reset_index(drop=True)

    crime_df[["crime_category", "crime_group"]] = crime_df["crime_code"].apply(
        lambda x: pd.Series(categorize_crime(int(x)))
    )

    weapon_df = df[["Weapon Used Cd", "Weapon Desc"]].copy()
    weapon_df["Weapon Used Cd"] = pd.to_numeric(weapon_df["Weapon Used Cd"], errors="coerce")
    weapon_df = weapon_df.dropna(subset=["Weapon Used Cd", "Weapon Desc"]).drop_duplicates()
    weapon_df["Weapon Used Cd"] = weapon_df["Weapon Used Cd"].astype("int64")
    weapon_df.columns = ["weapon_code", "weapon_description"]
    weapon_df = weapon_df.sort_values("weapon_code").reset_index(drop=True)
    weapon_df["weapon_type"] = weapon_df["weapon_code"].apply(
        lambda x: categorize_weapon(int(x))
    )

    final_crime_output = crime_output
    final_weapon_output = weapon_output

    try:
        crime_df.to_excel(crime_output, index=False)
    except PermissionError:
        final_crime_output = fallback_output_path(crime_output)
        crime_df.to_excel(final_crime_output, index=False)
        print(
            f"Warning: {crime_output.name} is in use. Saved crime output to {final_crime_output.name} instead."
        )

    try:
        weapon_df.to_csv(weapon_output, index=False)
    except PermissionError:
        final_weapon_output = fallback_output_path(weapon_output)
        weapon_df.to_csv(final_weapon_output, index=False)
        print(
            f"Warning: {weapon_output.name} is in use. Saved weapon output to {final_weapon_output.name} instead."
        )

    print("Done!")
    print(f"Crime categories: {len(crime_df)} rows saved to {final_crime_output}")
    print(f"Weapon lookup: {len(weapon_df)} rows saved to {final_weapon_output}")


if __name__ == "__main__":
    main()
