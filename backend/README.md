# Store343 Backend API

Flask backend for processing LIDL documents with Claude AI.

## Endpoints

- `GET /health` - Health check
- `POST /api/process-napi-info` - Process Napi Info documents
- `POST /api/process-nf-visszakuldes` - Process NF visszaküldés documents

## Deployment to Railway

1. Create Railway account: https://railway.app
2. Create new project
3. Connect GitHub repository
4. Select `backend` folder as root
5. Add environment variable: `ANTHROPIC_API_KEY=your_key_here`
6. Deploy!

## Local Development

```bash
cd backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
export ANTHROPIC_API_KEY=your_key_here
python app.py
```

Server runs on http://localhost:5000
