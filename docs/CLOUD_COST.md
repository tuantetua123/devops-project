# Bảng Ước Tính Chi Phí Vận Hành Trên Cloud (Bài 12)

Ước tính chi phí hàng tháng khi chuyển cụm 3 máy ảo cục bộ của Nhóm 7 lên **AWS (Region: ap-southeast-1 - Singapore)**:

| Thành phần | Cấu hình tương đương AWS | Số lượng | Đơn giá | Chi phí / tháng |
| :--- | :--- | :---: | :---: | :---: |
| Jenkins CI/CD Server | EC2 `t3.medium` (2 vCPU, 4 GB RAM) | 1 | $0.0464/giờ | ~$33.87 |
| k3s Master Node | EC2 `t3.medium` (2 vCPU, 4 GB RAM) | 1 | $0.0464/giờ | ~$33.87 |
| k3s Worker Node | EC2 `t3.medium` (2 vCPU, 4 GB RAM) | 1 | $0.0464/giờ | ~$33.87 |
| Lưu trữ EBS | EBS `gp3` (30 GB/VM) | 90 GB | $0.096/GB | ~$8.64 |
| Container Registry | GHCR / AWS ECR (5 GB) | 1 | Miễn phí / $0.10/GB | ~$0.50 |
| **Tổng cộng** | | | | **~$110.75 / tháng** |

**Tối ưu chi phí:** Tắt node Staging ngoài giờ hành chính (20:00–07:00 & cuối tuần) giúp tiết kiệm ~45% chi phí compute cho môi trường thử nghiệm.