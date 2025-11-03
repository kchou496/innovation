"""
Download all data files from USDA ERS Fruit and Vegetable Prices page
URL: https://www.ers.usda.gov/data-products/fruit-and-vegetable-prices
"""

import os
import requests
from urllib.parse import urlparse
import time
import zipfile

# Add your download URLs here
DOWNLOAD_URLS = [
    # Add your URLs here, for example:
    # "https://www.ers.usda.gov/webdocs/DataFiles/50472/vegetables2013.xlsx",
    # "https://www.ers.usda.gov/webdocs/DataFiles/50472/fruit2013.xlsx",
    # "https://www.ers.usda.gov/webdocs/DataFiles/50472/vegetables2016.xlsx",
    # "https://www.ers.usda.gov/webdocs/DataFiles/50472/fruit2016.xlsx",
    "https://ers.usda.gov/sites/default/files/_laserfiche/DataFiles/51035/Fruit-Prices-2022.csv?v=64514",
    "https://ers.usda.gov/sites/default/files/_laserfiche/DataFiles/51035/Vegetable-Prices-2022.csv?v=64879",
    "https://ers.usda.gov/sites/default/files/_laserfiche/DataFiles/51035/vegetables-2020.zip?v=30838"
]


def download_file(url, output_dir="downloads"):
    """Download a file from URL to the output directory"""
    try:
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Get filename from URL (remove query parameters)
        parsed_url = urlparse(url)
        filename = os.path.basename(parsed_url.path)
        if not filename:
            filename = "download_file"
        
        output_path = os.path.join(output_dir, filename)
        
        print(f"Downloading: {filename}")
        print(f"  from: {url}")
        
        # Download the file with headers to mimic browser
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, stream=True, timeout=30, headers=headers)
        
        # Check response status
        print(f"  Response status: {response.status_code}")
        response.raise_for_status()
        
        # Check content type
        content_type = response.headers.get('Content-Type', 'unknown')
        print(f"  Content-Type: {content_type}")
        
        # Save to file
        with open(output_path, 'wb') as f:
            bytes_written = 0
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:  # filter out keep-alive new chunks
                    f.write(chunk)
                    bytes_written += len(chunk)
        
        file_size = os.path.getsize(output_path)
        print(f"  ✓ Saved to: {output_path} ({file_size:,} bytes)")
        
        # Check if file is actually empty or very small
        if file_size < 100:
            print(f"  ⚠️  Warning: File is very small ({file_size} bytes) - may not have downloaded correctly")
            # Try to read and show first few bytes
            with open(output_path, 'rb') as f:
                content_preview = f.read(file_size)
                print(f"  Content preview: {content_preview[:100]}")
        
        # Check if it's a zip file and extract it
        if filename.lower().endswith('.zip'):
            print(f"  📦 Extracting zip file...")
            try:
                with zipfile.ZipFile(output_path, 'r') as zip_ref:
                    # Get list of files in zip
                    zip_contents = zip_ref.namelist()
                    print(f"  Found {len(zip_contents)} file(s) in zip:")
                    
                    # Extract all files to the same directory
                    for file_in_zip in zip_contents:
                        zip_ref.extract(file_in_zip, output_dir)
                        extracted_path = os.path.join(output_dir, file_in_zip)
                        if os.path.exists(extracted_path):
                            extracted_size = os.path.getsize(extracted_path)
                            print(f"    ✓ {file_in_zip} ({extracted_size:,} bytes)")
                        else:
                            print(f"    ✗ Failed to extract: {file_in_zip}")
                    
                    # Optionally remove the zip file after extraction
                    # Uncomment the next two lines if you want to delete the zip after extracting
                    # os.remove(output_path)
                    # print(f"  🗑️  Removed zip file: {filename}")
                    
            except zipfile.BadZipFile:
                print(f"  ✗ Error: {filename} is not a valid zip file")
                return False
        
        return True
        
    except requests.exceptions.HTTPError as e:
        print(f"  ✗ HTTP Error: {e}")
        print(f"  Response content: {e.response.text[:500] if hasattr(e, 'response') else 'N/A'}")
        return False
    except Exception as e:
        print(f"  ✗ Error downloading {url}: {type(e).__name__}: {e}")
        import traceback
        print(f"  Traceback: {traceback.format_exc()}")
        return False

def main():
    output_dir = "usda_fruit_veg_data"
    
    print("=" * 70)
    print("USDA ERS Fruit and Vegetable Prices Data Downloader")
    print("=" * 70)
    print()
    
    if not DOWNLOAD_URLS:
        print("\n⚠️  No URLs configured!")
        print("\nTo use this script:")
        print("1. Visit the webpage in your browser:")
        print("   https://www.ers.usda.gov/data-products/fruit-and-vegetable-prices")
        print("2. Right-click on each download link and copy the URL")
        print("3. Add the URLs to the DOWNLOAD_URLS list at the top of this script")
        print("\nExample:")
        print("DOWNLOAD_URLS = [")
        print('    "https://www.ers.usda.gov/webdocs/DataFiles/50472/fruit2022.xlsx",')
        print('    "https://www.ers.usda.gov/webdocs/DataFiles/50472/vegetables2022.xlsx",')
        print("]")
        return
    
    print(f"Configured {len(DOWNLOAD_URLS)} file(s) to download:\n")
    for i, url in enumerate(DOWNLOAD_URLS, 1):
        filename = os.path.basename(urlparse(url).path)
        print(f"{i}. {filename}")
    
    print(f"\n{'=' * 70}")
    print("Starting downloads...")
    print(f"{'=' * 70}\n")
    
    # Download each file
    success_count = 0
    for i, url in enumerate(DOWNLOAD_URLS, 1):
        print(f"\n[{i}/{len(DOWNLOAD_URLS)}]")
        if download_file(url, output_dir):
            success_count += 1
        time.sleep(0.5)  # Be polite to the server
    
    print(f"\n{'=' * 70}")
    print(f"Download complete: {success_count}/{len(DOWNLOAD_URLS)} successful")
    print(f"Files saved to: {os.path.abspath(output_dir)}/")
    print(f"{'=' * 70}")

if __name__ == "__main__":
    main()
