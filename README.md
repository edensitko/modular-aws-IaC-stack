# Modular AWS Infrastructure Stack

This repository contains a modular Terraform AWS infrastructure stack with components for VPC, security groups, IAM roles, launch templates, Auto Scaling Groups, and CloudWatch monitoring.

## Features

- **EC2 Instance Dashboard**: Displays instance metadata, IAM role permissions, running services, and CloudWatch CPU metrics
- **Auto Scaling**: Configured with scale-out (CPU > 80%) and scale-in (CPU < 30%) policies
- **IAM Roles**: Custom IAM policies for EC2 instances with permissions for CloudWatch metrics and IAM role info retrieval
- **CloudWatch Integration**: CPU utilization metrics displayed in the dashboard with interactive charts
- **Modular Design**: Separate modules for each infrastructure component

## CI/CD Workflow

The repository includes GitHub Actions workflows for CI/CD:

1. **Terraform Validation**: Runs on push and pull requests to validate syntax and formatting
2. **Terraform Validation (Manual)**: Can be manually triggered to validate specific environments

### Important Note on CI/CD

The GitHub Actions workflows are configured in **validation-only mode** due to limited IAM permissions. The workflows will:

1. Check Terraform formatting
2. Validate Terraform syntax
3. List files that would be deployed
4. Upload the file list as an artifact

No AWS API calls are made during these workflows, ensuring they will run successfully without requiring additional permissions.

To apply changes, you need to run Terraform locally with proper AWS credentials.

## Local Development

### Prerequisites

- Terraform v1.0+
- AWS CLI configured with appropriate credentials
- S3 bucket for Terraform state (optional)

### Setup

1. Clone the repository
2. Configure AWS credentials with sufficient permissions
3. Initialize Terraform:

```bash
terraform init
```

4. Select or create a workspace:

```bash
terraform workspace select dev || terraform workspace new dev
```

5. Plan changes:

```bash
terraform plan -out=tfplan
```

6. Apply changes:

```bash
terraform apply tfplan
```

## AWS Resources

This stack creates the following resources:

- VPC with public subnets
- Internet Gateway
- Security Groups for instances and ALB
- Key Pair
- Launch Template with user data script
- Auto Scaling Group with ALB
- IAM Role with custom policies
- CloudWatch Alarms and Metrics

## EC2 Dashboard

The EC2 instances include a dashboard that displays:

- Instance metadata (ID, type, AZ)
- Running services
- IAM role permissions
- CloudWatch CPU utilization metrics with charts

## Maintenance

To update the infrastructure:

1. Modify the Terraform configuration
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes
4. Check the Auto Scaling Group for instance refresh status

## Troubleshooting

If you encounter issues with the EC2 dashboard:

- Check IAM permissions for CloudWatch metrics and IAM role access
- Verify the user data script in the launch template
- Ensure the Auto Scaling Group has completed instance refresh
