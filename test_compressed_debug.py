#!/usr/bin/env python3
"""Test IMG_6427 with compression and debug output"""

import requests
import base64
from PIL import Image
import io

API_URL = "https://store343-production.up.railway.app/api/process-beosztas"
IMAGE_PATH = "/home/user/Store343/IMG_6427.jpeg"

print("📸 Loading and compressing image...")

# Load image
img = Image.open(IMAGE_PATH)
print(f"Original size: {img.size}")

# Calculate new size (max 1600px width for faster processing)
max_width = 1600
if img.width > max_width:
    ratio = max_width / img.width
    new_size = (max_width, int(img.height * ratio))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    print(f"Resized to: {img.size}")

# Compress to JPEG with quality 80
buffer = io.BytesIO()
img.save(buffer, format='JPEG', quality=80, optimize=True)
compressed_bytes = buffer.getvalue()

print(f"Original: 556 KB → Compressed: {len(compressed_bytes) / 1024:.1f} KB")

# Encode to base64
image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')

print("📤 Sending to Railway with 240 sec timeout...")

payload = {
    "image_base64": image_base64,
    "image_type": "image/jpeg"
}

try:
    response = requests.post(API_URL, json=payload, timeout=240)

    print(f"\n📡 HTTP Status: {response.status_code}")
    print(f"📝 Response headers: {dict(response.headers)}")
    print(f"📄 Response text (first 500 chars):\n{response.text[:500]}")

    if response.status_code == 200:
        result = response.json()

        if result.get("success"):
            employees = result.get("employees", [])
            print(f"\n✅ SUCCESS! Found {len(employees)} employees")

            for emp in employees:
                print(f"   - {emp.get('name')} ({len(emp.get('shifts', []))} shifts)")

            print(f"\n📊 Tokens: IN={result['usage']['input_tokens']} OUT={result['usage']['output_tokens']}")
        else:
            print(f"\n❌ API returned error: {result.get('error')}")
    else:
        print(f"\n❌ HTTP error: {response.status_code}")

except requests.exceptions.Timeout:
    print("\n❌ Request timed out after 240 seconds")
except requests.exceptions.RequestException as e:
    print(f"\n❌ Request error: {str(e)}")
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
