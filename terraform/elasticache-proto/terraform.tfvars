remote_state_bucket_name = "remote_state_bucket_name"
#define any tags appropriate to your environment
tags = {
  Owner = "cloud-automation"
  MaintainedBy = "CloudProfessionals"
  Project = "Portfolio"
}
redis_node_type = "cache.t3.small"
number_of_replicas = 2
#specify vpc cidr
vpc_cidr_block = "10.220.0.0/16"

#define private subnet to use
private_subnets = ["10.220.48.0/20","10.220.64.0/20","10.220.80.0/20"]

#define public subnets to use. Note you must specify at least two subnets
public_subnets = ["10.220.0.0/20","10.220.16.0/20","10.220.32.0/20"]

#enter the region in which your aws resources will be provisioned
region = "us-east-1"

#specify your aws credential profile. Note this is not IAM role but rather profile configured during AWS CLI installation
profile = "cloud"

#specify the name you will like to call this project.
stack_name = "cloud"

