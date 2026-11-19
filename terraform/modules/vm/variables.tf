
variable "vm_name" {
  description = "Name of VirtualBox VM"
  type        = string
}

variable "image" {
  description = "Path or URL of Vagrant VirtualBox box image"
  type        = string
}

variable "cpus" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory allocated to VM"
  type        = string
  default     = "2048 mib"
}

variable "status" {
  description = "VM power status"
  type        = string
  default     = "running"

  validation {
    condition     = contains(["running", "poweroff"], var.status)
    error_message = "Status must be running or poweroff."
  }
}

variable "host_interface" {
  description = "VirtualBox Host-only adapter name"
  type        = string
}
