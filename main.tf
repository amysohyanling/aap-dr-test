provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "aap_vpc" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "aap_subnet" {
  vpc_id                  = aws_vpc.aap_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

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
}

variable "common_tags" {
  default = {
    Project = "AAP 2.5"
  }
}

locals {
  instance_type = "t3.xlarge" # 4vCPU, 16GB RAM
  ami_id        = "ami-0abcdef1234567890" # Replace with your RHEL 8 AMI ID
}

# Platform Gateway
resource "aws_instance" "pgw" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 60
  }
  tags = merge(var.common_tags, { Name = "pgw" })
}

# Control Nodes (3)
resource "aws_instance" "control" {
  count                       = 3
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 80
  }
  tags = merge(var.common_tags, { Name = "control-${count.index + 1}" })
}

# Automation Hub
resource "aws_instance" "automation_hub" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 60
  }
  tags = merge(var.common_tags, { Name = "automation_hub" })
}

# Database
resource "aws_instance" "database" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 100
  }
  tags = merge(var.common_tags, { Name = "database" })
}

# Event Driven Ansible Controller
resource "aws_instance" "eda" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 60
  }
  tags = merge(var.common_tags, { Name = "eda" })
}

# Execution Nodes (2)
resource "aws_instance" "execution_nodes" {
  count                       = 2
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.aap_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = "your-ssh-key"
  root_block_device {
    volume_size = 60
  }
  tags = merge(var.common_tags, { Name = "execution_node-${count.index + 1}" })
}
