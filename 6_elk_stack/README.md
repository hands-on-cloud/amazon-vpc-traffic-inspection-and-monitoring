<!-- BEGIN_TF_DOCS -->

# Elasticksearch For Traffic Analysis 

This is a demo repository for the [How to inspect VPC, subnet, and EC2 instance traffic in AWS](https://hands-on.cloud/how-to-inspect-vpc-subnet-and-ec2-instance-traffic-in-aws/) article.

This module sets up the following AWS services:

* Elasticsearch

![Base infrastructure](img/Elasticsearch.png)

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
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
## Resources

| Name | Type |
|------|------|
| [aws_elasticsearch_domain.es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticsearch_domain) | resource |
| [aws_iam_service_linked_role.es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_security_group.es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [terraform_remote_state.base](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_es_arn"></a> [es\_arn](#output\_es\_arn) | n/a |
| <a name="output_es_domain_id"></a> [es\_domain\_id](#output\_es\_domain\_id) | n/a |
| <a name="output_es_domain_name"></a> [es\_domain\_name](#output\_es\_domain\_name) | n/a |
| <a name="output_es_endpoint"></a> [es\_endpoint](#output\_es\_endpoint) | n/a |
| <a name="output_es_version"></a> [es\_version](#output\_es\_version) | n/a |
| <a name="output_kibana_endpoint"></a> [kibana\_endpoint](#output\_kibana\_endpoint) | n/a |

<!-- END_TF_DOCS -->