
output "vm_id" {
  description = "VirtualBox VM ID"
  value       = virtualbox_vm.this.id
}

output "vm_name" {
  description = "VirtualBox VM name"
  value       = virtualbox_vm.this.name
}

output "vm_ip" {
  description = "VirtualBox VM IPv4 address"
  value       = virtualbox_vm.this.network_adapter[0].ipv4_address
}
