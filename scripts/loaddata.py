import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path

# Database connection
username = "yourusername"
password = "yourpassword"
host = "host"
port = "port"
database = "online_project"


engine = create_engine(
    f"postgresql+psycopg2://{username}:{password}@{host}:{port}/{database}"
)

# Dataset folder
folder_path = Path(r"C:\path\online_food_delivery project\datasets")

# Process files
for file in folder_path.glob("*.csv"):

    try:
        # Skip empty files
        if file.stat().st_size == 0:
            print(f"Skipped empty file: {file.name}")
            continue

        # Table name
        table_name = file.stem.lower()

        # Read CSV
        df = pd.read_csv(file)

        # Load to PostgreSQL
        df.to_sql(
            name=table_name,
            con=engine,
            schema="online_p",
            if_exists='replace',
            index=False
        )

        print(f"Successfully loaded: {file.name}")

    except Exception as e:
        print(f"Failed to load {file.name}: {e}")

print("Import process completed.")


