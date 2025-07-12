variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "VPC"
  type        = string
  default     = "dev-vpc"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}


variable "key_name" {
  description = "EC2 Key Pair name to use"
  type        = string
  default     = "eden-keyv2"
}

variable "policy_arn" {
  description = "IAM Policy ARN to attach to the EC2 instance"
  type        = string
}

variable "role_name" {
  description = "IAM Role name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "aws-infra-nginx"
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
  default     = "aws-infra-nginx"
}

