# Store343 Backend API
# FastAPI server for OCR processing using Google Cloud Vision API

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64
from typing import List, Optional
import os
import re
from google.cloud import vision
import json

app = FastAPI(title="Store343 OCR API", version="1.0.0")

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Google Cloud Vision client
vision_client = None

def get_vision_client():
    """Initialize Google Cloud Vision client"""
    global vision_client
    if vision_client is None:
        # Check if credentials are provided as JSON string (Railway)
        creds_json = os.getenv('GOOGLE_APPLICATION_CREDENTIALS_JSON')
        if creds_json:
            # Parse JSON string and create client from dict
            import json
            from google.oauth2 import service_account
            creds_dict = json.loads(creds_json)
            credentials = service_account.Credentials.from_service_account_info(creds_dict)
            vision_client = vision.ImageAnnotatorClient(credentials=credentials)
        else:
            # Use default credentials (local development with GOOGLE_APPLICATION_CREDENTIALS file)
            vision_client = vision.ImageAnnotatorClient()
    return vision_client

# MARK: - Models

class ImageBase64Request(BaseModel):
    image_base64: str

class NapiInfoBlock(BaseModel):
    tema: str
    erintett: str
    tartalom: str
    hatarido: Optional[str] = None
    flags: Optional[dict] = None
    termekek: Optional[List[dict]] = None
    emails: Optional[List[str]] = None

class NapiInfoResponse(BaseModel):
    document_date: Optional[str] = None
    page_number: Optional[int] = None
    success: bool
    blocks: Optional[List[NapiInfoBlock]] = None
    raw_text: Optional[str] = None
    error: Optional[str] = None

# MARK: - Endpoints

@app.get("/")
def root():
    return {
        "status": "running",
        "service": "Store343 OCR API",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    try:
        client = get_vision_client()
        return {"status": "healthy", "vision_api": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}

@app.post("/api/process-napi-info", response_model=NapiInfoResponse)
async def process_napi_info(request: ImageBase64Request):
    """Process Napi Info document with Google Cloud Vision API"""
    try:
        # Decode image
        image_data = base64.b64decode(request.image_base64)
        image = vision.Image(content=image_data)
        
        # Get Vision client and perform OCR
        client = get_vision_client()
        response = client.document_text_detection(image=image)
        
        if response.error.message:
            raise HTTPException(status_code=500, detail=response.error.message)
        
        # Extract text
        full_text = response.full_text_annotation.text if response.full_text_annotation else ""
        
        if not full_text:
            return NapiInfoResponse(success=False, blocks=[], raw_text="")
        
        # Parse document
        document_date, page_number = extract_document_metadata(full_text)
        blocks = parse_napi_info_text(full_text)
        
        return NapiInfoResponse(
            success=True,
            blocks=blocks,
            raw_text=full_text,
            document_date=document_date,
            page_number=page_number
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# MARK: - Parser Functions

def extract_document_metadata(text: str) -> tuple:
    """Extract date and page number from header"""
    # Extract date: "Dátum: YYYY.MM.DD."
    date_match = re.search(r'\bDátum:\s*(\d{4}\.\d{2}\.\d{2})\.?', text, re.IGNORECASE)
    document_date = date_match.group(1) if date_match else None
    
    # Extract page number: "Oldal: X"
    page_match = re.search(r'\bOldal:\s*(\d+)', text, re.IGNORECASE)
    page_number = int(page_match.group(1)) if page_match else None
    
    return document_date, page_number

def parse_napi_info_text(text: str) -> List[NapiInfoBlock]:
    """Parse Napi Info text into structured blocks"""
    blocks = []
    lines = text.split('\n')
    
    current_block = None
    skip_patterns = ['info', 'feladat', 'melléklet', 'jelentés', 'napi infó', 'oldal', 'dátum:']
    
    for line in lines:
        line = line.strip()
        if not line or len(line) < 3:
            continue
        
        line_lower = line.lower()
        
        # Detect "Téma:" - start new block
        tema_match = re.search(r'\bTéma:\s*(.+)', line, re.IGNORECASE)
        if tema_match:
            # Save previous block
            if current_block and current_block.get('tema'):
                finalize_block(current_block)
                blocks.append(NapiInfoBlock(**current_block))
            
            # Start new block
            current_block = {
                'tema': tema_match.group(1).strip(),
                'erintett': 'Mindenki',
                'tartalom': '',
                'hatarido': None,
                'flags': {'info': False, 'task': False, 'attachment': False, 'report': False},
                'termekek': [],
                'emails': []
            }
            continue
        
        # Skip header lines
        if not current_block:
            continue
        
        # Check for flags in checkbox lines
        if '☑' in line or '☐' in line:
            if 'info' in line_lower:
                current_block['flags']['info'] = True
            if 'feladat' in line_lower:
                current_block['flags']['task'] = True
            if 'melléklet' in line_lower:
                current_block['flags']['attachment'] = True
            if 'jelentés' in line_lower:
                current_block['flags']['report'] = True
            continue
        
        # Detect "Határidő:"
        hatarido_match = re.search(r'\bHatáridő:\s*([^\n\r]+)', line, re.IGNORECASE)
        if hatarido_match:
            hatarido_raw = hatarido_match.group(1).strip()
            date_match = re.search(r'(\d{4}\.\d{2}\.\d{2})\.?', hatarido_raw)
            current_block['hatarido'] = date_match.group(1) if date_match else hatarido_raw
            continue
        
        # Detect "Érintett:"
        erintett_match = re.search(r'\bÉrintett:\s*([^\n\r]+)', line, re.IGNORECASE)
        if erintett_match:
            erintett_value = erintett_match.group(1).strip()
            if erintett_value and erintett_value.lower() != 'mindenki':
                current_block['erintett'] = erintett_value
            continue
        
        # Skip certain patterns
        if any(pattern in line_lower for pattern in skip_patterns):
            continue
        
        # Content lines
        line = line.replace('☐', '').replace('☑', '').replace('•', '').strip()
        if line:
            if current_block['tartalom']:
                current_block['tartalom'] += ' ' + line
            else:
                current_block['tartalom'] = line
            
            # Extract date from content if not set
            if not current_block['hatarido']:
                dates = re.findall(r'\d{4}\.\d{2}\.\d{2}\.?', line)
                if dates:
                    current_block['hatarido'] = dates[0].rstrip('.')
    
    # Add last block
    if current_block and current_block.get('tema'):
        finalize_block(current_block)
        blocks.append(NapiInfoBlock(**current_block))
    
    return blocks

def finalize_block(block: dict):
    """Extract products and emails, clean flags"""
    tartalom = block.get('tartalom', '')
    
    # Extract products
    products = extract_products(tartalom)
    block['termekek'] = products if products else None
    
    # Extract emails
    emails = extract_emails(tartalom)
    block['emails'] = emails if emails else None
    
    # Clean flags
    flags = block.get('flags', {})
    block['flags'] = flags if any(flags.values()) else None

def extract_products(text: str) -> List[dict]:
    """Extract product list (cikkszám – név)"""
    products = []
    # Pattern: 4-7 digits followed by – and product name
    pattern = r'(\d{4,7})\s*[–-]\s*([A-ZÁÉÍÓÖŐÚÜŰa-záéíóöőúüű\s]+)'
    matches = re.findall(pattern, text)
    
    for match in matches:
        products.append({
            'cikkszam': match[0],
            'nev': match[1].strip()
        })
    
    return products

def extract_emails(text: str) -> List[str]:
    """Extract email addresses"""
    pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    return re.findall(pattern, text)

# MARK: - Server

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
