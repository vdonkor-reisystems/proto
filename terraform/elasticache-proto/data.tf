
data "aws_caller_identity" "account" {}
data "aws_availability_zones" "available" {}
data "aws_iam_policy_document" "read_secret" {
  statement {
    sid = "AllowSecretManagerReadAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.redis_user_secret_manager.arn
    ]
  }
}

data "aws_iam_policy_document" "assume_lambda_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
data "aws_vpc_endpoint_service" "secrets_manager" {
  service = "secretsmanager"
}
