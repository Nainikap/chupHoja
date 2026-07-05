import requests
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
 
# ── App ──────────────────────────────────────────────────────────────────────
 
app = FastAPI(title="DrishtiAI API", version="1.0.0")
 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
 
# ── Config ───────────────────────────────────────────────────────────────────
 
MODEL_PATH  = "dr_model_scripted.pt"   # TorchScript model exported from Colab
IMG_SIZE    = 512
# DEVICE      = torch.device("cuda" if torch.cuda.is_available() else "cpu")
COLAB_INFERENCE_URL = "abhi daalni hai"
GRADE_LABELS = {
    0: "No DR",
    1: "Mild DR",
    2: "Moderate DR",
    3: "Severe DR",
    4: "Proliferative DR",
}
 
REFERRALS = {
    0: "No referral needed. Rescreen in 1 year.",
    1: "Mild DR detected. Refer to ophthalmologist within 6 months.",
    2: "Moderate DR detected. Refer within 1 month.",
    3: "Severe DR detected. Urgent referral within 1 week.",
    4: "Proliferative DR detected. IMMEDIATE referral today.",
}
 
SEVERITY_COLOR = {
    0: "#2D9E6B",   # green
    1: "#F0A500",   # amber
    2: "#E67E22",   # orange
    3: "#E74C3C",   # red
    4: "#8E44AD",   # purple
}


class PredictionResponse(BaseModel):
    grade:          int
    grade_label:    str
    confidence:     float
    probabilities:  list[float]
    referral:       str
    severity_color: str
    low_confidence: bool
    gradcam_b64:    str
    quality_ok:     bool
    quality_msg:    str

#endpoints

@app.get('/health')
def health():
    """Check that both this server and the Colab inference server are reachable."""
    try:
        resp = requests.get(
            f"{COLAB_INFERENCE_URL}/health",
            timeout=5,
            headers = {"ngrok-skip-browser-warning": "true"}
        )
        colab_ok = resp.status_code==200

    except Exception as e:
        colab_ok=False

    return{
        "fastapi_server": "ok",
        "colab_inference": "ok" if colab_ok else "unreachable — update COLAB_INFERENCE_URL",
    }

@app.post("/predict", response_model=PredictionResponse)
async def predict(file: UploadFile=File(...)):
    contents = await file.read()
    
    try:
        colab_response = requests.post(
            f"{COLAB_INFERENCE_URL}/predict",
            files={"file": (file.filename, contents, file.content_type)},
            timeout=30,
            headers = {"ngrok-skip-browser-warning": "true"}
        )
        colab_response.raise_for_status()
    except requests.Timeout:
        raise HTTPException(status_code=504, detail="Colab inference server timed out")
    except requests.ConnectionError:
        raise HTTPException(
            status_code=503,
            detail="Cannot reach Colab — check ngrok is running and COLAB_INFERENCE_URL is updated",
        )
    except requests.HTTPError as e:
        raise HTTPException(status_code=502, detail=f'Colab returned error: {e}')
    
    return colab_response.json()