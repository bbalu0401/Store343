# Local test runner for Napi Info OCR
# Sends sample images in backend/samples to the FastAPI endpoint

import os
import base64
import json
import requests

BASE_URL = os.environ.get("OCR_API_URL", "http://localhost:8000")
SAMPLES_DIR = os.path.join(os.path.dirname(__file__), "samples")

print(f"Using API: {BASE_URL}")
print(f"Reading samples from: {SAMPLES_DIR}")

files = [f for f in os.listdir(SAMPLES_DIR) if f.lower().endswith((".jpg",".jpeg",".png"))]

if not files:
    print("No sample images found.")
    exit(1)

for fname in sorted(files):
    path = os.path.join(SAMPLES_DIR, fname)
    with open(path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")

    payload = {"image_base64": b64}
    url = f"{BASE_URL}/api/process-napi-info"
    print(f"\n=== {fname} ===")
    try:
        r = requests.post(url, json=payload, timeout=60)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            if data.get("success"):
                blocks = data.get("blocks", [])
                print(f"Found {len(blocks)} block(s)")
                for i, b in enumerate(blocks, 1):
                    print(f"  [{i}] Téma: {b.get('tema')} | Érintett: {b.get('erintett')} | Határidő: {b.get('hatarido')}")
                    print(f"      Tartalom: {b.get('tartalom')[:200]}...")
            else:
                print("Failed:", data.get("error"))
        else:
            print(r.text[:300])
    except Exception as e:
        print("Error:", e)
