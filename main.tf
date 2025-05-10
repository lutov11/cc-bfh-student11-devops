provider "aws" {
  region  = "eu-central-1"
}




resource "aws_s3_bucket" "result_bucket" {
  bucket = "cc-bfh-${var.student_id}-result-do"

  force_destroy = true 

  tags = {
    Owner   = var.student_id
    Project = "iac-lab"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.student_id}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

data "aws_iam_policy_document" "lambda_s3_write_policy_document" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["arn:aws:s3:::cc-bfh-${var.student_id}-result/*"]
  }
}

resource "aws_iam_policy" "lambda_s3_write_policy" {
  name   = "lambda-s3-write-policy"
  policy = data.aws_iam_policy_document.lambda_s3_write_policy_document.json
}

resource "aws_iam_policy_attachment" "lambda_s3_policy_attachment" {
  name       = "lambda-s3-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.lambda_s3_write_policy.arn
}

resource "aws_lambda_function" "lambda" {
  function_name = "cc-bfh-${var.student_id}-lambda-do"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/lambda.zip"

  environment {
    variables = {
      RESULT_BUCKET = aws_s3_bucket.result_bucket.bucket
    }
  }

  tags = {
    Owner   = var.student_id
    Project = "iac-lab"
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "result_bucket" {
  value = aws_s3_bucket.result_bucket.bucket
}

