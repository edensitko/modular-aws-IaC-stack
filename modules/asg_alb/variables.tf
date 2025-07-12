variable "name" {
  description = "Name of the ASG and ALB"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string
}

variable "launch_template_version" {
  description = "Version of the launch template to use"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}
