# Runbook Vận Hành Hệ Thống Điểm Danh QR — Nhóm 7

## 1. Quy trình Deploy & Cập nhật thủ công
1. Kiểm tra cụm k3s: `kubectl get nodes` và `kubectl get pods -n production`
2. Chạy K8s Job migration CSDL trước khi nâng cấp backend:
   - `kubectl -n production create configmap db-migrations --from-file=db/migrations --dry-run=client -o yaml | kubectl -n production apply -f -`
   - `JOB_NAME=$(kubectl -n production create -f k8s/jobs/migrate-job.yaml -o name)`
   - `kubectl -n production wait --for=condition=complete "$JOB_NAME" --timeout=90s`
3. Cập nhật image mới theo commit SHA (`<TAG>`):
   - `kubectl apply -k k8s/overlays/production`
   - `kubectl -n production set image deployment/api api=ghcr.io/tuantetua123/attendance-api:<TAG>`
   - `kubectl -n production rollout status deployment/api --timeout=120s`

## 2. Quy trình Rollback khẩn cấp (dưới 2 phút)
- Xem lịch sử: `kubectl -n production rollout history deployment/api`
- Quay lui ngay: `kubectl -n production rollout undo deployment/api`
- Kiểm tra trạng thái: `kubectl -n production rollout status deployment/api --timeout=60s`

## 3. Sao lưu & Khôi phục CSDL PostgreSQL
- Sao lưu định kỳ qua `systemd timer` (`deploy/systemd/attendance-backup.timer`) gọi `scripts/backup-db.sh`.
- Sao lưu thủ công: `bash scripts/backup-db.sh`
- Khôi phục dữ liệu: `bash scripts/restore-db.sh backups/<ten_file_backup>.sql.gz`

## 4. Xử lý cảnh báo (Alertmanager -> Telegram)
- **HighErrorRate (5xx > 5%):** Kiểm tra log trên Grafana/Loki (`level="error"`), thực hiện rollback nếu lỗi phát sinh sau khi deploy.
- **HighLatencyP95 (> 500ms):** Kiểm tra `kubectl get hpa -n production` để xác nhận pod `api`/`qr` tự động scale.
- **PodCrashLooping:** Chạy `kubectl describe pod <pod> -n production` kiểm tra `OOMKilled` hoặc biến môi trường trong `attendance-secrets`.