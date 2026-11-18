# Hạ tầng local: Terraform + Vagrant + Ansible

Dựng 3 máy ảo Ubuntu 22.04 trong VirtualBox: `jenkins` (192.168.56.10, vừa chạy Jenkins vừa là máy chạy Ansible),
`k3s-1` (server, .11) và `k3s-2` (agent, .12).

## Cần cài trước
```powershell
winget install Oracle.VirtualBox Hashicorp.Vagrant Hashicorp.Terraform
```
Cần khoảng 8GB RAM trống (mặc định 3+2+2 GB). Máy yếu: copy `terraform/terraform.tfvars.example` thành `terraform.tfvars` rồi giảm RAM.
Nếu Windows đang bật Hyper-V/WSL2 (Docker Desktop), VirtualBox vẫn chạy nhưng chậm hơn.

## Các bước (đây cũng là bước 1 của kịch bản demo)
**0. Tạo file mật khẩu Vault** (file này KHÔNG commit, xin mật khẩu từ người giữ):
```powershell
Set-Content infra\ansible\vault-pass.txt "<mat-khau-vault>" -NoNewline
```
**1. Dựng máy ảo bằng Terraform** (lần đầu tải box ~500MB, mất 10-20 phút):
```powershell
cd infra\terraform
terraform init
terraform apply
```
**2. Cài đặt từ máy trắng bằng Ansible** (chạy trên máy `jenkins`):
```powershell
cd ..\vagrant
vagrant ssh jenkins -c "cd ~/ansible && ansible-playbook site.yml"
```
**3. Chạy lần 2, kết quả phải là `changed=0` (idempotent):**
```powershell
vagrant ssh jenkins -c "cd ~/ansible && ansible-playbook site.yml"
```
**4. Kiểm tra**
```powershell
vagrant ssh k3s-1 -c "sudo k3s kubectl get nodes -o wide"     # 2 node Ready
vagrant ssh jenkins -c "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
```
Mở http://192.168.56.10:8080 để vào Jenkins. Node exporter: http://192.168.56.11:9100/metrics

**Dọn dẹp:** `cd infra\terraform; terraform destroy`

## Khi sửa Ansible sau khi máy ảo đã chạy
Thư mục `ansible/` được upload lên máy `jenkins` lúc `vagrant up`. Sửa xong chạy lại để cập nhật:
```powershell
cd infra\vagrant
vagrant provision jenkins --provision-with upload-ansible
```

## Ansible Vault
```powershell
# xem / sửa (chạy trên máy jenkins hoặc nơi có ansible)
ansible-vault view ansible/inventories/local/group_vars/all/vault.yml
ansible-vault rekey ansible/inventories/local/group_vars/all/vault.yml   # đổi mật khẩu
```
`vault.yml` đã mã hóa được commit. Mật khẩu (`vault-pass.txt`) giữ ngoài Git, chia sẻ qua kênh riêng của nhóm.

## Ánh xạ với đề bài
| Yêu cầu | Nằm ở đâu |
|---|---|
| Terraform: máy ảo, mạng, firewall, biến, output, module tự viết | `terraform/` + `terraform/modules/local-cluster` |
| State không commit | `.gitignore` (tfstate, .terraform) |
| Ansible chia role, từ máy trắng | `ansible/roles/*`: common, docker, node_exporter, k3s_server, k3s_agent, jenkins |
| Inventory tách theo môi trường | `ansible/inventories/local/` |
| Idempotent | các task dùng `creates`, module khai báo trạng thái |
| Secret bằng Ansible Vault | `group_vars/all/vault.yml` (token k3s) |
| user riêng, SSH key, tắt root, ufw (bài 3) | role `common` |
| Firewall do Terraform định nghĩa | `variables.tf` -> `terraform.yml` -> ufw |

## Giới hạn hiện tại (nói thật khi vấn đáp)
- Provider VirtualBox của Terraform không còn được bảo trì, nên module để Terraform điều phối Vagrant (VirtualBox).
- Chưa có Molecule, chưa gọi playbook từ pipeline Jenkins (mục Nâng cao).
- Các luật ufw áp giống nhau cho cả 3 máy cho đơn giản.
