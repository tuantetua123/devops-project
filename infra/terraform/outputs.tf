output "node_ips" {
  description = "IP của từng máy ảo"
  value       = module.cluster.node_ips
}

output "next_steps" {
  description = "Lệnh chạy Ansible sau khi máy ảo đã lên"
  value       = <<-EOT
    cd ../vagrant
    vagrant ssh jenkins -c "cd ~/ansible && ansible-playbook site.yml"
  EOT
}
