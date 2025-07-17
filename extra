provider "aws" {
  region = "ap-southeast-2"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "aap_vpc_ap2" {
  cidr_block = "10.20.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "aap_vpc-ap2"
  }
}

# -----------------------
# Internet Gateway for public subnet
# -----------------------
resource "aws_internet_gateway" "igw_ap2" {
  vpc_id = aws_vpc.aap_vpc_ap2.id
  tags = {
    Name = "aap_igw-ap2"
  }
}

# -----------------------
# Public Subnet
# -----------------------
resource "aws_subnet" "public_subnet_ap2" {
  vpc_id                  = aws_vpc.aap_vpc_ap2.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet-ap2"
  }
}

# -----------------------
# Private Subnet
# -----------------------
resource "aws_subnet" "private_subnet_ap2" {
  vpc_id            = aws_vpc.aap_vpc_ap2.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "private_subnet-ap2"
  }
}

# -----------------------
# NAT Gateway for private subnet
# -----------------------
resource "aws_eip" "nat_eip_ap2" {
  domain = "vpc"
  tags = {
    Name = "nat_eip-ap2"
  }
}

resource "aws_nat_gateway" "nat_gw_ap2" {
  allocation_id = aws_eip.nat_eip_ap2.id
  subnet_id     = aws_subnet.public_subnet_ap2.id
  tags = {
    Name = "nat_gw-ap2"
  }
}

# -----------------------
# Route Tables
# -----------------------
resource "aws_route_table" "public_rt_ap2" {
  vpc_id = aws_vpc.aap_vpc_ap2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_ap2.id
  }
  tags = {
    Name = "public_rt-ap2"
  }
}

resource "aws_route_table_association" "public_assoc_ap2" {
  subnet_id      = aws_subnet.public_subnet_ap2.id
  route_table_id = aws_route_table.public_rt_ap2.id
}

resource "aws_route_table" "private_rt_ap2" {
  vpc_id = aws_vpc.aap_vpc_ap2.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_ap2.id
  }
  tags = {
    Name = "private_rt-ap2"
  }
}

resource "aws_route_table_association" "private_assoc_ap2" {
  subnet_id      = aws_subnet.private_subnet_ap2.id
  route_table_id = aws_route_table.private_rt_ap2.id
}

# -----------------------
# Security Group
# -----------------------
resource "aws_security_group" "aap_sg_ap2" {
  name        = "aap_sg_ap2"
  description = "Allow SSH and all traffic within security group"
  vpc_id      = aws_vpc.aap_vpc_ap2.id

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
    Name = "aap_sg-ap2"
  }
}

# -----------------------
# Variables and Locals
# -----------------------
variable "common_tags" {
  default = {
    Project = "AAP 2.5 AP2"
  }
}

locals {
  instance_type = "t3.xlarge"
  ami_id        = "ami-0705fe1e9a50e0d57"
}

# -----------------------
# EC2 Instances
# -----------------------
resource "aws_instance" "pgw_ap2" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.public_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "pgw-ap2" })
}

resource "aws_instance" "control_ap2" {
  count                  = 1
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 80
  }

  tags = merge(var.common_tags, { Name = "control-ap2-${count.index + 1}" })
}

resource "aws_instance" "automation_hub_ap2" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "automation_hub-ap2" })
}

resource "aws_instance" "database_ap2" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 100
  }

  tags = merge(var.common_tags, { Name = "database-ap2" })
}

resource "aws_instance" "eda_ap2" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "eda-ap2" })
}

resource "aws_instance" "execution_nodes_ap2" {
  count                  = 2
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private_subnet_ap2.id
  vpc_security_group_ids = [aws_security_group.aap_sg_ap2.id]
  key_name               = "aap-dr-key-pair-2"

  root_block_device {
    volume_size = 60
  }

  tags = merge(var.common_tags, { Name = "execution_node-ap2-${count.index + 1}" })
}
