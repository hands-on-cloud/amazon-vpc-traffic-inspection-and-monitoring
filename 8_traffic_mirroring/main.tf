data "aws_caller_identity" "current" {}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.base_state_file
  }
}

data "terraform_remote_state" "suricata" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.suricata_state_file
  }
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region  = "us-west-2"
  prefix      = "amazon-vpc-traffic-mirroring"
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  remote_state_bucket   = "hands-on-cloud-terraform-remote-state-s3"
  base_state_file       = "amazon-vpc-traffic-monitoring-base.tfstate"
  suricata_state_file   = "amazon-vpc-traffic-monitoring-suricata.tfstate"
  flow_logs_table_name  = "vpc_flow_logs"
  flow_logs_s3_bucket_arn = data.terraform_remote_state.base.outputs.logging_s3_bucket_arn
  flow_logs_s3_bucket_name = data.terraform_remote_state.base.outputs.logging_s3_bucket_name
}

resource "aws_ec2_traffic_mirror_filter" "filter" {}

resource "aws_ec2_traffic_mirror_filter_rule" "https" {
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "10.0.0.0/8"
  rule_number              = 100
  rule_action              = "accept"
  traffic_direction        = "egress"
  protocol                 = 6

  destination_port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_ec2_traffic_mirror_target" "suricata" {
  network_interface_id = data.terraform_remote_state.suricata.outputs.suricata_interface_id
}

resource "aws_ec2_traffic_mirror_session" "demo_ec2" {
  network_interface_id     = data.terraform_remote_state.base.outputs.demo_ec2_interface_id
  session_number           = 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.suricata.id
}
