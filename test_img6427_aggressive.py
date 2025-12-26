#!/usr/bin/env python3
"""Test IMG_6427 with aggressive compression"""

import requests
import base64
from PIL import Image
import io

API_URL = "https://store343-production.up.railway.app/api/process-beosztas"
IMAGE_PATH = "/home/user/Store343/IMG_6427.jpeg"

print("📸 Loading and AGGRESSIVELY compressing image...")

# Load image
img = Image.open(IMAGE_PATH)
print(f"Original size: {img.size} ({img.width}x{img.height} pixels)")

# Resize to max 1400px width (smaller = faster)
max_width = 1400
if img.width > max_width:
    ratio = max_width / img.width
    new_size = (max_width, int(img.height * ratio))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    print(f"Resized to: {img.size} ({img.width}x{img.height} pixels)")

# Compress to JPEG with quality 75 (lower = smaller file)
buffer = io.BytesIO()
img.save(buffer, format='JPEG', quality=75, optimize=True)
compressed_bytes = buffer.getvalue()

print(f"File size: 556 KB → {len(compressed_bytes) / 1024:.1f} KB ({(len(compressed_bytes) / (556*1024) * 100):.1f}%)")

# Encode to base64
image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')

print("📤 Sending to Railway with 300 sec timeout...")
print("⏳ This may take 2-3 minutes for large schedule tables...")

payload = {
    "image_base64": image_base64,
    "image_type": "image/jpeg"
}

try:
    response = requests.post(API_URL, json=payload, timeout=300)

    print(f"\n📡 HTTP Status: {response.status_code}")

    if response.status_code == 200:
        result = response.json()

        if result.get("success"):
            employees = result.get("employees", [])
            print(f"\n✅ SUCCESS! Found {len(employees)} employees\n")

            for emp in employees:
                name = emp.get('name')
                shifts = emp.get('shifts', [])
                hours = emp.get('weekly_hours', 'N/A')
                print(f"   - {name}: {len(shifts)} shifts, {hours} hrs/week")

            print(f"\n📊 Token Usage:")
            print(f"   Input: {result['usage']['input_tokens']}")
            print(f"   Output: {result['usage']['output_tokens']}")
        else:
            print(f"\n❌ API returned error: {result.get('error')}")
    else:
        print(f"\n❌ HTTP error: {response.status_code}")
        print(f"Response: {response.text}")

except requests.exceptions.Timeout:
    print("\n❌ Request timed out after 300 seconds")
    print("This image is too complex. Consider splitting it or using lower resolution.")
except requests.exceptions.RequestException as e:
    print(f"\n❌ Request error: {str(e)}")
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
