variable "project" {
  type = string
}

variable "box" {
  type = string
}

variable "nodes" {
  type = map(object({
    ip     = string
    cpus   = number
    memory = number
    role   = string
  }))
}

variable "workdir" {
  description = "Thư mục chứa Vagrantfile sinh ra"
  type        = string
}

variable "ansible_dir" {
  description = "Đường dẫn tuyệt đối (dùng dấu /) tới thư mục ansible để upload lên máy control"
  type        = string
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}
