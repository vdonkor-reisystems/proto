module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"
  name                 =  "${var.stack_name}-${random_string.random.result}-${terraform.workspace}-vpc"
  cidr                 =  var.vpc_cidr_block
  azs                  = data.aws_availability_zones.available.names
  private_subnets      =  var.private_subnets
  public_subnets       =  var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags = var.tags
}
//resource "aws_vpc_endpoint" "secretsmanager" {
//  service_name = data.aws_vpc_endpoint_service.secrets_manager.service_name
//  vpc_id = module.vpc.vpc_id
////  security_group_ids = [aws_security_group.secret_manager.id]
//}