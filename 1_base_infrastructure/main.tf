locals {
  aws_region  = "us-west-2"
  prefix      = "amazon-vpc-traffic-mirroring"
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  vpc_cidr = var.vpc_cidr
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.prefix}-vpc"
  cidr = local.vpc_cidr

  azs             = ["${local.aws_region}a", "${local.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true
  enable_vpn_gateway      = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
