provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_name = var.vpc_name
}

module "igw" {
  source     = "./modules/igw"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  name       = var.vpc_name
}

module "security_group" {
  source        = "./modules/security_group"
  sg_name       = "${terraform.workspace}-sg-v2"
  vpc_id        = module.vpc.vpc_id
  allowed_ports = [22, 80, 443]
}

module "asg_alb" {
  source                  = "./modules/asg_alb"
  name                    = "aws-infra-nginx"
  ami_id                  = data.aws_ami.ubuntu.id
  instance_type           = "t2.micro"
  key_name                = module.key_pair.key_name
  subnet_ids              = module.vpc.public_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  launch_template_id      = module.launch_tmpl_nginx.launch_template_id
  launch_template_version = module.launch_tmpl_nginx.launch_template_latest_version
  alb_security_group_id   = module.security_group.alb_sg_id
}

module "key_pair" {
  source   = "./modules/key_pair"
  key_name = "eden-key-v2"
}

module "launch_tmpl_nginx" {
  source                    = "./modules/launch_tmpl_nginx"
  name                      = "aws-infra-nginx"
  ami_id                    = data.aws_ami.ubuntu.id
  instance_type             = "t2.micro"
  key_name                  = module.key_pair.key_name
  security_group_id         = module.security_group.instance_sg_id
  iam_instance_profile_name = module.iam_role_ec2.instance_profile_name
}

module "iam_role_ec2" {
  source     = "./modules/iam-role-ec2"
  role_name  = "aws-infra-ec2"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

module "cloudwatch" {
  source   = "./modules/cloudwatch"
  name     = "aws-infra-nginx"
  asg_name = module.asg_alb.asg_name
}

output "alb_dns_name" {
  value = module.asg_alb.alb_dns_name
}
