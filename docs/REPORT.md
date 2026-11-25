# Báo Cáo Tổng Kết Đồ Án Môn DevOps — Nhóm 7

## 1. Thông tin nhóm & Phân công nhiệm vụ
- **Đề tài 02:** Điểm danh sinh viên bằng mã QR
- **Bùi Đình Sơn (Nhóm trưởng):** Quản lý quy trình Git/PR, phát triển Frontend (`web`), Docker hóa Frontend, tổng hợp báo cáo.
- **Nguyễn Văn Định:** Dựng hạ tầng 3 VM (`infra/vagrant`), Terraform (`infra/terraform`), Ansible (`infra/ansible`), bảo mật & backup Linux (`scripts/`, `deploy/`).
- **Nguyễn Khắc Hưng:** Xây dựng pipeline CI/CD trên Jenkins (`Jenkinsfile`), tích hợp webhook, credentials và thông báo Telegram.
- **Lê Văn Tuấn:** Phát triển Backend (`api`, `qr`) chuẩn `/health`, `/metrics`, log JSON; triển khai Kubernetes (`k8s/`), K8s Job migration/seed, Giám sát (`monitoring/`), Bảo mật (`Trivy`, `Gitleaks`, `RBAC`, `cert-manager`) và Runbook.

## 2. Kiến trúc hệ thống & Quy trình CI/CD
- **Ứng dụng 4 thành phần:** `web` (Nginx) -> `api` (FastAPI) -> `qr` (FastAPI sinh/xác thực mã QR có hạn 45s) + `db` (PostgreSQL 16).
- **Luồng CI/CD:** `Checkout (SHA)` -> `Gitleaks` -> `Lint (Ruff + Hadolint)` -> `Pytest` -> `Docker Build` -> `Compose Smoke Test` -> `Trivy Scan` -> `Push GHCR` -> `K8s Migrate & Seed Job` -> `Deploy Staging` -> `Manual Approve` -> `Deploy Production`.