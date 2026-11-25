# Postmortem Sự Cố: Lỗi Kubernetes Job Migration Trùng Tên Khi Re-deploy

- **Ngày xảy ra:** 18/11/2026
- **Mức độ:** Trung bình (Gián đoạn luồng deploy tự động lên Staging)
- **Người xử lý:** Lê Văn Tuấn, Nguyễn Khắc Hưng (Nhóm 7)

## 1. Tóm tắt sự cố
Khi merge Pull Request cập nhật schema CSDL lần thứ hai vào nhánh `main`, stage `Deploy staging` trên Jenkins báo lỗi từ lệnh `kubectl apply -f k8s/jobs/migrate-job.yaml`.

## 2. Diễn biến & Nguyên nhân gốc rễ
- Kubernetes khóa cứng trường `spec.template` của đối tượng `batch/v1 Job` sau lần tạo đầu tiên (immutable).
- Việc giữ nguyên `metadata.name` cố định và dùng `kubectl apply` ở lần chạy sau gây xung đột cấu hình bất biến.

## 3. Khắc phục & Phòng ngừa
- Chuyển sang dùng `metadata.generateName: migrate-` (và `seed-` cho Job dữ liệu mẫu), khởi chạy bằng `kubectl create -f` trong `Jenkinsfile`.
- Bật `ttlSecondsAfterFinished: 600` để K8s tự dọn dẹp Job cũ sau 10 phút.