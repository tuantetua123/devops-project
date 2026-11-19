variable "vm_cpu" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type    = string
  default = "2048mib"
}

variable "host_interface" {
  type    = string
  default = "VirtualBox Host-Only Ethernet Adapter"
}
variable "vm_image" {
  description = "VirtualBox VM image path"
  type        = string
}