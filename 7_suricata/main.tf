data "aws_caller_identity" "current" {}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.base_state_file
  }
}

data "terraform_remote_state" "elk" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key = local.elk_state_file
  }
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region  = "us-west-2"
  prefix      = "amazon-vpc-traffic-mirroring"
  suricata_ec2_volume_size = 30
  suricata_ec2_volume_type = "gp3"
  suricata_ec2_volume_encryption = true
  suricata_ec2_instance_type = "t3.small"
  common_tags = {
    Project         = local.prefix
    ManagedBy       = "Terraform"
  }
  remote_state_bucket   = "hands-on-cloud-terraform-remote-state-s3"
  base_state_file       = "amazon-vpc-traffic-monitoring-base.tfstate"
  elk_state_file        = "amazon-vpc-traffic-monitoring-elk.tfstate"
  es_version            = "${data.terraform_remote_state.elk.outputs.es_version}.0"
  es_endpoint           = data.terraform_remote_state.elk.outputs.es_endpoint
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

# EC2 Suricata Instance Profile

resource "aws_iam_instance_profile" "suricata" {
  name = "${local.prefix}-ec2-suricata-instance-profile"
  role = aws_iam_role.suricata.name
}

resource "aws_iam_role" "suricata" {
  name = "${local.prefix}-ec2-suricata-role"
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

resource "aws_iam_policy_attachment" "suricata" {
  name       = "${local.prefix}-ec2-suricata-role-attachment"
  roles      = [aws_iam_role.suricata.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 Suricata instance

resource "aws_network_interface" "suricata" {
  subnet_id   = data.terraform_remote_state.base.outputs.private_subnets[1]
  private_ips = ["10.0.2.101"]
}

resource "aws_instance" "suricata" {
  ami                  = data.aws_ami.ubuntu_latest.id
  instance_type        = local.suricata_ec2_instance_type
  availability_zone    = "${local.aws_region}b"
  iam_instance_profile = aws_iam_instance_profile.suricata.name

  network_interface {
    network_interface_id = aws_network_interface.suricata.id
    device_index         = 0
  }

  user_data = <<EOF
#!/bin/bash
eni_name=`ip route get 1.0.0.0 | awk '{print $5}'` #ens5
ip link set $eni_name multicast off
ip link set $eni_name promisc on
ip link set $eni_name up
apt-get update
apt-get -y install ca-certificates curl gnupg lsb-release git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io
ELK_VERSION="${local.es_version}"
docker pull ubuntu
docker pull docker.elastic.co/logstash/logstash-oss:$ELK_VERSION
git clone https://github.com/andreivmaksimov/grIDS.git
cd grIDS/docker/logstash
sed -i "s/localhost:9200/https:\/\/${local.es_endpoint}:443/g" beats_to_elastic.conf
docker build -t logstash .
docker run -d --hostname=logstash --name=logstash --network="host" --restart always -t logstash
cd ../suricata
sed -i "s/enp8s0/$eni_name/g" suricata.yaml
docker build -t suricata .
docker run -d --network=host --cap-add=net_admin --cap-add=sys_nice --hostname=suricata --name=suricata --restart always suricata
docker ps -a
EOF

  root_block_device {
    encrypted = local.suricata_ec2_volume_encryption
    volume_size = local.suricata_ec2_volume_size
    volume_type = local.suricata_ec2_volume_type
  }

  tags = {
    Name = "${local.prefix}-ec2-suricata"
  }
}
