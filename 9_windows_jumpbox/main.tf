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
  windows_instance_ami  = "ami-058b12f51d412b5db"
  ssh_key_name          = "Lenovo-T410"
}

locals {
  demo_ec2_instance_type = "t3.small"
}

# EC2 demo Instance Profile

resource "aws_iam_instance_profile" "ec2_windows_jumpbox" {
  name = "${local.prefix}-ec2-windows-jumpbox-instance-profile"
  role = aws_iam_role.ec2_windows_jumpbox.name
}

resource "aws_iam_role" "ec2_windows_jumpbox" {
  name = "${local.prefix}-ec2-windows-jumpbox-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Allow Systems Manager to manage EC2 instance

resource "aws_iam_policy_attachment" "ec2" {
  name       = "${local.prefix}-windows-jumpbox-role-attachment"
  roles      = [aws_iam_role.ec2_windows_jumpbox.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 demo instance

resource "aws_security_group" "rdp" {
  name        = "${local.prefix}-rdp"
  description = "Allow RDP inbound traffic"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress = [
    {
      description      = "RDP"
      from_port        = 3389
      to_port          = 3389
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
      description      = "ALL Traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_network_interface" "ec2_windows_jumpbox" {
  subnet_id   = data.terraform_remote_state.base.outputs.public_subnets[1]
  private_ips = ["10.0.102.101"]
  security_groups = [aws_security_group.rdp.id]
}

resource "aws_instance" "ec2_windows_jumpbox" {
  ami                  = local.windows_instance_ami
  instance_type        = local.demo_ec2_instance_type
  availability_zone    = "${local.aws_region}b"
  iam_instance_profile = aws_iam_instance_profile.ec2_windows_jumpbox.name

  network_interface {
    network_interface_id = aws_network_interface.ec2_windows_jumpbox.id
    device_index         = 0
  }

  user_data = <<EOF
<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n=allowGlobalConfirmation
choco install googlechrome
</powershell>
EOF

  key_name = local.ssh_key_name

  tags = {
    Name = "${local.prefix}-ec2-windows-jumpbox"
  }
}
