"""
Store343 Backend API
Flask server for processing documents with Claude AI
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import anthropic
import os
import base64
import json
from typing import List, Dict, Any

app = Flask(__name__)
CORS(app)

# Claude API client
client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "Store343 API"}), 200

@app.route('/api/process-napi-info', methods=['POST'])
def process_napi_info():
    """
    Process Napi Info document (image or PDF) with Claude AI

    Request body:
    {
        "image_base64": "base64_encoded_image_data",
        "image_type": "image/jpeg" or "application/pdf"
    }

    Response:
    {
        "success": true,
        "blocks": [
            {
                "tema": "Topic",
                "erintett": "Affected area",
                "tartalom": "Content",
                "hatarido": "Deadline",
                "emoji": "📋",
                "checkboxes": ["Task 1", "Task 2"],
                "images": []
            }
        ],
        "usage": {
            "input_tokens": 1234,
            "output_tokens": 567
        }
    }
    """
    try:
        data = request.get_json()

        if not data or 'image_base64' not in data:
            return jsonify({
                "success": False,
                "error": "Missing image_base64 in request"
            }), 400

        image_base64 = data['image_base64']
        image_type = data.get('image_type', 'image/jpeg')

        # Prepare messages for Claude
        prompt = """Analyze this Hungarian LIDL daily info document. Extract structured information.

For each distinct topic/section, create a block with:
1. **tema**: The main topic (e.g., "Árufeltöltés", "Takarítás")
2. **erintett**: Affected area/department
3. **tartalom**: Detailed content/description
4. **hatarido**: Deadline if mentioned (format: "YYYY-MM-DD HH:MM" or null)
5. **emoji**: One relevant emoji that represents the topic
6. **checkboxes**: List of actionable tasks/checkboxes
7. **images**: Always empty array []

Return ONLY valid JSON array of blocks, nothing else:
[{"tema": "...", "erintett": "...", "tartalom": "...", "hatarido": "...", "emoji": "...", "checkboxes": [...], "images": []}]

Important:
- Use Hungarian text exactly as written
- Extract ALL sections/topics
- If no deadline, use null
- Each block is a separate topic"""

        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=4096,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": image_type,
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ],
                }
            ],
        )

        # Extract JSON from response
        response_text = message.content[0].text.strip()

        # Remove markdown code blocks if present
        if response_text.startswith('```'):
            response_text = response_text.split('```')[1]
            if response_text.startswith('json'):
                response_text = response_text[4:]
            response_text = response_text.strip()

        blocks = json.loads(response_text)

        return jsonify({
            "success": True,
            "blocks": blocks,
            "usage": {
                "input_tokens": message.usage.input_tokens,
                "output_tokens": message.usage.output_tokens
            }
        }), 200

    except json.JSONDecodeError as e:
        return jsonify({
            "success": False,
            "error": f"Failed to parse AI response as JSON: {str(e)}"
        }), 500
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/process-nf-visszakuldes', methods=['POST'])
def process_nf_visszakuldes():
    """
    Process NF visszaküldés document (Excel/image/PDF) with Claude AI

    Request body:
    {
        "document_base64": "base64_encoded_document_data",
        "document_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or "image/jpeg" or "application/pdf"
    }

    Response:
    {
        "success": true,
        "termekek": [
            {
                "cikkszam": "123456",
                "cikk_megnevezes": "Product name",
                "bizonylat_szam": "33606",
                "elvi_keszlet": 5
            }
        ],
        "usage": {
            "input_tokens": 1234,
            "output_tokens": 567
        }
    }
    """
    try:
        print("🔵 [NF] Received request to /api/process-nf-visszakuldes")
        data = request.get_json()
        print(f"🔵 [NF] Request data keys: {data.keys() if data else 'None'}")

        if not data or 'document_base64' not in data:
            print("❌ [NF] Missing document_base64 in request")
            return jsonify({
                "success": False,
                "error": "Missing document_base64 in request"
            }), 400

        document_base64 = data['document_base64']
        document_type = data.get('document_type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        print(f"🔵 [NF] Document type: {document_type}")
        print(f"🔵 [NF] Document base64 length: {len(document_base64)} chars")

        # Prepare messages for Claude
        prompt = """Analyze this Hungarian LIDL NF visszaküldés (return) document. Extract all product information.

The document contains products with these columns:
- Cikkszám (product code/SKU)
- Cikk megnevezés (product name)
- Bizonylat (receipt/document number)
- Mennyiség (quantity - this is "elvi készlet" / theoretical stock)

Some rows are category headers (like "Parkside", "PLU") - IGNORE these rows (they don't have a cikkszám).

Return ONLY valid JSON array of products, nothing else:
[{"cikkszam": "...", "cikk_megnevezes": "...", "bizonylat_szam": "...", "elvi_keszlet": 0}]

Important:
- Extract ALL products from ALL bizonylatok
- Skip category header rows
- If mennyiség is empty, use 0
- Use exact Hungarian text
- cikkszam should be a string (may have leading zeros)
- bizonylat_szam should be a string
- elvi_keszlet should be an integer (0 if empty/null)"""

        # Determine content type
        if document_type.startswith('image/'):
            print("🔵 [NF] Using 'image' content type for Claude API")
            content_item = {
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": document_type,
                    "data": document_base64,
                },
            }
        else:  # PDF or other documents
            print("🔵 [NF] Using 'document' content type for Claude API")
            content_item = {
                "type": "document",
                "source": {
                    "type": "base64",
                    "media_type": document_type,
                    "data": document_base64,
                },
            }

        print("🔵 [NF] Calling Claude API...")
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=8192,
            messages=[
                {
                    "role": "user",
                    "content": [
                        content_item,
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ],
                }
            ],
        )

        print("✅ [NF] Claude API call successful!")
        print(f"🔵 [NF] Token usage - Input: {message.usage.input_tokens}, Output: {message.usage.output_tokens}")

        # Extract JSON from response
        response_text = message.content[0].text.strip()
        print(f"🔵 [NF] Raw response length: {len(response_text)} chars")
        print(f"🔵 [NF] Response preview: {response_text[:200]}...")

        # Remove markdown code blocks if present
        if response_text.startswith('```'):
            print("🔵 [NF] Removing markdown code blocks from response")
            response_text = response_text.split('```')[1]
            if response_text.startswith('json'):
                response_text = response_text[4:]
            response_text = response_text.strip()

        print("🔵 [NF] Parsing JSON response...")
        termekek = json.loads(response_text)
        print(f"✅ [NF] Successfully parsed {len(termekek)} termekek")

        return jsonify({
            "success": True,
            "termekek": termekek,
            "usage": {
                "input_tokens": message.usage.input_tokens,
                "output_tokens": message.usage.output_tokens
            }
        }), 200

    except json.JSONDecodeError as e:
        print(f"❌ [NF] JSON decode error: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Failed to parse AI response as JSON: {str(e)}"
        }), 500
    except Exception as e:
        print(f"❌ [NF] Exception: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "error": f"{type(e).__name__}: {str(e)}"
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
