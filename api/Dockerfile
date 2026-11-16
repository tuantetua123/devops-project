# ---- stage 1: build virtualenv (compilers/pip cache never reach runtime) ----
FROM python:3.12-slim AS build
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
# copy requirements first so this layer is cached until dependencies change
COPY requirements.txt .
RUN pip install -r requirements.txt

# ---- stage 2: runtime, non-root user ----
FROM python:3.12-slim AS runtime
ARG GIT_SHA=unknown
ARG VERSION=dev
LABEL org.opencontainers.image.title="attendance-api" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}"
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/opt/venv/bin:$PATH
RUN groupadd --gid 10001 app \
 && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=build /opt/venv /opt/venv
COPY --chown=10001:10001 app/ .
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]