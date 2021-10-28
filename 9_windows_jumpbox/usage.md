# Jumpbox Windows EC2 instance to get access to Elasticsearch Kibana 

This is a demo repository for the [How to inspect VPC, subnet, and EC2 instance traffic in AWS](https://hands-on.cloud/how-to-inspect-vpc-subnet-and-ec2-instance-traffic-in-aws/) article.

This module sets up the following AWS services:

* EC2

Google Chrome is automatically installed to the instance using [Chocolatey](https://chocolatey.org/).

![Base infrastructure](img/Windows-Jumpbox.png)

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
