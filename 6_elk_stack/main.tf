data "aws_caller_identity" "current" {}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.base_state_file
  }
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region  = "us-west-2"
  prefix      = "amazon-vpc-traffic-mirroring"
  elk_stack_version     = "7.10"
  elk_stack_volume_size = 10
  elk_stack_volume_type = "gp2"
  elk_stack_instance_type = "m4.large.elasticsearch"
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  remote_state_bucket   = "hands-on-cloud-terraform-remote-state-s3"
  base_state_file       = "amazon-vpc-traffic-monitoring-base.tfstate"
  vpc_id                = data.terraform_remote_state.base.outputs.vpc_id
  elk_domain            = "suricata"
}

data "aws_vpc" "selected" {
  id = local.vpc_id
}

resource "aws_security_group" "es" {
  name        = "${local.prefix}-elk-${local.elk_domain}"
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.selected.cidr_block,
    ]
  }
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = local.elk_domain
  elasticsearch_version = local.elk_stack_version

  cluster_config {
    instance_type          = local.elk_stack_instance_type
  }

  vpc_options {
    subnet_ids = [
      data.terraform_remote_state.base.outputs.private_subnets[1]
    ]

    security_group_ids = [aws_security_group.es.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = local.elk_stack_volume_size
    volume_type = local.elk_stack_volume_type
  }

  tags = local.common_tags

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${local.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.elk_domain}/*"
        }
    ]
}
CONFIG

  depends_on = [aws_iam_service_linked_role.es]
}
