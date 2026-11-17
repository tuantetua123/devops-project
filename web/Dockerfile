# ---- stage 1: minify static HTML (real build step, makes multi-stage meaningful) ----
FROM node:22-alpine AS build
WORKDIR /src
COPY index.html checkin.html ./
RUN npx --yes html-minifier-terser@7.2.0 \
      --collapse-whitespace --remove-comments \
      -o /out-index.html index.html \
 && npx --yes html-minifier-terser@7.2.0 \
      --collapse-whitespace --remove-comments \
      -o /out-checkin.html checkin.html

# ---- stage 2: runtime, nginx already runs as non-root (uid 101) ----
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
ARG GIT_SHA=unknown
ARG VERSION=dev
LABEL org.opencontainers.image.title="attendance-web" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /out-index.html /usr/share/nginx/html/index.html
COPY --from=build /out-checkin.html /usr/share/nginx/html/checkin.html
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1