#!/bin/bash

# Test the deployed OCR endpoint on Railway

echo "📸 Encoding image to base64..."
IMAGE_BASE64=$(base64 -w 0 /home/user/Store343/IMG_6428.jpeg)

echo "📤 Sending request to Railway..."
echo ""

curl -X POST https://store343-production.up.railway.app/api/process-beosztas \
  -H "Content-Type: application/json" \
  -d "{\"image_base64\": \"$IMAGE_BASE64\", \"image_type\": \"image/jpeg\"}" \
  -w "\n\n📊 HTTP Status: %{http_code}\n" \
  --max-time 120 \
  -s | jq -r '
    if .success then
      "✅ SUCCESS!\n" +
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" +
      "📅 Week Info:\n" +
      "   Dates: \(.week_info.dates | join(", "))\n" +
      "   Days: \(.week_info.days | join(", "))\n\n" +
      "👥 Employees Found: \(.employees | length)\n\n" +
      (.employees | to_entries | map(
        "   \(.key + 1). \(.value.name)\n" +
        "      Weekly Hours: \(.value.weekly_hours // "N/A")\n" +
        "      Shifts: \(.value.shifts | length) shifts\n"
      ) | join("\n")) +
      "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
      "📊 Token Usage:\n" +
      "   Input: \(.usage.input_tokens)\n" +
      "   Output: \(.usage.output_tokens)\n"
    else
      "❌ FAILED\n" +
      "Error: \(.error)\n" +
      (if .raw_response then "Raw Response:\n\(.raw_response)\n" else "" end)
    end
  '

echo ""
echo "🔗 Full JSON response saved to: /tmp/ocr_test_result.json"
