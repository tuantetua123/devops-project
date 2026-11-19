
# ---- Stage 1: Build and minify HTML ----
FROM node:22-alpine AS build

WORKDIR /src

COPY index.html checkin.html ./

RUN npx --yes html-minifier-terser@7.2.0 \
      --collapse-whitespace --remove-comments \
      -o /out-index.html index.html \
 && npx --yes html-minifier-terser@7.2.0 \
      --collapse-whitespace --remove-comments \
      -o /out-checkin.html checkin.html


# ---- Stage 2: Nginx runtime (non-root) ----
FROM nginxinc/nginx-unprivileged:stable-alpine3.24 AS runtime

# Temporarily use root to install security patches
USER root

# Update Brotli to address CVE-2026-111497
RUN apk upgrade --no-cache brotli-libs \
    && apk info -v brotli-libs

# Restore non-root execution
USER 101

ARG GIT_SHA=unknown
ARG VERSION=dev

LABEL org.opencontainers.image.title="attendance-web" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}"

# Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy optimized HTML files
COPY --from=build /out-index.html /usr/share/nginx/html/index.html
COPY --from=build /out-checkin.html /usr/share/nginx/html/checkin.html

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1
