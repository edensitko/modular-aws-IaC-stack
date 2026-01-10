variable "name_prefix" {
  description = "Prefix to be used in the naming of resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "lambda_environment_variables" {
  description = "Map of environment variables to be provided to the Lambda functions"
  type        = map(map(string))
  default     = {}
}

variable "s3_trigger_bucket" {
  description = "Optional S3 bucket name to trigger the s3_processor Lambda function"
  type        = string
  default     = ""
}

variable "create_s3_trigger" {
  description = "Whether to create an S3 trigger for the s3_processor Lambda function"
  type        = bool
  default     = false
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "telegram_api_url" {
  description = "Telegram API URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}
