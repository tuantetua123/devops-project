# Provider VirtualBox cho Terraform không còn được bảo trì (không chạy với VirtualBox 7),
# nên module này để Terraform điều phối Vagrant (VirtualBox) qua file Vagrantfile sinh từ biến.

resource "local_sensitive_file" "private_key" {
  filename        = "${var.workdir}/.keys/id_ed25519"
  content         = var.ssh_private_key
  file_permission = "0600"
}

resource "local_file" "vagrantfile" {
  filename = "${var.workdir}/Vagrantfile"
  content = templatefile("${path.module}/Vagrantfile.tftpl", {
    project        = var.project
    box            = var.box
    nodes          = var.nodes
    ssh_public_key = var.ssh_public_key
    ansible_dir    = var.ansible_dir
  })
}

resource "terraform_data" "vms" {
  input            = var.workdir
  triggers_replace = [local_file.vagrantfile.content_md5]

  depends_on = [local_sensitive_file.private_key]

  provisioner "local-exec" {
    command     = "vagrant up"
    working_dir = var.workdir
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "vagrant destroy -f"
    working_dir = self.input
  }
}
