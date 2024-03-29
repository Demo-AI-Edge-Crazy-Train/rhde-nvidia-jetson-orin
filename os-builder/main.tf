terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

variable "tag_name" {
  type    = string
  default = "os-builder-arm64"
}

variable "route53_zone" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

data "aws_ami" "rhel" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.3.0_HVM-*-arm64-*-Hourly2-GP3"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  owners = ["309956199498"] # amazon
}

resource "aws_iam_policy" "s3_policy" {
  name        = "WriteAccessToS3Bucket"
  description = "Policy to let the EC2 instance access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ],
        Effect = "Allow",
      },
    ],
  })

  tags = {
    Name = var.tag_name
  }
}

resource "aws_iam_role" "ec2_s3_access_role" {
  name = "AssumesWriteAccessToS3Bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Principal = { "Service" : "ec2.amazonaws.com" },
        Effect    = "Allow",
        Sid       = "",
      },
    ],
  })

  tags = {
    Name = var.tag_name
  }
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Ec2AssumesWriteAccessToS3Bucket"
  role = aws_iam_role.ec2_s3_access_role.name

  tags = {
    Name = var.tag_name
  }
}

resource "aws_vpc" "lab_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.tag_name
  }
}

resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "172.16.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = var.tag_name
  }
}

resource "aws_route_table" "lab_route" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_gw.id
  }

  tags = {
    Name = var.tag_name
  }
}

resource "aws_route_table_association" "lab_rta" {
  subnet_id      = aws_subnet.lab_subnet.id
  route_table_id = aws_route_table.lab_route.id
}

resource "aws_security_group" "lab_rhel" {
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    description = "Incoming SSH connection"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Incoming HTTP connection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outgoing connections"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.tag_name
  }
}

resource "aws_internet_gateway" "lab_gw" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = {
    Name = var.tag_name
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "os-builder admin"
  public_key = file("~/.ssh/id_ed25519.pub")
  tags = {
    Name = var.tag_name
  }
}

resource "aws_instance" "lab_rhel" {
  ami                         = data.aws_ami.rhel.id
  instance_type               = "m6g.2xlarge"
  key_name                    = aws_key_pair.admin.key_name
  subnet_id                   = aws_subnet.lab_subnet.id
  depends_on                  = [aws_internet_gateway.lab_gw]
  vpc_security_group_ids      = [aws_security_group.lab_rhel.id]
  user_data                   = filebase64("cloud-init/user-data.yaml")
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = var.tag_name
  }
}

resource "aws_eip" "lab_eip" {
  instance = aws_instance.lab_rhel.id
  vpc      = true

  tags = {
    Name = var.tag_name
  }
}

data "aws_route53_zone" "lab_zone" {
  name         = var.route53_zone
  private_zone = false
}

resource "aws_route53_record" "os_builder_a_record" {
  zone_id = data.aws_route53_zone.lab_zone.zone_id
  name    = "os-builder.${var.route53_zone}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.lab_eip.public_ip]
}

output "public_ip" {
  value = aws_instance.lab_rhel.public_ip
}
