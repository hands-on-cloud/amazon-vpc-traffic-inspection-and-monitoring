# Suricata EC2 instance For Traffic Analysis 

This is a demo repository for the [How to inspect VPC, subnet, and EC2 instance traffic in AWS](https://hands-on.cloud/how-to-inspect-vpc-subnet-and-ec2-instance-traffic-in-aws/) article.

This module sets up the following AWS services:

* EC2

Deploying [Suricata](https://suricata.io/) Docker container in EC2 instance to alert mirrored traffic flows incidents.

Configuring Filebeat OSS and Logstash OSS for sending alerts to Elasticsearch.

![Base infrastructure](img/Suricata.png)

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
