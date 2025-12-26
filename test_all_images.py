#!/usr/bin/env python3
"""Test all 3 schedule images"""

import requests
import base64
import json

API_URL = "https://store343-production.up.railway.app/api/process-beosztas"

images = [
    "/home/user/Store343/IMG_6427.jpeg",
    "/home/user/Store343/IMG_6428.jpeg",
    "/home/user/Store343/IMG_6429.jpeg"
]

all_employees = {}

for img_path in images:
    print(f"\n{'='*80}")
    print(f"Testing: {img_path.split('/')[-1]}")
    print(f"{'='*80}")

    with open(img_path, 'rb') as f:
        image_data = base64.b64encode(f.read()).decode('utf-8')

    payload = {
        "image_base64": image_data,
        "image_type": "image/jpeg"
    }

    try:
        response = requests.post(API_URL, json=payload, timeout=120)
        result = response.json()

        if result.get("success"):
            employees = result.get("employees", [])
            print(f"✅ Found {len(employees)} employees")

            for emp in employees:
                name = emp.get('name')
                if name not in all_employees:
                    all_employees[name] = emp
                else:
                    # Merge shifts
                    existing_shifts = all_employees[name].get('shifts', [])
                    new_shifts = emp.get('shifts', [])
                    all_employees[name]['shifts'] = existing_shifts + new_shifts

                print(f"   - {name} ({len(emp.get('shifts', []))} shifts)")

            print(f"📊 Tokens: IN={result['usage']['input_tokens']} OUT={result['usage']['output_tokens']}")
        else:
            print(f"❌ Failed: {result.get('error')}")

    except Exception as e:
        print(f"❌ Error: {str(e)}")

print(f"\n{'='*80}")
print(f"📊 TOTAL SUMMARY")
print(f"{'='*80}")
print(f"Total unique employees: {len(all_employees)}")
print()

for name, emp_data in sorted(all_employees.items()):
    print(f"   {name}: {len(emp_data.get('shifts', []))} shifts")

# Save combined result
with open('/tmp/all_employees.json', 'w', encoding='utf-8') as f:
    json.dump(list(all_employees.values()), f, indent=2, ensure_ascii=False)

print(f"\n💾 All employees saved to: /tmp/all_employees.json")
