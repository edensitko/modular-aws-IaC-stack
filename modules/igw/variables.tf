variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}