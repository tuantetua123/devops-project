
output "vm_name" {
  value = virtualbox_vm.server.name
}

output "vm_id" {
  value = virtualbox_vm.server.id
}

output "vm_ip" {
  value = virtualbox_vm.server.network_adapter[0].ipv4_address
}
