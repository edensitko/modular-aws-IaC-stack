variable "name" {
  description = "Prefix for alarm and policies"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "high_cpu_threshold" {
  description = "CPU usage threshold for high CPU alarm"
  type        = number
  default     = 80
}

variable "low_cpu_threshold" {
  description = "CPU usage threshold for low CPU alarm"
  type        = number
  default     = 20
}