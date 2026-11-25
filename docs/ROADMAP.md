# Bảng Theo Dõi Tiến Độ 12 Bài Đồ Án DevOps — Nhóm 7

- [x] **B1:** Quy trình làm việc nhóm, phân vai, kiến trúc hệ thống
- [x] **B2:** Repo GitHub, Conventional Commits, tag semver (`v0.1.0`, `v0.2.0`), GitHub Actions CI
- [x] **B3:** Script backup/restore Postgres (`scripts/`), `systemd timer`, `logrotate`, bảo mật Linux
- [x] **B4:** Dockerfile multi-stage, non-root, `HEALTHCHECK`, `.dockerignore` (`api`, `qr`, `web`)
- [x] **B5:** `compose.yml` (hardening, healthcheck, migrate, seed), `compose.test.yml`, `compose.monitoring.yml`
- [x] **B6:** `Jenkinsfile` declarative: Gitleaks -> Lint -> Unit test -> Smoke test -> Trivy -> Push GHCR -> Deploy staging -> Approve -> Deploy production -> Telegram
- [x] **B7:** Ansible chia 6 roles (`common`, `docker`, `jenkins`, `k3s_server`, `k3s_agent`, `node_exporter`) + Ansible Vault
- [x] **B8:** Terraform dựng 3 VM + mạng + module `local-cluster` (`infra/terraform`)
- [x] **B9:** Kubernetes (`Deployment`, `Service`, `Ingress`, `ConfigMap`, `Secret`, `HPA`), tách namespace `staging`/`production`, Kustomize + PDB
- [x] **B9+:** Thử thách riêng Đề tài 02: Migration CSDL (`migrate-job.yaml`) & Seed dữ liệu mẫu (`seed-job.yaml`) bằng K8s Job trong pipeline
- [x] **B10:** Prometheus + Grafana + Alertmanager (Telegram) + Loki + Promtail + Load test k6
- [x] **B11:** Gitleaks, Trivy chặn lỗi `CRITICAL`, HTTPS Ingress (`cert-manager`), RBAC tối thiểu quyền (`rbac.yaml`)
- [x] **B12 & Tài liệu:** Bảng ước tính chi phí Cloud (`CLOUD_COST.md`), `RUNBOOK.md`, `POSTMORTEM.md`, `REPORT.md`