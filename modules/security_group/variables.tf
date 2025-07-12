variable "sg_name" {
  type        = string
  description = "Name of the security group"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the SG will be created"
}

variable "allowed_ports" {
  type        = list(number)
  description = "List of allowed ingress TCP ports"
  default     = [22, 80, 443]
}