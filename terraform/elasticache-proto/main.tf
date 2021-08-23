locals {
  all_ips  = ["0.0.0.0/0"]
  any_port = 0
  https_port = 443
  any_protocol = "-1"
  tcp_protocol = "tcp"
  redis_port = 6379
  redis_snapshot_retention_limit = 10
  redis_access_string = "on ~* -@all +SET"
  redis_user_credentials = {
    redis_rbac_user = var.redis_app_user
    redis_rbac_user_password = random_password.redis_user_password.result
    kms_key_id = aws_kms_key.redis_cmk_key.id
  }
}

#create random string
resource "random_string" "random" {
  length = 4
  special = false
  upper = false
}

#create random password to assign to redis user
resource "random_password" "redis_user_password" {
  length           = 16
  special          = true
  override_special = "@%*()_+="
  keepers = {
    name = "do_not_change"
  }
}

#create aws secret to store password for the user
resource "aws_secretsmanager_secret" "redis_user_secret_manager" {
  name = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis-rbac"
}

#create secret
resource "aws_secretsmanager_secret_version" "redis_user_secret" {
  secret_id     = aws_secretsmanager_secret.redis_user_secret_manager.id
  secret_string = jsonencode(local.redis_user_credentials)
  depends_on = [aws_elasticache_replication_group.replication_group]
}

#create iam role for redis to retrieve secret
resource "aws_iam_role" "redis_iam_role" {
  name  = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_role.json
}

#create iam policy to allow read access
resource "aws_iam_policy" "read_redis_secret" {
  name   = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-secret-manager-policy"
  policy = data.aws_iam_policy_document.read_secret.json
}

resource "aws_iam_role_policy_attachment" "redis_lambda_basic_execution_role" {
  role   =  aws_iam_role.redis_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "redis_lambda_vpc_access_execution_role" {
  role   =  aws_iam_role.redis_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "redis_lambda_read_secret" {
  role   =  aws_iam_role.redis_iam_role.name
  policy_arn = aws_iam_policy.read_redis_secret.arn
}

#create kms key for vault
resource "aws_kms_key" "redis_cmk_key" {
  description  = "vault unseal key"
  tags = var.tags
}

resource "aws_kms_alias" "redis_cmk_key" {
  name  = "alias/redis-rbac-microservices"
  target_key_id = aws_kms_key.redis_cmk_key.id
}


resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis-subnet-group"
  subnet_ids = slice(module.vpc.private_subnets,0,2 )
  depends_on = [module.vpc]
}

resource "aws_elasticache_replication_group" "replication_group" {
  replication_group_id          = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis-cluster"
  replication_group_description = "Redis cluster for ${var.stack_name}-${random_string.random.result}-${terraform.workspace}"
  apply_immediately = false
  node_type            =  var.redis_node_type
  port                 = local.redis_port
  number_cache_clusters = var.number_of_replicas
  parameter_group_name = var.redis_parameter_group_name
  snapshot_retention_limit =  local.redis_snapshot_retention_limit
  snapshot_window          = var.redis_snapshot_window
  security_group_ids = [aws_security_group.redis.id]
  subnet_group_name = aws_elasticache_subnet_group.redis_subnet_group.name
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  multi_az_enabled = true
  kms_key_id = aws_kms_key.redis_cmk_key.id
  //  cluster_mode {
  //    replicas_per_node_group = 1
  //    num_node_groups         = var.redis_node_group
  //  }
  lifecycle {
    ignore_changes = [number_cache_clusters]
  }
}

resource "aws_elasticache_user" "redis_user" {
  user_id       = var.redis_app_user
  user_name     = var.redis_app_user
  access_string = local.redis_access_string
  engine        = "REDIS"
  passwords     = [random_password.redis_user_password.result]
}

resource "aws_elasticache_user" "redis_user_default" {
  user_id       = "new-default-user"
  user_name     = "default"
  access_string = "off +get ~keys*"
  engine        = "REDIS"
  passwords     = [random_password.redis_user_password.result]
}

resource "aws_elasticache_user_group" "redis_user_group" {
  engine        = "REDIS"
  user_group_id = "${var.stack_name}GroupId"
  user_ids      = [aws_elasticache_user.redis_user.user_id,aws_elasticache_user.redis_user_default.user_id]

}

#define security group for lambda to test
resource "aws_security_group" "lambda" {
  name = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-lambda-sg"
  vpc_id = module.vpc.vpc_id
  description = "security group for lambda"
  tags = merge(
  {
    "Name" = format("%s-lambda-%s-sg",var.stack_name,terraform.workspace),
  },
  var.tags,
  )
}

#define security group for secret manager
resource "aws_security_group" "secret_manager" {
  name = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-secret-manager"
  vpc_id = module.vpc.vpc_id
  description = "security group for secret manager"
  tags = merge(
  {
    "Name" = format("%s-lambda-%s-sg",var.stack_name,terraform.workspace),
  },
  var.tags,
  )
}

#define security group for redis
resource "aws_security_group" "redis" {
  name = "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-redis-sg"
  vpc_id = module.vpc.vpc_id
  description = "security group for redis"
  tags = merge(
  {
    "Name" = format("%s-redis-%s-sg",var.stack_name,terraform.workspace),
  },
  var.tags,
  )
}

resource "aws_security_group_rule" "allow_private_subnets" {
  type        = "ingress"
  from_port   = local.redis_port
  to_port     = local.redis_port
  protocol    = local.any_protocol
  cidr_blocks = flatten([var.private_subnets])
  security_group_id = aws_security_group.redis.id
}

resource "aws_security_group_rule" "lambda_secret" {
  type        = "ingress"
  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.any_protocol
  source_security_group_id = aws_security_group.lambda.id
  security_group_id = aws_security_group.secret_manager.id
}

resource "aws_security_group_rule" "redis_lambda" {
  from_port = local.redis_port
  protocol = local.tcp_protocol
  to_port = local.redis_port
  source_security_group_id = aws_security_group.lambda.id
  security_group_id = aws_security_group.redis.id
  type = "ingress"
}


resource "aws_security_group_rule" "all_outbound_redis" {
  from_port = local.any_port
  protocol = local.any_protocol
  to_port = local.any_port
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.redis.id
  type = "egress"
}

resource "aws_security_group_rule" "all_outbound_lambda" {
  from_port = local.any_port
  protocol = local.any_protocol
  to_port = local.any_port
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.lambda.id
  type = "egress"
}
resource "aws_security_group_rule" "all_outbound_secret_manager" {
  from_port = local.any_port
  protocol = local.any_protocol
  to_port = local.any_port
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.secret_manager.id
  type = "egress"
}

resource "null_resource" "enable_logs" {
  depends_on = [aws_elasticache_replication_group.replication_group]
  provisioner "local-exec" {
    command = <<EOT
    aws elasticache modify-replication-group \
    --replication-group-id ${aws_elasticache_replication_group.replication_group.id} \
    --user-group-ids-to-add ${aws_elasticache_user_group.redis_user_group.id} --region ${var.region}
EOT
  }
}

//data "aws_iam_policy_document" "redis" {
//  statement {
//    sid = "VaultKMSPerm"
//
//    actions = [
//      "kms:Encrypt",
//      "kms:Decrypt",
//      "kms:DescribeKey"
//    ]
//    resources = [
//      "arn:aws:kms:${var.region}::key/*"
//    ]
//  }
//
//}
