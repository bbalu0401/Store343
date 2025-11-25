#!/usr/bin/env python3
"""
Test the deployed /api/process-beosztas endpoint on Railway
"""

import requests
import base64
import json

# Test with IMG_6428.jpeg (clearest image)
IMAGE_PATH = "/home/user/Store343/IMG_6428.jpeg"
API_URL = "https://store343-production.up.railway.app/api/process-beosztas"

print("📸 Reading and encoding image...")
with open(IMAGE_PATH, 'rb') as f:
    image_data = base64.b64encode(f.read()).decode('utf-8')

print(f"📊 Image size: {len(image_data)} characters")
print("📤 Sending request to Railway...")

# Prepare request
payload = {
    "image_base64": image_data,
    "image_type": "image/jpeg"
}

try:
    # Send request (120 second timeout)
    response = requests.post(API_URL, json=payload, timeout=120)

    print(f"\n📡 HTTP Status: {response.status_code}")

    # Parse response
    result = response.json()

    if result.get("success"):
        print("\n✅ SUCCESS!")
        print("━" * 80)

        # Week info
        week_info = result.get("week_info", {})
        print(f"\n📅 Week Info:")
        print(f"   Dates: {', '.join(week_info.get('dates', []))}")
        print(f"   Days: {', '.join(week_info.get('days', []))}")

        # Employees
        employees = result.get("employees", [])
        print(f"\n👥 Employees Found: {len(employees)}")
        print()

        for idx, emp in enumerate(employees, 1):
            print(f"   {idx}. {emp.get('name')}")
            print(f"      Weekly Hours: {emp.get('weekly_hours', 'N/A')}")
            print(f"      Shifts: {len(emp.get('shifts', []))} shifts")

            # Show first 2 shifts as example
            for shift in emp.get('shifts', [])[:2]:
                shift_type = shift.get('type', 'unknown')
                if shift_type == 'shift':
                    print(f"         - {shift.get('date')} ({shift.get('day')}): "
                          f"{shift.get('position')} {shift.get('start_time')}-{shift.get('end_time')}")
                elif shift_type == 'rest':
                    print(f"         - {shift.get('date')} ({shift.get('day')}): Pihenőnap")
                elif shift_type == 'holiday':
                    print(f"         - {shift.get('date')} ({shift.get('day')}): Munkaszüneti nap")
                elif shift_type == 'sick':
                    print(f"         - {shift.get('date')} ({shift.get('day')}): Beteg/Szabadság")

            if len(emp.get('shifts', [])) > 2:
                print(f"         ... and {len(emp.get('shifts', [])) - 2} more shifts")
            print()

        # Token usage
        usage = result.get("usage", {})
        print("━" * 80)
        print(f"📊 Token Usage:")
        print(f"   Input: {usage.get('input_tokens', 0)}")
        print(f"   Output: {usage.get('output_tokens', 0)}")

        # Save full result
        with open('/tmp/ocr_result.json', 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

        print(f"\n💾 Full JSON saved to: /tmp/ocr_result.json")

    else:
        print("\n❌ FAILED")
        print(f"Error: {result.get('error')}")
        if 'raw_response' in result:
            print(f"\nRaw Response:\n{result.get('raw_response')}")

except requests.exceptions.Timeout:
    print("\n❌ Request timed out (>120 seconds)")
except requests.exceptions.RequestException as e:
    print(f"\n❌ Request failed: {str(e)}")
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
