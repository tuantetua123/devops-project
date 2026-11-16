"""Token điểm danh có hạn: <session_id>.<exp>.<hmac>. Không cần lưu DB."""
import hashlib
import hmac
import time


def _sig(payload: str, secret: str) -> str:
    return hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()[:32]


def make(session_id: int, secret: str, ttl: int, now: float | None = None) -> str:
    exp = int((now if now is not None else time.time()) + ttl)
    payload = f"{session_id}.{exp}"
    return f"{payload}.{_sig(payload, secret)}"


def verify(token: str, secret: str, now: float | None = None) -> int | None:
    parts = token.split(".")
    if len(parts) != 3:
        return None
    sid, exp, sig = parts
    if not hmac.compare_digest(sig, _sig(f"{sid}.{exp}", secret)):
        return None
    try:
        if int(exp) < (now if now is not None else time.time()):
            return None
        return int(sid)
    except ValueError:
        return None
