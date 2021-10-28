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
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  remote_state_bucket   = "hands-on-cloud-terraform-remote-state-s3"
  base_state_file       = "amazon-vpc-traffic-monitoring-base.tfstate"
  flow_logs_table_name  = "vpc_flow_logs"
  flow_logs_s3_bucket_arn = data.terraform_remote_state.base.outputs.logging_s3_bucket_arn
  flow_logs_s3_bucket_name = data.terraform_remote_state.base.outputs.logging_s3_bucket_name
}

resource "aws_athena_workgroup" "vpc_flow_logs" {
  name = "${local.prefix}-vpc-flow-logs"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_location.bucket}/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  force_destroy = true
}

resource "aws_athena_database" "vpc_flow_logs" {
  name   = replace("${local.prefix}-vpc-flow-logs", "-", "_")
  bucket = aws_s3_bucket.query_location.bucket
  force_destroy = true
}

resource "aws_athena_named_query" "vpc_flow_logs_create_table" {
  name      = "${local.prefix}-vpc-flow-logs-create-table-query"
  workgroup = aws_athena_workgroup.vpc_flow_logs.id
  database  = aws_athena_database.vpc_flow_logs.name
  query     = <<QUERY

CREATE EXTERNAL TABLE IF NOT EXISTS ${local.flow_logs_table_name} (
  version int,
  account string,
  interfaceid string,
  sourceaddress string,
  destinationaddress string,
  sourceport int,
  destinationport int,
  protocol int,
  numpackets int,
  numbytes bigint,
  starttime int,
  endtime int,
  action string,
  logstatus string,
  vpcid string,
  subnetid string,
  instanceid string,
  tcpflags int,
  type string,
  pktsrcaddr string,
  pktdstaddr string,
  region string,
  azid string,
  sublocationtype string,
  sublocationid string,
  pktsrcawsservice string,
  pktdstawsservice string,
  flowdirection string,
  trafficpath string
)
PARTITIONED BY (aws_region string, day string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION 's3://${local.flow_logs_s3_bucket_name}/AWSLogs/${local.aws_account_id}/vpcflowlogs/${local.aws_region}/'
TBLPROPERTIES
(
  "skip.header.line.count"="1",
  "projection.enabled" = "true",
  "projection.aws_region.type" = "enum",
  "projection.aws_region.values" = "us-west-2",
  "projection.day.type" = "date",
  "projection.day.range" = "2021/01/01,NOW",
  "projection.day.format" = "yyyy/MM/dd",
  "storage.location.template" = "s3://${local.flow_logs_s3_bucket_name}/AWSLogs/${local.aws_account_id}/vpcflowlogs/$${aws_region}/$${day}"
)

QUERY

}

resource "aws_athena_named_query" "vpc_flow_logs_query" {
  name      = "${local.prefix}-vpc-flow-logs-query"
  workgroup = aws_athena_workgroup.vpc_flow_logs.id
  database  = aws_athena_database.vpc_flow_logs.name
  query     = "SELECT * FROM ${local.flow_logs_table_name} WHERE day > '2021/10/25' limit 20;"
}
