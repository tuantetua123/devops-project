
module "staging_vm" {
  source = "../../modules/vm"

  vm_name = "devops-staging-test"
  image   = "../../images/ubuntu-jammy.box"

  cpus   = var.vm_cpu
  memory = "2.0 gib"
  status = "running"

  host_interface = var.host_interface
}
