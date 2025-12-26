# 🚀 Store343 Backend Setup Guide

## Gyors útmutató a Google Cloud Vision API + Railway deployment beállításához

### 1️⃣ Google Cloud Vision API Setup (5 perc)

1. **Menj a Google Cloud Console-ra:**
   https://console.cloud.google.com/

2. **Hozz létre projektet:**
   - Klikk "Select a project" → "New Project"
   - Név: `Store343`
   - Create

3. **Engedélyezd a Vision API-t:**
   - Search bar: "Cloud Vision API"
   - Enable API
   - ✅ INGYENES 1000 oldal/hó alatt!

4. **Service Account létrehozása:**
   - IAM & Admin → Service Accounts
   - Create Service Account
   - Name: `store343-ocr`
   - Role: `Cloud Vision API User`
   - Create Key → JSON
   - ⬇️ Töltsd le a JSON fájlt!

### 2️⃣ Railway Deployment (5 perc)

1. **Jelentkezz be Railway-re:**
   https://railway.app
   - GitHub login

2. **New Project:**
   - Deploy from GitHub repo
   - Válaszd: `Store343` repo
   - Root directory: `/backend`

3. **Environment Variables:**
   - Settings → Variables
   - Add Variable:
     ```
     Name: GOOGLE_APPLICATION_CREDENTIALS_JSON
     Value: (másold be a JSON fájl TELJES tartalmát)
     ```

4. **Deploy:**
   - Automatic deploy indul
   - Várj 2-3 percet
   - Kész! URL: `https://store343-production.up.railway.app`

### 3️⃣ iOS App Konfiguráció (1 perc)

1. **Nyisd meg:**
   `Store343/Helpers/ClaudeAPIService.swift`

2. **Frissítsd a baseURL-t:**
   ```swift
   private let baseURL = "https://store343-production.up.railway.app"
   ```
   (Cseréld ki a Railway által generált URL-re!)

3. **Build & Run** 🎉

### 🧪 Tesztelés

**Lokálisan tesztelés előtt deployment:**
```bash
cd backend
pip install -r requirements.txt
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
python main.py
```

**Health check:**
```bash
curl https://your-app.up.railway.app/health
```

Expected response:
```json
{"status": "healthy", "vision_api": "connected"}
```

### ✅ Checklist

- [ ] Google Cloud projekt létrehozva
- [ ] Vision API engedélyezve
- [ ] Service Account JSON letöltve
- [ ] Railway projekt létrehozva
- [ ] Environment variable beállítva
- [ ] iOS app baseURL frissítve
- [ ] App tesztelve fotó feltöltéssel

### 💰 Költségek

- **Google Vision:** INGYENES (1000 oldal/hó)
- **Railway:** INGYENES ($5 credit/hó starter plan)
- **Átlagos használat:** ~70 oldal/hó → 100% ingyenes! ✅

### 🐛 Troubleshooting

**"Invalid credentials" hiba:**
- Ellenőrizd hogy a teljes JSON került be az environment variable-be
- Próbáld újra deploy-olni

**"Connection refused":**
- Várj 1-2 percet a deployment után
- Ellenőrizd a Railway logs-ot

**"No text found":**
- Jobb minőségű fotó kell
- Próbálj jobb fénnyen fotózni

### 📞 Következő lépések

Ha minden működik:
1. Tesztelj több fotóval
2. Ellenőrizd az OCR pontosságot
3. Ha kell, finomítsd a parsing logikát (`backend/main.py`)
