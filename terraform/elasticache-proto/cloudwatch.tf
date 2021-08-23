resource "aws_cloudwatch_log_group" "redis_logs" {
  name = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis/logs"
  tags = var.tags

}

data "aws_iam_policy_document" "elasticache_logs" {
  statement {
    sid = "AllowRedisLoging"
    actions = [
      "logs:CreateLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries"
    ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    sid = "AllowRedisCloudwatch"
    actions = [
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
    effect = "Allow"
  }
}




//resource "aws_cloudwatch_log_destination_policy" "redis_destination_policy" {
////  destination_name = aws_cloudwatch_log_destination.redis_logs.name
//  access_policy    = data.aws_iam_policy_document.elasticache_logs.json
//}
