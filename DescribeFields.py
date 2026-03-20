import time
import pandas as pd
from openai import AzureOpenAI

# Azure OpenAI setup
AZURE_API_KEY = ""               # Set your Azure OpenAI API key
AZURE_API_VERSION = "2024-08-01-preview"
AZURE_ENDPOINT = "https://YOUR_AZURE_ENDPOINT.openai.azure.com/"
DEPLOYMENT_NAME = "gpt-4o-mini"

client = AzureOpenAI(
    api_key=AZURE_API_KEY,
    api_version=AZURE_API_VERSION,
    azure_endpoint=AZURE_ENDPOINT
)

# Load AGOL field inventory CSV
# Expected columns: FeatureServiceTitle, LayerOrTableName, FieldName, FieldAlias, FieldType, Domain
df = pd.read_csv("AGOL_FieldInventory.csv")

if "Description" not in df.columns:
    df["Description"] = ""

def generate_field_description(row):
    """Ask Azure OpenAI to generate a brief description of a GIS field."""
    prompt = f"""
    You are documenting GIS schema fields for a municipal utility organization.
    Write a concise, clear description (1–2 sentences) of the purpose of the following field:

    Feature Service: {row['FeatureServiceTitle']}
    Layer or Table: {row['LayerOrTableName']}
    Field Name: {row['FieldName']}
    Field Alias: {row['FieldAlias']}
    Field Type: {row['FieldType']}
    Domain: {row['Domain'] if pd.notna(row['Domain']) else "None"}

    Example output:
    "Indicates the operational status of the hydrant, such as Active or Inactive."

    Keep it factual and neutral. If you cannot infer the meaning, respond with "No description available."
    """

    try:
        response = client.chat.completions.create(
            model=DEPLOYMENT_NAME,
            messages=[
                {"role": "system", "content": "You are a GIS data documentation assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=80,
            temperature=0.3
        )
        time.sleep(0.8)  # Gentle rate limiting
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"Error generating description for {row['FieldName']}: {e}")
        return "Error"

# Loop through fields — skips rows that already have a description
for idx, row in df.iterrows():
    if not row["Description"] or row["Description"] in ["Error", "No description available"]:
        print(f"Processing: {row['FieldName']} ({row['LayerOrTableName']})")
        desc = generate_field_description(row)
        df.at[idx, "Description"] = desc

# Save results
df.to_csv("AGOL_FieldInventory_Described.csv", index=False, encoding="utf-8-sig")
print("Field descriptions saved to AGOL_FieldInventory_Described.csv")