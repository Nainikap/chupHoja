# DrishtiAI — Diabetic Retinopathy Screener

A lightweight, AI-powered diabetic retinopathy screening tool designed for opticians and primary care settings in India. Captures fundus images via a ₹3,000 clip-on lens, grades DR severity (0–4) using EfficientNet-B4, and returns a referral recommendation with a Grad-CAM heatmap — all in under 3 seconds.

---

## The Problem

India has 77M+ diabetics, most of whom will develop diabetic retinopathy. Ophthalmologists are concentrated in metros, while 1.2L+ opticians see these patients daily but have no diagnostic tools. A clinical-grade fundus camera costs ₹3L+, making AI-assisted screening inaccessible at scale.

DrishtiAI bridges this gap with a smartphone-based screener that costs a fraction of existing solutions.

---

## Architecture

```
Flutter App (Android/iOS)
        ↓  POST /predict (image)
FastAPI Backend  ←── main.py (passthrough server)
        ↓  forwards image via ngrok
Colab Inference Server
        ↓  preprocess → EfficientNet-B4 → Grad-CAM
        ↑  grade, confidence, heatmap, referral
FastAPI Backend
        ↑  PredictionResponse JSON
Flutter App
        ↑  Result screen with heatmap + referral
```

---

## Repository Structure

```
drishti-backend/
├── main.py               # FastAPI passthrough server
├── requirements.txt      # Backend dependencies
├── .env                  # Ngrok URL (gitignored)
├── .gitignore
└── README.md

drishti-flutter/
├── lib/
│   └── screens/
│       ├── home_screen.dart      # Landing page
│       ├── camera_screen.dart    # Camera capture + alignment guide
│       └── result_screen.dart    # Grade, heatmap, referral
│   └── services/
│       └── api_service.dart      # HTTP client for /predict
└── pubspec.yaml

colab/
└── DR_Screener.ipynb     # Training + inference server (runs on Colab T4)
```

---

## ML Model

| Property        | Detail                                                      |
| --------------- | ----------------------------------------------------------- |
| Architecture    | EfficientNet-B4 (timm)                                      |
| Dataset         | APTOS 2019 (~13,000 fundus images)                          |
| Fine-tuned on   | IDRiD (Indian-specific fundus images)                       |
| Training        | Two-phase: head-only → full fine-tune                       |
| Class imbalance | Balanced class weights + label smoothing                    |
| Augmentation    | Random rotation 360°, flips, colour jitter, grid distortion |
| Explainability  | Grad-CAM on last EfficientNet block                         |
| Target metric   | Quadratic Weighted Kappa ≥ 0.85                             |
| Inference       | Google Colab T4 GPU via ngrok tunnel                        |

### DR Grading Scale

| Grade | Label            | Referral                        |
| ----- | ---------------- | ------------------------------- |
| 0     | No DR            | Rescreen in 1 year              |
| 1     | Mild DR          | Ophthalmologist within 6 months |
| 2     | Moderate DR      | Ophthalmologist within 1 month  |
| 3     | Severe DR        | Urgent referral within 1 week   |
| 4     | Proliferative DR | Immediate referral today        |

---

## Setup

### 1. Colab — Train & Run Inference Server

1. Open `DR_Screener.ipynb` in Google Colab
2. Set runtime to **T4 GPU** (Runtime → Change runtime type)
3. Run all cells top to bottom — training takes ~2–3 hours
4. At the end, paste your ngrok authtoken (free at [dashboard.ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken))
5. Run the inference server cell — copy the printed public URL

### 2. FastAPI Backend

```bash
# Clone and enter project
git clone https://github.com/your-username/drishti-backend.git
cd drishti-backend

# Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set your Colab ngrok URL
echo "COLAB_INFERENCE_URL=https://your-ngrok-url.ngrok-free.app" > .env

# Start server
uvicorn main:app --host 0.0.0.0 --port 8000
```

Verify both servers are reachable:

```
GET http://localhost:8000/health
```

Expected response:

```json
{
  "fastapi_server": "ok",
  "colab_inference": "ok"
}
```

### 3. Flutter App

```bash
cd drishti-flutter

# Install dependencies
flutter pub get

# For Android emulator — backend URL is already set to 10.0.2.2
# For physical device — update _baseUrl in lib/services/api_service.dart:
#   'http://<your-laptop-ip>:8000'

flutter run
```

Add to `pubspec.yaml` if not already present:

```yaml
dependencies:
  camera: ^0.10.5
  image_picker: ^1.0.7
  http: ^1.2.0
```

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## API Reference

### `GET /health`

Returns status of both the FastAPI server and Colab inference server.

### `POST /predict`

Accepts a multipart image upload, returns a prediction.

**Request:**

```
Content-Type: multipart/form-data
Body: file=<fundus image (jpg/png)>
```

**Response:**

```json
{
  "grade": 2,
  "grade_label": "Moderate DR",
  "confidence": 87.4,
  "probabilities": [2.1, 4.3, 87.4, 5.1, 1.1],
  "referral": "Moderate DR detected. Refer within 1 month.",
  "severity_color": "#E67E22",
  "low_confidence": false,
  "gradcam_b64": "<base64 encoded JPEG>",
  "quality_ok": true,
  "quality_msg": "OK"
}
```

If image quality is insufficient, `quality_ok` is `false` and `quality_msg` describes the issue (too dark, blurry, overexposed). The Flutter app surfaces this as a retake prompt.

---

## Hardware Requirements

| Component           | Spec                               |
| ------------------- | ---------------------------------- |
| Smartphone / tablet | Android 8.0+ or iOS 14+            |
| Clip-on fundus lens | ~₹3,000 (any 20D equivalent)       |
| Lighting            | Dim room, no direct flash          |
| Internet            | Required (inference runs on Colab) |

---

## Limitations

- Inference requires an active Colab session with ngrok running — not suitable for fully offline use
- Ngrok free tier URL changes every session — update `.env` on each restart
- Model is trained on APTOS 2019; performance on very low-quality or non-standard fundus images may degrade
- This is a **screening aid only** — not a substitute for clinical diagnosis by a qualified ophthalmologist

---

## Roadmap

- [ ] Export model to ONNX and run inference on-device (no Colab dependency)
- [ ] PDF report generation for patient records
- [ ] IDRiD fine-tuning for better Indian fundus image accuracy
- [ ] Offline-first mode with local ONNX inference on device
- [ ] Patient history and longitudinal tracking

---

## Disclaimer

DrishtiAI is a screening aid only. It does not constitute a clinical diagnosis. All results must be reviewed by a qualified ophthalmologist before any clinical decision is made. Patient consent must be obtained before capturing retinal images.

---

## License

MIT
