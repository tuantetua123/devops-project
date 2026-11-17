# Cặp khóa SSH dùng chung: máy Jenkins (chạy Ansible) -> các máy còn lại
resource "tls_private_key" "cluster" {
  algorithm = "ED25519"
}

# Terraform là nguồn sự thật về mạng + firewall; Ansible đọc file này để áp ufw
resource "local_file" "ansible_vars" {
  filename        = "${path.root}/../ansible/inventories/local/group_vars/all/terraform.yml"
  file_permission = "0644"
  content = join("\n", [
    "# Sinh tự động bởi Terraform. KHÔNG sửa tay (sửa trong terraform/variables.tf).",
    yamlencode({
      network_cidr   = var.network_cidr
      firewall_rules = var.firewall_rules
    }),
    "",
  ])
}

module "cluster" {
  source = "./modules/local-cluster"

  project         = var.project
  box             = var.box
  nodes           = var.nodes
  workdir         = abspath("${path.root}/../vagrant")
  ansible_dir     = replace(abspath("${path.root}/../ansible"), "\\", "/")
  ssh_public_key  = trimspace(tls_private_key.cluster.public_key_openssh)
  ssh_private_key = tls_private_key.cluster.private_key_openssh

  depends_on = [local_file.ansible_vars]
}
