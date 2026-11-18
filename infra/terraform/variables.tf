variable "project" {
  description = "Tiền tố đặt tên máy ảo trong VirtualBox"
  type        = string
  default     = "attendance"
}

variable "box" {
  description = "Vagrant box (Ubuntu 22.04)"
  type        = string
  default     = "ubuntu/jammy64"
}

variable "network_cidr" {
  description = "Mạng host-only giữa các máy ảo (VirtualBox mặc định 192.168.56.0/24)"
  type        = string
  default     = "192.168.56.0/24"
}

variable "nodes" {
  description = "Các máy ảo: control = Jenkins + Ansible, server = k3s server, agent = k3s agent"
  type = map(object({
    ip     = string
    cpus   = number
    memory = number
    role   = string
  }))
  default = {
    jenkins = { ip = "192.168.56.10", cpus = 2, memory = 3072, role = "control" }
    k3s-1   = { ip = "192.168.56.11", cpus = 2, memory = 2048, role = "server" }
    k3s-2   = { ip = "192.168.56.12", cpus = 2, memory = 2048, role = "agent" }
  }

  validation {
    condition     = length([for n in var.nodes : n if n.role == "control"]) == 1
    error_message = "Phải có đúng 1 node role = \"control\" (máy chạy Jenkins và Ansible)."
  }

  validation {
    condition     = alltrue([for n in var.nodes : contains(["control", "server", "agent"], n.role)])
    error_message = "role chỉ được là control, server hoặc agent."
  }
}

variable "firewall_rules" {
  description = "Luật tường lửa, Terraform sinh ra file vars cho Ansible áp bằng ufw"
  type = list(object({
    port    = string
    proto   = string
    source  = string
    comment = string
  }))
  default = [
    { port = "22", proto = "tcp", source = "any", comment = "ssh" },
    { port = "80", proto = "tcp", source = "any", comment = "http" },
    { port = "443", proto = "tcp", source = "any", comment = "https" },
    { port = "6443", proto = "tcp", source = "192.168.56.0/24", comment = "k3s api" },
    { port = "10250", proto = "tcp", source = "192.168.56.0/24", comment = "kubelet" },
    { port = "8472", proto = "udp", source = "192.168.56.0/24", comment = "flannel vxlan" },
    { port = "8080", proto = "tcp", source = "192.168.56.0/24", comment = "jenkins ui" },
    { port = "50000", proto = "tcp", source = "192.168.56.0/24", comment = "jenkins agent" },
    { port = "9100", proto = "tcp", source = "192.168.56.0/24", comment = "node exporter" },
    { port = "any", proto = "any", source = "10.42.0.0/16", comment = "k3s pod cidr" },
    { port = "any", proto = "any", source = "10.43.0.0/16", comment = "k3s service cidr" },
  ]
}
