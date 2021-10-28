locals {
  aws_region  = "us-west-2"
  prefix      = "amazon-vpc-traffic-mirroring"
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  remote_state_bucket = "hands-on-cloud-terraform-remote-state-s3"
  base_state_file      = "amazon-vpc-traffic-monitoring-base.tfstate"
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.base_state_file
  }
}

# Enable VPC Subnet Flow Log

resource "aws_flow_log" "subnet" {
  log_destination      = data.terraform_remote_state.base.outputs.logging_s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  subnet_id            = data.terraform_remote_state.base.outputs.private_subnets[0]
}
