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
  type = string
  default = "os-builder-arm64"
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
    name = "architecture"
    values = ["arm64"]
  }

  owners = ["309956199498"] # amazon
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

output "public_ip" {
  value = aws_instance.lab_rhel.public_ip
}
