# Base infrastructure - VPC, subnets, EC2 instance, Logging S3 bucket 

This is a demo repository for the [How to inspect VPC, subnet, and EC2 instance traffic in AWS](https://hands-on.cloud/how-to-inspect-vpc-subnet-and-ec2-instance-traffic-in-aws/) article.

This module sets up the following AWS services:

* VPC (2 private, 2 public subnets, NAT Gateway)
* Demo EC2 instance
* Systems Manager - Session Manager (to manager EC2 instances)
* Amazon Guard Duty
* Logging S3 bucket (to store VPC Flow Logs)

![Base infrastructure](../4_interface_logging/Base-infrastructure.png)

## Deployment

```sh
terraform init
terraform plan
terraform apply -auto-approve
```

## Tier down

```sh
terraform destroy -auto-approve
```
