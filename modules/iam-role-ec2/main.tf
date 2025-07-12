# Generate a random suffix for resource names to avoid conflicts
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  resource_suffix = random_string.suffix.result
}

resource "aws_iam_role" "this" {
  name                  = "${var.role_name}-${local.resource_suffix}"
  force_detach_policies = true

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Attach the S3 read-only policy
resource "aws_iam_role_policy_attachment" "readonly_policy" {
  role       = aws_iam_role.this.name
  policy_arn = var.policy_arn
}

# Create a custom policy for dashboard functionality
resource "aws_iam_policy" "dashboard_policy" {
  name        = "${var.role_name}-dashboard-policy-${local.resource_suffix}"
  description = "Policy for EC2 dashboard to retrieve IAM and CloudWatch information"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Attach the custom dashboard policy
resource "aws_iam_role_policy_attachment" "dashboard_policy_attachment" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.dashboard_policy.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.role_name}-instance-profile-${local.resource_suffix}"
  role = aws_iam_role.this.name

  lifecycle {
    create_before_destroy = true
  }
}