# S3 event notification configuration for the s3_processor Lambda function
resource "aws_s3_bucket_notification" "lambda_trigger" {
  count  = var.create_s3_trigger && var.s3_trigger_bucket != "" ? 1 : 0
  bucket = var.s3_trigger_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.functions["s3_processor"].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}

# Permission for S3 to invoke the Lambda function
resource "aws_lambda_permission" "s3_trigger" {
  count         = var.create_s3_trigger && var.s3_trigger_bucket != "" ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions["s3_processor"].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_trigger_bucket}"
}