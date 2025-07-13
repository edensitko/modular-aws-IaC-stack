# Modular Terraform AWS Infrastructure Stack

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)

This repository contains a modular Terraform AWS infrastructure stack with components for VPC, security groups, IAM roles, launch templates, Auto Scaling Groups, and CloudWatch monitoring.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Module Structure](#module-structure)
- [Features](#features)
- [CI/CD Workflows](#cicd-workflows)
- [Local Development](#local-development)
- [AWS Resources](#aws-resources)
- [EC2 Dashboard](#ec2-dashboard)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## 🌟 Overview

This project implements a modular AWS infrastructure using Terraform with a focus on maintainability, scalability, and security. The infrastructure includes VPC networking, auto-scaling EC2 instances running NGINX, load balancing, IAM roles, security groups, and CloudWatch monitoring.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                               │
│                                                                 │
│  ┌─────────────┐     ┌──────────────┐      ┌────────────────┐   │
│  │             │     │              │      │                │   │
│  │     VPC     │────▶│  Public      │──────▶│  Internet      │   │
│  │             │     │  Subnets     │      │  Gateway      │   │
│  └─────────────┘     └──────────────┘      └────────────────┘   │
│         │                    │                                   │
│         ▼                    ▼                                   │
│  ┌─────────────┐     ┌──────────────┐      ┌────────────────┐   │
│  │             │     │              │      │                │   │
│  │  Security   │     │  Application │◀────▶│  Auto Scaling  │   │
│  │  Groups     │────▶│  Load        │      │  Group         │   │
│  │             │     │  Balancer    │      │                │   │
│  └─────────────┘     └──────────────┘      └────────────────┘   │
│                                                   │              │
│                                                   ▼              │
│  ┌─────────────┐     ┌──────────────┐      ┌────────────────┐   │
│  │             │     │              │      │                │   │
│  │  IAM Roles  │────▶│  Launch      │──────▶│  EC2 Instances │   │
│  │  & Policies │     │  Template    │      │  (NGINX)       │   │
│  │             │     │              │      │                │   │
│  └─────────────┘     └──────────────┘      └────────────────┘   │
│         │                                          │            │
│         │                                          ▼            │
│         │                                   ┌────────────────┐   │
│         └─────────────────────────────────▶│                │   │
│                                             │  CloudWatch    │   │
│                                             │  Monitoring    │   │
│                                             │                │   │
│                                             └────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Module Structure

The infrastructure is organized into the following modules:

- **VPC**: Network foundation with public subnets
- **IGW**: Internet Gateway for public subnet connectivity
- **Security Group**: Firewall rules for EC2 instances and ALB
- **Key Pair**: SSH key management for EC2 access
- **IAM Role**: EC2 instance roles with policies for S3 and CloudWatch access
- **Launch Template**: EC2 configuration with NGINX installation
- **ASG & ALB**: Auto Scaling Group with Application Load Balancer
- **CloudWatch**: Monitoring and auto-scaling triggers

## ✨ Features

### 🌐 Networking

- **VPC**: Isolated network environment
- **Public Subnets**: Distributed across availability zones
- **Internet Gateway**: Public internet access
- **Security Groups**: Granular traffic control

### 🔒 Security

- **IAM Roles**: Least privilege access for EC2 instances
- **Security Groups**: Restricted access to necessary ports only (22, 80, 443)
- **SSH Key Pairs**: Secure instance access with auto-generated keys

### 🚀 EC2 & Load Balancer Stack

- **Launch Template**:
  - Ubuntu-based EC2
  - Installs and configures **NGINX** with custom HTML dashboard
  - Health check served via `/health.html`

- **Auto Scaling Group (ASG)**:
  - Launches EC2 from template across availability zones
  - Integrated with Application Load Balancer

- **Application Load Balancer (ALB)**:
  - Targets EC2 instances
  - Health checks automatically deregister unhealthy instances

### 📊 Monitoring & Scaling

- **EC2 Instance Dashboard**: Displays instance metadata, IAM role permissions, running services, and CloudWatch CPU metrics
- **CloudWatch Alarms**:
  - High CPU utilization (>80%) triggers scale-out
  - Low CPU utilization (<30%) triggers scale-in
- **Auto-Scaling Policies**:
  - Scale-out: Add one instance when CPU is high
  - Scale-in: Remove one instance when CPU is low
  - ASG configured with min=1, max=2, desired=1 instances

## 🔄 CI/CD Workflows

The repository includes GitHub Actions workflows for CI/CD:

### Terraform Plan

Validates changes without applying them:

- Initializes Terraform
- Selects the appropriate workspace
- Runs format check and validation
- Creates and uploads a plan artifact

### Terraform Apply

Deploys infrastructure with approval:

- Requires manual confirmation with "APPLY" input
- Supports environment selection (dev/prod)
- Handles existing resource conflicts with options:
  - **Import existing resources**: Imports IAM roles, policies, and EC2 key pairs into Terraform state
  - **Destroy before apply**: Runs `terraform destroy` before applying to ensure clean deployment
  - **Force delete resources**: Uses AWS CLI to force delete specific conflicting resources
- Uses random resource name suffixes to avoid naming conflicts
- Uploads state and outputs as artifacts

### Terraform Destroy

Tears down infrastructure with approval:

- Requires manual confirmation with "DESTROY" input
- Supports environment selection
- Destroys all resources in the selected workspace

### Important Note on IAM Permissions

The GitHub Actions workflows require an AWS IAM user with sufficient permissions. The 'modular-aws' user may need additional permissions for:

- EC2 operations (ImportKeyPair, CreateVpc)
- IAM operations (CreateRole, DeleteRole, AttachRolePolicy)
- CloudWatch operations
- Auto Scaling operations

If you encounter permission errors, you may need to:

1. Add additional permissions to the IAM user
2. Use the force delete options in the workflow
3. Use the random suffix feature for resources to avoid conflicts

## 🚀 Local Development

### Prerequisites

- Terraform v1.0+
- AWS CLI configured with appropriate credentials
- S3 bucket for Terraform state (configured in backend.tf)
- IAM user with sufficient permissions

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/edensitko/modular-aws-IaC-stack.git
cd modular-aws-IaC-stack
```

2. **Initialize Terraform**

```bash
terraform init
```

3. **Select workspace (environment)**

```bash
terraform workspace select dev  # or create: terraform workspace new dev
```

4. **Plan the deployment**

```bash
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
```

5. **Apply the changes**

```bash
terraform apply tfplan
```

### Handling Existing Resources

If you encounter conflicts with existing resources, you have several options:

1. **Import existing resources into Terraform state**:

```bash
terraform import module.iam_role_ec2.aws_iam_role.this aws-infra-ec2
terraform import module.iam_role_ec2.aws_iam_policy.dashboard_policy aws-infra-ec2-dashboard-policy
terraform import module.key_pair.aws_key_pair.this eden-key-v2
```

2. **Use random suffixes for resource names** (already implemented in the code):
   - IAM roles, policies, and key pairs now use random suffixes to avoid conflicts
   - Each deployment creates new resources with unique names

3. **Destroy and recreate resources**:

```bash
terraform destroy -target=module.iam_role_ec2 -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 💻 AWS Resources

This stack creates the following resources:

- **VPC** with public subnets across availability zones
- **Internet Gateway** for public internet access
- **Security Groups** for instances (ports 22, 80, 443) and ALB (ports 80, 443)
- **Key Pair** with auto-generated RSA 4096-bit keys and random suffix
- **Launch Template** with user data script for NGINX installation and dashboard setup
- **Auto Scaling Group** with Application Load Balancer and health checks
- **IAM Role** with custom policies for S3 access and CloudWatch metrics
- **CloudWatch Alarms** for CPU utilization and auto-scaling triggers

## 📊 EC2 Dashboard

The EC2 instances include a custom HTML dashboard that displays:

- **Instance Metadata**: ID, type, availability zone, region
- **IAM Information**: Role name, attached policies, and permissions
- **System Status**: Running services, CPU usage, memory usage
- **CloudWatch Metrics**: Real-time CPU utilization with interactive charts
- **Health Check**: Status endpoint at `/health.html` for ALB health checks

## 🔧 Maintenance

To update the infrastructure:

1. **Modify the Terraform configuration**:
   - Update module parameters in `main.tf`
   - Add/modify environment-specific variables in `environments/<env>/terraform.tfvars`

2. **Run validation**:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```

3. **Plan changes**:
   ```bash
   terraform plan -var-file=environments/<env>/terraform.tfvars -out=tfplan
   ```

4. **Apply changes**:
   ```bash
   terraform apply tfplan
   ```

5. **Verify deployment**:
   - Check the Auto Scaling Group for instance refresh status
   - Verify ALB health checks are passing
   - Access the EC2 dashboard via the ALB DNS name

## 💰 Cost Estimation with Infracost

This project integrates with Infracost to provide cost estimates for AWS resources before deployment.

### Local Cost Estimation

To estimate costs locally:

1. **Install Infracost**:
   ```bash
   brew install infracost
   ```

2. **Authenticate with Infracost**:
   ```bash
   infracost auth login
   ```

3. **Generate cost breakdown**:
   ```bash
   infracost breakdown --path=.
   ```

4. **Compare changes before applying**:
   ```bash
   infracost diff --path=. --compare-to=infracost-base.json
   ```

### CI/CD Integration

Infracost is integrated into the CI/CD pipeline to provide cost estimates on pull requests:

1. **GitHub Actions Workflow**: `.github/workflows/infracost.yml`
2. **Configuration**: `infracost.yml` and `infracost-usage.yml`
3. **Required Secret**: Add `INFRACOST_API_KEY` to GitHub repository secrets

### Cost Optimization

Based on the current configuration, estimated monthly costs are:
- **Dev Environment**: ~$25/month
- **Prod Environment**: ~$25/month

Main cost components:
- Application Load Balancer: $16.43/month
- EC2 instances (t2.micro): $8.47/month per instance
- CloudWatch alarms: $0.20/month

## 🔧 Troubleshooting

### Resource Conflicts

**Problem**: `EntityAlreadyExists` errors during apply for IAM roles, policies, or key pairs.

**Solutions**:
1. Use the random suffix feature (already implemented)
2. Import existing resources into Terraform state
3. Use the `force_delete_resources` option in the GitHub Actions workflow
4. Manually delete conflicting resources in the AWS Console

### Permission Issues

**Problem**: `UnauthorizedOperation` errors during apply.

**Solutions**:
1. Verify the IAM user has the necessary permissions
2. Add missing permissions to the IAM user policy:
   - EC2: ImportKeyPair, CreateVpc, CreateSecurityGroup, etc.
   - IAM: CreateRole, AttachRolePolicy, etc.
   - CloudWatch: PutMetricAlarm, etc.
   - AutoScaling: CreateAutoScalingGroup, etc.

### GitHub Actions Workflow Issues

**Problem**: GitHub Actions workflow fails with AWS credential errors.

**Solutions**:
1. Verify AWS credentials are correctly set as GitHub repository secrets
2. Check the format of the secrets (no extra spaces or characters)
3. Ensure the IAM user has the necessary permissions

## 💾 Environment Management

The project supports multiple environments through Terraform workspaces:

- **Dev**: Development environment (workspace: dev)
- **Prod**: Production environment (workspace: prod)

Environment-specific configurations are stored in the `environments/` directory with separate variable files for each environment.

## 🔒 Security Best Practices

- **IAM Roles**: Follow the principle of least privilege
- **Security Groups**: Restrict access to necessary ports only
- **SSH Keys**: Generated securely and stored with appropriate permissions
- **Resource Naming**: Use random suffixes to avoid predictable naming
- **Secrets Management**: Store AWS credentials as GitHub secrets, never in code
- **Approval Workflows**: Require manual confirmation for destructive operations

If you encounter issues with the EC2 dashboard:

- Check IAM permissions for CloudWatch metrics and IAM role access
- Verify the user data script in the launch template
- Ensure the Auto Scaling Group has completed instance refresh

