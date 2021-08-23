variable "tags" {
  description = "tags to associate with resources provisioned"
  type = map(string)
}
variable "stack_name" {
  description = "name of the project"
  type = string
}
variable "region" {
  description = "aws region to deploy"
  type = string
}
variable "profile" {
  description = "iam user profile to use"
  type = string
}

variable "redis_app_user" {
  type = string
  description = "the name of redis user, this will be the application/microservice name"
  default = "app"
}

variable "redis_app_group" {
  type = string
  description = "the name of the redis group, this will be the group that has redis user"
  default = "app-group"
}
variable "redis_node_type" {
  type = string
  description = "redis instance type"
}
variable "redis_parameter_group_name" {
  type = string
  description = "choose a parameter group name to control whether you have a single shard or cluster"
  default = "default.redis6.x"
}
variable "redis_snapshot_window" {
  description = "time window for automated snapshot"
  default = "00:00-05:00"
}
variable "number_of_replicas" {
  type = number
  description = "number of cache clusters. Note this number must much the number of az available"
}
variable "remote_state_bucket_name" {
  type = string
  description = "bucket name for the terraform remote state"
}
variable "vpc_cidr_block" {
  description = "CIDR Block for this  VPC. Example 10.0.0.0/16"
  default = "10.10.0.0/16"
  type = string
}
variable "public_subnets" {
  description = "Provide list of public subnets to use in this VPC. Example 10.0.1.0/24,10.0.2.0/24"
  default     = []
  type = list(string)
}
variable "private_subnets" {
  description = "Provide list private subnets to use in this VPC. Example 10.0.10.0/24,10.0.11.0/24"
  default     = []
  type = list(string)
}
variable "availability_zones" {
  description = "list of availability zones to use"
  type = list(string)
  default = []
}