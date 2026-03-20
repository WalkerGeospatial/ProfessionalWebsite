import os
import glob
import time
import pytesseract
import pandas as pd
from pdf2image import convert_from_path
from openai import AzureOpenAI

# Azure OpenAI Configuration
AZURE_API_KEY = ""               # Set your Azure OpenAI API key
AZURE_API_VERSION = "2024-08-01-preview"
AZURE_ENDPOINT = "https://YOUR_AZURE_ENDPOINT.openai.azure.com/"
DEPLOYMENT_NAME = "gpt-4o-mini"

# Directory containing the PDF CCTV reports
PDF_DIRECTORY = r"C:\path\to\cctv_reports"

# Initialize Azure OpenAI client
client = AzureOpenAI(
    api_key=AZURE_API_KEY,
    api_version=AZURE_API_VERSION,
    azure_endpoint=AZURE_ENDPOINT
)

def extract_text_from_pdf(pdf_path):
    """Extract text from a PDF file using OCR."""
    try:
        images = convert_from_path(pdf_path)
        text = " ".join([pytesseract.image_to_string(img) for img in images])
        return text.strip()
    except Exception as e:
        print(f"OCR failed for {pdf_path}: {e}")
        return ""

def extract_manhole_conditions(pdf_name, ocr_text):
    """Use Azure OpenAI to extract upstream and downstream manholes with conditions."""
    prompt = f"""
    The following text was extracted from a CCTV sewer inspection report named {pdf_name}.
    Identify the upstream and downstream manhole IDs along with their reported conditions.

    Return the result in the following format, separating values with a "|":
    Upstream Manhole | Upstream Condition | Downstream Manhole | Downstream Condition

    If any value is missing, write "Unknown". If no data is found, return "No data found".

    Text:
    {ocr_text}
    """

    try:
        response = client.chat.completions.create(
            model=DEPLOYMENT_NAME,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=100
        )
        time.sleep(1)  # Prevent hitting rate limits
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"Error processing {pdf_name}: {e}")
        return "Error | Error | Error | Error"

def main():
    """Scan directory for PDFs, extract manhole data, and save results to CSV."""
    pdf_files = glob.glob(os.path.join(PDF_DIRECTORY, "*.pdf"))
    output_data = []

    for pdf_path in pdf_files:
        pdf_name = os.path.basename(pdf_path)
        print(f"Processing: {pdf_name}")

        ocr_text = extract_text_from_pdf(pdf_path)
        if not ocr_text:
            print(f"Skipping {pdf_name} (OCR failed)")
            continue

        manhole_data = extract_manhole_conditions(pdf_name, ocr_text)

        # Ensure consistent data structure
        parsed_data = manhole_data.split("|")
        if len(parsed_data) != 4:
            parsed_data = ["Error", "Error", "Error", "Error"]

        output_data.append([pdf_name] + [item.strip() for item in parsed_data])

    # Save results to CSV
    df = pd.DataFrame(output_data, columns=[
        "File Name", "Upstream Manhole", "Upstream Condition",
        "Downstream Manhole", "Downstream Condition"
    ])
    df.to_csv("cctv_manhole_conditions.csv", index=False)
    print("Results saved to cctv_manhole_conditions.csv.")

if __name__ == "__main__":
    main()