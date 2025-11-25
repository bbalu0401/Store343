"""
Test script to check if Claude can OCR the weekly schedule images
"""

import anthropic
import os
import base64

# Initialize Claude client
api_key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
client = anthropic.Anthropic(api_key=api_key)

def test_schedule_image(image_path: str):
    """Test OCR on a schedule image"""
    print(f"\n{'='*80}")
    print(f"Testing: {image_path}")
    print(f"{'='*80}\n")

    # Read and encode image
    with open(image_path, 'rb') as f:
        image_data = base64.b64encode(f.read()).decode('utf-8')

    # Determine media type
    if image_path.endswith('.png'):
        media_type = "image/png"
    elif image_path.endswith('.jpg') or image_path.endswith('.jpeg'):
        media_type = "image/jpeg"
    else:
        media_type = "image/png"

    # Prepare prompt for Claude
    prompt = """Analyze this weekly employee schedule table.

Extract ALL information in structured JSON format:

{
  "week_info": {
    "dates": ["10.20", "10.21", ...],  // all dates from columns
    "days": ["H", "K", ...]  // day abbreviations
  },
  "employees": [
    {
      "name": "Employee name",
      "shifts": [
        {
          "date": "10.20",
          "day": "H",
          "position": "Bolti dolgozó" or "Munkaszüneti nap" or "P" or "B",
          "start_time": "21:00",  // if applicable
          "end_time": "6:00",  // if applicable
          "hours": "8:30",  // if shown
          "location": "Kasszás: 5:00-14:00" // additional details if any
        }
      ],
      "weekly_hours": "42:30"  // if shown in last column
    }
  ]
}

Notes:
- "P" means pihenőnap (rest day)
- "B" means beteg/szabadság (sick/vacation)
- "Munkaszüneti nap" means public holiday
- Extract ALL employees visible in the image
- Be precise with time formats (HH:MM)
- Include all shift details and special notes

Return ONLY valid JSON, no markdown formatting."""

    try:
        # Call Claude API
        message = client.messages.create(
            model="claude-sonnet-4-5-20250929",
            max_tokens=16384,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_data
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        )

        # Extract response
        response_text = message.content[0].text

        print("✅ Claude API Response:")
        print(response_text)
        print(f"\n📊 Token Usage:")
        print(f"   Input: {message.usage.input_tokens}")
        print(f"   Output: {message.usage.output_tokens}")

        return response_text

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    # Test all three schedule images
    images = [
        "/home/user/Store343/IMG_6427.jpeg",
        "/home/user/Store343/IMG_6428.jpeg",
        "/home/user/Store343/IMG_6429.jpeg"
    ]

    results = []
    for img_path in images:
        result = test_schedule_image(img_path)
        if result:
            results.append(result)

    print(f"\n{'='*80}")
    print(f"✅ Successfully processed {len(results)}/{len(images)} images")
    print(f"{'='*80}")
