
resource "virtualbox_vm" "server" {
  name  = var.vm_name
  image = var.vm_image

  cpus   = var.cpu
  memory = var.memory
  status = "poweroff"

  network_adapter {
    type           = "hostonly"
    host_interface = var.host_interface
  }
}
