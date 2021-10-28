locals {
  demo_ec2_instance_type = "t3.micro"
}

# Latest Ubuntu 20.04 AMI

data "aws_ami" "ubuntu_latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# EC2 demo Instance Profile

resource "aws_iam_instance_profile" "ec2_demo" {
  name = "${local.prefix}-ec2-demo-instance-profile"
  role = aws_iam_role.ec2_demo.name
}

resource "aws_iam_role" "ec2_demo" {
  name = "${local.prefix}-ec2-demo-role"
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
  name       = "${local.prefix}-ec2-demo-role-attachment"
  roles      = [aws_iam_role.ec2_demo.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 demo instance

resource "aws_network_interface" "ec2_demo" {
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.0.1.101"]
}

resource "aws_instance" "ec2_demo" {
  ami                  = data.aws_ami.ubuntu_latest.id
  instance_type        = local.demo_ec2_instance_type
  availability_zone    = "${local.aws_region}a"
  iam_instance_profile = aws_iam_instance_profile.ec2_demo.name

  network_interface {
    network_interface_id = aws_network_interface.ec2_demo.id
    device_index         = 0
  }

  tags = {
    Name = "${local.prefix}-ec2-demo"
  }
}
