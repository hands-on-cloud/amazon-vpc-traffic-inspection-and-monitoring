output "vpc_id" {
  value = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnets" {
  value = module.vpc.public_subnets
  description = "VPC public subnets' IDs list"
}

output "private_subnets" {
  value = module.vpc.private_subnets
  description = "VPC private subnets' IDs list"
}

output "logging_s3_bucket_name" {
  value = aws_s3_bucket.logging.bucket
  description = "Logging S3 bucket name"
}

output "logging_s3_bucket_arn" {
  value = aws_s3_bucket.logging.arn
  description = "Logging S3 Bucket ARN"
}

output "demo_ec2_interface_id" {
  value = aws_network_interface.ec2_demo.id
  description = "Demo EC2 instance network interface (ENI) ID"
}
