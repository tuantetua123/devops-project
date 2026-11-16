import io
import os

import segno
from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel

import obs
import tokens

SECRET = os.environ["QR_SECRET"]
TTL = int(os.getenv("QR_TTL_SECONDS", "45"))
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://localhost:8080").rstrip("/")

app = FastAPI(title="qr-service")
obs.setup(app, "qr", os.getenv("LOG_LEVEL", "INFO"))


class VerifyIn(BaseModel):
    token: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/qr/{session_id}")
def qr_png(session_id: int):
    url = f"{PUBLIC_BASE_URL}/checkin.html?token={tokens.make(session_id, SECRET, TTL)}"
    buf = io.BytesIO()
    segno.make(url, error="m").save(buf, kind="png", scale=8, border=2)
    return Response(buf.getvalue(), media_type="image/png", headers={"Cache-Control": "no-store"})


@app.post("/verify")
def verify(body: VerifyIn):
    sid = tokens.verify(body.token, SECRET)
    if sid is None:
        raise HTTPException(status_code=400, detail="invalid or expired token")
    return {"session_id": sid}
