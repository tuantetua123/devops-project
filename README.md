# Điểm danh sinh viên bằng mã QR (đồ án DevOps)

Thành phần: `web` (nginx, giao diện giảng viên + trang sinh viên) → `api` (FastAPI) → `qr` (sinh/kiểm tra QR có hạn 45s) + `db` (PostgreSQL).
Mỗi service backend có `/health`, `/metrics`, log JSON ra stdout, cấu hình bằng biến môi trường.

## Chạy môi trường dev (1 lệnh)
```bash
cp .env.example .env        # sửa mật khẩu, PUBLIC_BASE_URL = IP LAN của máy
docker compose up -d --build
docker compose run --rm seed   # (tùy chọn) dữ liệu mẫu
```
Mở http://localhost:8080, nhập `ADMIN_API_KEY` → tạo lớp → bắt đầu buổi học → quét QR bằng điện thoại.

## Test
```bash
pip install -r qr/requirements.txt -r qr/requirements-dev.txt && pytest qr/tests
```

## Quy ước
- Nhánh `main` được bảo vệ, mọi thay đổi qua Pull Request (>= 1 review).
- Commit theo Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `ci:`.
- Tag phiên bản semver: `v0.1.0`.

## Tài liệu
- `docs/ROADMAP.md`: checklist 12 bài + kịch bản demo

L�u ?: n?u c?ng 8080 b? chi?m, �?t WEB_PORT trong .env (v� d? 18080) v� �?i PUBLIC_BASE_URL cho kh?p.
////