provider "aws" {
  region = "ap-southeast-1"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "aap_vpc" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "aap_vpc"
  }
}

# -----------------------
# Internet Gateway for public subnet
# -----------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aap_vpc.id
  tags = {
    Name = "aap_igw"
  }
}

# -----------------------
# Public Subnet
# -----------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.aap_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

# -----------------------
# Private Subnet
# -----------------------
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.aap_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "private_subnet"
  }
}

# -----------------------
# NAT Gateway for private subnet
# -----------------------
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "nat_gw"
  }
}

# -----------------------
# Route Tables
# -----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aap_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aap_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------
# Security Group
# -----------------------
resource "aws_security_group" "aap_sg" {
  name        = "aap_sg"
  description = "Allow SSH and all traffic within security group"
  vpc_id      = aws_vpc.aap_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aap_sg"
  }
}

# -----------------------
# SSH Key Pair
# -----------------------
resource "aws_key_pair" "default" {
  key_name   = "aap-dr-test-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# -----------------------
# Variables and Locals
# -----------------------
variable "common_tags" {
  default = {
    Project = "AAP 2.5"
  }
}

locals {
  instance_type = "t3.xlarge" # 4vCPU, 16GB RAM
  ami_id        = "ami-04698733964af06d5" # FROM AWS 
}

# -----------------------
# EC2 Instances
# -----------------------

# Platform Gateway - Public subnet
resource "aws_instance" "pgw" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "pgw" })
}

# Control Nodes - Private subnet
resource "aws_instance" "control" {
  count                       = 1
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 80
  }

  tags = merge(var.common_tags, { Name = "control-${count.index + 1}" })
}

# Automation Hub - Private subnet
resource "aws_instance" "automation_hub" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "automation_hub" })
}

# Database - Private subnet
resource "aws_instance" "database" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 100
  }

  tags = merge(var.common_tags, { Name = "database" })
}

# Event Driven Ansible Controller - Private subnet
resource "aws_instance" "eda" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "eda" })
}

# Execution Nodes (2) - Private subnet
resource "aws_instance" "execution_nodes" {
  count                       = 2
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "execution_node-${count.index + 1}" })
}
