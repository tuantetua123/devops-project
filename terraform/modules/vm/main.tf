
resource "virtualbox_vm" "this" {
  name   = var.vm_name
  image  = var.image
  cpus   = var.cpus
  memory = var.memory
  status = var.status

  network_adapter {
    type           = "hostonly"
    host_interface = var.host_interface
  }
}
