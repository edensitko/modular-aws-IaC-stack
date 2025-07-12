# Generate a random suffix for resource names to avoid conflicts
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  resource_suffix = random_string.suffix.result
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.key_name}-${local.resource_suffix}"
  public_key = tls_private_key.this.public_key_openssh

  lifecycle {
    create_before_destroy = true
  }
}

resource "local_file" "private_key_pem" {
  content              = tls_private_key.this.private_key_pem
  filename             = "${path.root}/${var.key_name}-${local.resource_suffix}.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}