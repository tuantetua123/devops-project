
variable "vm_name" {
  description = "Ten may ao"
  type        = string
}

variable "vm_image" {
  description = "Duong dan VirtualBox image"
  type        = string
}

variable "cpu" {
  type    = number
  default = 2
}

variable "memory" {
  type    = string
  default = "2048 mib"
}

variable "host_interface" {
  type    = string
  default = "VirtualBox Host-Only Ethernet Adapter"
}
variable "source_vm" {
  description = "Source VM name"
  type        = string
}