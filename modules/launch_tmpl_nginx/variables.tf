variable "name" {
  type        = string
  description = "Prefix for naming resources"
}

variable "ami_id" {
  type        = string
  description = "AMI ID to use"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "Key pair name"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the instance"
}

variable "iam_instance_profile_name" {
  type        = string
  description = "IAM instance profile name to attach to the instance"
  default     = ""
}
