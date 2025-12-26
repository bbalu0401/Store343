#!/usr/bin/env python3
"""Test IMG_6427 with compression"""

import requests
import base64
from PIL import Image
import io

API_URL = "https://store343-production.up.railway.app/api/process-beosztas"
IMAGE_PATH = "/home/user/Store343/IMG_6427.jpeg"

print("📸 Loading and compressing image...")

# Load image
img = Image.open(IMAGE_PATH)
print(f"Original size: {img.size} ({IMAGE_PATH.split('/')[-1]})")

# Calculate new size (max 1920px width)
max_width = 1920
if img.width > max_width:
    ratio = max_width / img.width
    new_size = (max_width, int(img.height * ratio))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    print(f"Resized to: {img.size}")

# Compress to JPEG with quality 85
buffer = io.BytesIO()
img.save(buffer, format='JPEG', quality=85, optimize=True)
compressed_bytes = buffer.getvalue()

print(f"Compressed size: {len(compressed_bytes) / 1024:.1f} KB")

# Encode to base64
image_base64 = base64.b64encode(compressed_bytes).decode('utf-8')

print("📤 Sending to Railway with 240 sec timeout...")

payload = {
    "image_base64": image_base64,
    "image_type": "image/jpeg"
}

try:
    response = requests.post(API_URL, json=payload, timeout=240)
    result = response.json()

    if result.get("success"):
        employees = result.get("employees", [])
        print(f"\n✅ SUCCESS! Found {len(employees)} employees")

        for emp in employees:
            print(f"   - {emp.get('name')} ({len(emp.get('shifts', []))} shifts, {emp.get('weekly_hours', 'N/A')} hrs)")

        print(f"\n📊 Tokens: IN={result['usage']['input_tokens']} OUT={result['usage']['output_tokens']}")
    else:
        print(f"\n❌ Failed: {result.get('error')}")

except requests.exceptions.Timeout:
    print("\n❌ Still timed out after 240 seconds")
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
