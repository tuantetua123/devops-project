"""Logging JSON ra stdout + /metrics cho Prometheus + middleware đo request."""
import json
import logging
import sys
import time

from fastapi import FastAPI, Request, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

REQS = Counter("http_requests_total", "Tổng số request", ["service", "method", "path", "status"])
LAT = Histogram("http_request_duration_seconds", "Độ trễ request (giây)", ["service", "method", "path"])


class JsonFormatter(logging.Formatter):
    def __init__(self, service: str):
        super().__init__()
        self.service = service

    def format(self, r: logging.LogRecord) -> str:
        d = {
            "ts": self.formatTime(r, "%Y-%m-%dT%H:%M:%S%z"),
            "level": r.levelname,
            "service": self.service,
            "logger": r.name,
            "msg": r.getMessage(),
        }
        d.update(getattr(r, "fields", {}))
        if r.exc_info:
            d["exc"] = self.formatException(r.exc_info)
        return json.dumps(d, ensure_ascii=False)


def setup(app: FastAPI, service: str, level: str = "INFO") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter(service))
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
    for name in ("uvicorn", "uvicorn.error"):
        lg = logging.getLogger(name)
        lg.handlers = []
        lg.propagate = True
    logging.getLogger("uvicorn.access").disabled = True  # tự log trong middleware
    log = logging.getLogger("http")

    @app.middleware("http")
    async def observe(request: Request, call_next):
        start = time.perf_counter()
        status = 500
        try:
            resp = await call_next(request)
            status = resp.status_code
            return resp
        finally:
            dur = time.perf_counter() - start
            route = request.scope.get("route")
            path = route.path if route else "unmatched"  # tránh bùng nổ cardinality
            if path != "/metrics":
                REQS.labels(service, request.method, path, str(status)).inc()
                LAT.labels(service, request.method, path).observe(dur)
            log.info("request", extra={"fields": {
                "method": request.method, "path": request.url.path,
                "status": status, "duration_ms": round(dur * 1000, 1)}})

    @app.get("/metrics", include_in_schema=False)
    def metrics() -> Response:
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
