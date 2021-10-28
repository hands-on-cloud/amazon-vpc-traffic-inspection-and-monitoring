terraform {
  backend "s3" {
    bucket = "hands-on-cloud-terraform-remote-state-s3"
    key = "amazon-vpc-traffic-monitoring-mirroring.tfstate"
    region = "us-west-2"
    encrypt = "true"
  }
}
