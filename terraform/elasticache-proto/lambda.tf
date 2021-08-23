resource "aws_lambda_function" "redis_test" {
  filename = "rbac.zip"
  function_name = "rbac"
  role = aws_iam_role.redis_iam_role.arn
  handler = "rbac.handler"
  memory_size = "512"
  runtime = "python3.8"
  timeout = 90
  source_code_hash = filebase64sha256("rbac.zip")
  vpc_config {
    security_group_ids = [aws_security_group.lambda.id,aws_security_group.secret_manager.id]
    subnet_ids = module.vpc.private_subnets
  }
  environment {
    variables = {
      redis_endpoint = aws_elasticache_replication_group.replication_group.primary_endpoint_address
      secret_id = aws_secretsmanager_secret.redis_user_secret_manager.name
      region = var.region
    }
  }
  depends_on = [aws_elasticache_replication_group.replication_group]
}
