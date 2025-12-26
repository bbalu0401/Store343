# Store343 Backend - OCR API

FastAPI backend Google Cloud Vision API-val magyar napi infó dokumentumok OCR feldolgozásához.

## 🚀 Funkciók

- **Napi Info OCR**: Fotókból strukturált adat kinyerés (Téma, Érintett, Tartalom, Határidő)
- **Google Cloud Vision API**: Ingyenes (1000 oldal/hó), pontos magyar OCR
- **FastAPI**: Gyors, modern Python API
- **Railway Deploy**: Egyszerű cloud hosting

## 📦 Setup

### 1. Google Cloud Vision API beállítás

1. Menj a [Google Cloud Console](https://console.cloud.google.com/)
2. Hozz létre új projektet: "Store343"
3. Engedélyezd a **Cloud Vision API**-t
4. Hozz létre Service Account-ot:
   - IAM & Admin → Service Accounts → Create
   - Role: "Cloud Vision API User"
   - Create Key → JSON
5. Töltsd le a JSON kulcsfájlt

### 2. Lokális tesztelés

```bash
# Telepítsd a függőségeket
pip install -r requirements.txt

# Állítsd be a Google credentials-t
export GOOGLE_APPLICATION_CREDENTIALS="path/to/your-service-account.json"

# Indítsd a szervert
python main.py
```

Szerver: `http://localhost:8000`

### 3. Railway Deployment

1. Jelentkezz be Railway-re: https://railway.app
2. New Project → Deploy from GitHub
3. Válaszd ki a Store343 repo-t
4. Environment Variables:
   - Add hozzá: `GOOGLE_APPLICATION_CREDENTIALS` (JSON tartalmát egyben)
   - VAGY: `GOOGLE_CREDENTIALS_JSON` (base64 encoded)
5. Deploy!

**Railway környezeti változó beállítás:**
```bash
# A JSON fájl tartalmát másold be GOOGLE_APPLICATION_CREDENTIALS-be
# vagy használd ezt:
cat your-service-account.json | base64
# és ezt rakd be GOOGLE_CREDENTIALS_JSON-be
```

## 🔌 API Endpoints

### Health Check
```bash
GET /health
```

### Napi Info OCR
```bash
POST /api/process-napi-info
Content-Type: application/json

{
  "image_base64": "iVBORw0KGgoAAAANS..."
}
```

**Response:**
```json
{
  "success": true,
  "document_date": "2025.12.15",
  "page_number": 1,
  "blocks": [
    {
      "tema": "Belépőnap változások az ünnepek miatt",
      "erintett": "Mindenki",
      "tartalom": "A 2025.12.29-es belépőnapra...",
      "hatarido": "2025.12.17",
      "flags": {
        "info": true,
        "task": false,
        "attachment": false,
        "report": false
      },
      "termekek": null,
      "emails": null
    },
    {
      "tema": "Készletszámolás",
      "erintett": "Mindenki",
      "tartalom": "Kérjük az alábbi termékek készletét megszámolni...",
      "hatarido": null,
      "flags": {
        "info": true,
        "task": true
      },
      "termekek": [
        {
          "cikkszam": "478943",
          "megnevezes": "Cleanmax Ingyvasaló 1800W"
        },
        {
          "cikkszam": "419337",
          "megnevezes": "Monsieur Cuisine Smart SKMS 1200 A1"
        }
      ],
      "emails": null
    },
    {
      "tema": "Új Medicare Klinika nyílt Budapesten",
      "erintett": "Mindenki",
      "tartalom": "Örömmel tájékoztatunk...",
      "hatarido": null,
      "flags": {"info": true},
      "termekek": null,
      "emails": ["medicare@lidl.hu"]
    }
  ],
  "raw_text": "teljes OCR szöveg..."
}
```

### Strukturált adatok

A backend automatikusan kinyeri:
- **Téma:** Regex `\bTéma:\s*(.+)`
- **Érintett:** Regex `\bÉrintett:\s*([^\n\r]+)` (default: "Mindenki")
- **Határidő:** Regex `\bHatáridő:\s*(\d{4}\.\d{2}\.\d{2})` vagy implicit dátum a szövegben
- **Flags:** Info/Feladat/Jelentés/Melléklet checkbox-ok
- **Termékek:** Regex `(\d{4,7})\s*[–—-]\s*(.+)` → cikkszám – név
- **Email-ek:** Regex email pattern
- **Dokumentum dátum:** Fejléc "Dátum: YYYY.MM.DD."
- **Oldalszám:** Footer "N. oldal"

## 🧪 Tesztelés

```bash
# Lokális teszt curl-lel
curl -X POST http://localhost:8000/api/process-napi-info \
  -H "Content-Type: application/json" \
  -d '{"image_base64": "..."}'
```

## 💰 Költségek

- **Google Cloud Vision**: INGYENES (1000 oldal/hó alatt)
- **Railway**: INGYENES tier (500h/hó)

Átlagos használat: ~70 oldal/hó → 100% ingyenes! ✅

## 📱 iOS App integráció

Az app a `ClaudeAPIService.swift`-ben hívja ezt az API-t. Frissítsd a `baseURL`-t:

```swift
private let baseURL = "https://your-app.up.railway.app"
```

## 🔧 Környezeti változók

- `PORT`: 8000 (alapértelmezett, Railway felülírja)
- `GOOGLE_APPLICATION_CREDENTIALS`: Google Cloud JSON credentials path
- `GOOGLE_CREDENTIALS_JSON`: Vagy base64 encoded JSON

## 📝 Fejlesztés

```bash
# Hot reload fejlesztéshez
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Docs: http://localhost:8000/docs (Swagger UI)
