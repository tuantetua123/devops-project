import os

import httpx
import psycopg
from fastapi import FastAPI, Header, HTTPException, Response
from psycopg.rows import dict_row
from pydantic import BaseModel, Field

import obs

DATABASE_URL = os.environ["DATABASE_URL"]
ADMIN_API_KEY = os.environ["ADMIN_API_KEY"]
QR_SERVICE_URL = os.getenv("QR_SERVICE_URL", "http://qr:8000")

app = FastAPI(title="attendance-api")
obs.setup(app, "api", os.getenv("LOG_LEVEL", "INFO"))


def db():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row, autocommit=True, connect_timeout=3)


def require_admin(key: str | None):
    if key != ADMIN_API_KEY:
        raise HTTPException(status_code=401, detail="missing or wrong X-Admin-Key")


class ClassIn(BaseModel):
    code: str = Field(min_length=1, max_length=20)
    name: str = Field(min_length=1, max_length=100)


class SessionIn(BaseModel):
    class_id: int


class CheckinIn(BaseModel):
    token: str
    student_id: str = Field(min_length=1, max_length=20)
    student_name: str = Field(min_length=1, max_length=100)


@app.get("/health")
def health():
    try:
        with db() as c:
            c.execute("SELECT 1")
    except psycopg.Error:
        raise HTTPException(status_code=503, detail="database unavailable")
    return {"status": "ok"}


@app.post("/api/classes", status_code=201)
def create_class(body: ClassIn, x_admin_key: str | None = Header(default=None)):
    require_admin(x_admin_key)
    with db() as c:
        try:
            return c.execute("INSERT INTO classes(code,name) VALUES(%s,%s) RETURNING *",
                             (body.code, body.name)).fetchone()
        except psycopg.errors.UniqueViolation:
            raise HTTPException(status_code=409, detail="class code already exists")


@app.get("/api/classes")
def list_classes(x_admin_key: str | None = Header(default=None)):
    require_admin(x_admin_key)
    with db() as c:
        return c.execute("SELECT * FROM classes ORDER BY id").fetchall()


@app.post("/api/sessions", status_code=201)
def create_session(body: SessionIn, x_admin_key: str | None = Header(default=None)):
    require_admin(x_admin_key)
    with db() as c:
        try:
            return c.execute("INSERT INTO sessions(class_id) VALUES(%s) RETURNING *",
                             (body.class_id,)).fetchone()
        except psycopg.errors.ForeignKeyViolation:
            raise HTTPException(status_code=404, detail="class not found")


@app.get("/api/sessions/{session_id}/qr")
def session_qr(session_id: int, x_admin_key: str | None = Header(default=None)):
    require_admin(x_admin_key)
    with db() as c:
        if not c.execute("SELECT 1 FROM sessions WHERE id=%s", (session_id,)).fetchone():
            raise HTTPException(status_code=404, detail="session not found")
    try:
        r = httpx.get(f"{QR_SERVICE_URL}/qr/{session_id}", timeout=3)
        r.raise_for_status()
    except httpx.HTTPError:
        raise HTTPException(status_code=503, detail="qr service unavailable")
    return Response(r.content, media_type="image/png", headers={"Cache-Control": "no-store"})


@app.post("/api/checkin")
def checkin(body: CheckinIn):
    try:
        r = httpx.post(f"{QR_SERVICE_URL}/verify", json={"token": body.token}, timeout=3)
    except httpx.HTTPError:
        raise HTTPException(status_code=503, detail="qr service unavailable")
    if r.status_code != 200:
        raise HTTPException(status_code=400, detail="invalid or expired token")
    sid = r.json()["session_id"]
    with db() as c:
        try:
            row = c.execute(
                "INSERT INTO attendance(session_id,student_id,student_name) VALUES(%s,%s,%s) "
                "ON CONFLICT DO NOTHING RETURNING id",
                (sid, body.student_id, body.student_name)).fetchone()
        except psycopg.errors.ForeignKeyViolation:
            raise HTTPException(status_code=404, detail="session not found")
    return {"status": "ok" if row else "already_checked_in", "session_id": sid}


@app.get("/api/sessions/{session_id}/attendance")
def attendance(session_id: int, x_admin_key: str | None = Header(default=None)):
    require_admin(x_admin_key)
    with db() as c:
        return c.execute("SELECT student_id,student_name,checked_in_at FROM attendance "
                         "WHERE session_id=%s ORDER BY checked_in_at", (session_id,)).fetchall()
