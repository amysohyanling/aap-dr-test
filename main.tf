# provider "aws" {
#   region = "ap-southeast-1"
# }

# # -----------------------
# # VPC
# # -----------------------
# resource "aws_vpc" "aap_vpc" {
#   cidr_block = "10.10.0.0/16"
#   enable_dns_support = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "aap_vpc"
#   }
# }

# # -----------------------
# # Internet Gateway for public subnet
# # -----------------------
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.aap_vpc.id
#   tags = {
#     Name = "aap_igw"
#   }
# }

# # -----------------------
# # Public Subnet
# # -----------------------
# resource "aws_subnet" "public_subnet" {
#   vpc_id                  = aws_vpc.aap_vpc.id
#   cidr_block              = "10.10.1.0/24"
#   availability_zone       = "ap-southeast-1a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "public_subnet"
#   }
# }

# # -----------------------
# # Private Subnet
# # -----------------------
# resource "aws_subnet" "private_subnet" {
#   vpc_id            = aws_vpc.aap_vpc.id
#   cidr_block        = "10.10.2.0/24"
#   availability_zone = "ap-southeast-1a"
#   tags = {
#     Name = "private_subnet"
#   }
# }

# # -----------------------
# # NAT Gateway for private subnet
# # -----------------------
# resource "aws_eip" "nat_eip" {
#   domain = "vpc"
#   tags = {
#     Name = "nat_eip"
#   }
# }

# resource "aws_nat_gateway" "nat_gw" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnet.id
#   tags = {
#     Name = "nat_gw"
#   }
# }

# # -----------------------
# # Route Tables
# # -----------------------
# resource "aws_route_table" "public_rt" {
#   vpc_id = aws_vpc.aap_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
#   tags = {
#     Name = "public_rt"
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_route_table" "private_rt" {
#   vpc_id = aws_vpc.aap_vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gw.id
#   }
#   tags = {
#     Name = "private_rt"
#   }
# }

# resource "aws_route_table_association" "private_assoc" {
#   subnet_id      = aws_subnet.private_subnet.id
#   route_table_id = aws_route_table.private_rt.id
# }

# # -----------------------
# # Security Group
# # -----------------------
# resource "aws_security_group" "aap_sg" {
#   name        = "aap_sg"
#   description = "Allow SSH and all traffic within security group"
#   vpc_id      = aws_vpc.aap_vpc.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     self            = true
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "aap_sg"
#   }
# }

# # -----------------------
# # SSH Key Pair
# # -----------------------
# # resource "aws_key_pair" "default" {
# #   key_name   = "aap-dr-test-key"
# #   public_key = file("~/.ssh/id_rsa.pub")
# # }

# # -----------------------
# # Variables and Locals
# # -----------------------
# variable "common_tags" {
#   default = {
#     Project = "AAP 2.5"
#   }
# }

# locals {
#   instance_type = "t3.xlarge" # 4vCPU, 16GB RAM
#   ami_id        = "ami-04698733964af06d5" # FROM AWS 
# }

# # -----------------------
# # EC2 Instances
# # -----------------------

# # Platform Gateway - Public subnet
# resource "aws_instance" "pgw" {
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.public_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"

#   root_block_device {
#     volume_size = 60
#   }

#   tags = merge(var.common_tags, { Name = "pgw" })
# }

# # Control Nodes - Private subnet
# resource "aws_instance" "control" {
#   count                       = 1
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.private_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"

#   root_block_device {
#     volume_size = 80
#   }

#   tags = merge(var.common_tags, { Name = "control-${count.index + 1}" })
# }

# # Automation Hub - Private subnet
# resource "aws_instance" "automation_hub" {
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.private_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"

#   root_block_device {
#     volume_size = 60
#   }

#   tags = merge(var.common_tags, { Name = "automation_hub" })
# }

# # Database - Private subnet
# resource "aws_instance" "database" {
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.private_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"


#   root_block_device {
#     volume_size = 100
#   }

#   tags = merge(var.common_tags, { Name = "database" })
# }

# # Event Driven Ansible Controller - Private subnet
# resource "aws_instance" "eda" {
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.private_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"

#   root_block_device {
#     volume_size = 60
#   }

#   tags = merge(var.common_tags, { Name = "eda" })
# }

# # Execution Nodes (2) - Private subnet
# resource "aws_instance" "execution_nodes" {
#   count                       = 2
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = aws_subnet.private_subnet.id
#   vpc_security_group_ids      = [aws_security_group.aap_sg.id]
#   key_name                    = "aap-dr-key-pair"

#   root_block_device {
#     volume_size = 60
#   }

#   tags = merge(var.common_tags, { Name = "execution_node-${count.index + 1}" })
# }


#========================================================================================
provider "aws" {
  region = "ap-southeast-1"
}

# -----------------------
# VPC
# -----------------------
resource "aws_vpc" "aap_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "aap_vpc" }
}

# -----------------------
# Internet Gateway for public subnet
# -----------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aap_vpc.id
  tags = { Name = "aap_igw" }
}

# -----------------------
# Public Subnet (LB lives here)
# -----------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.aap_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public_subnet" }
}

# -----------------------
# Private Subnet (all app/db/ee live here)
# -----------------------
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.aap_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "ap-southeast-1a"
  tags = { Name = "private_subnet" }
}

# -----------------------
# NAT Gateway for private subnet
# -----------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = { Name = "nat_eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = { Name = "nat_gw" }
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
  tags = { Name = "public_rt" }
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
  tags = { Name = "private_rt" }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------------
# Security Group (simple: SSH+HTTP+HTTPS from anywhere; all egress)
# For production, split LB/app/db SGs and restrict SSH to your IP.
# -----------------------
resource "aws_security_group" "aap_sg" {
  name        = "aap_sg"
  description = "Allow SSH/HTTP/HTTPS and all intra-SG traffic"
  vpc_id      = aws_vpc.aap_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic within the same SG (node-to-node)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aap_sg" }
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
  instance_type = "t3.xlarge"            # 4 vCPU, 16 GB RAM
  ami_id        = "ami-04698733964af06d5" # make sure this AMI exists in ap-southeast-1
  key_name      = "aap-dr-key-pair"       # must pre-exist or create via aws_key_pair
}

# -----------------------
# EC2 Instances (5 total)
# -----------------------

# 1) HAProxy Load Balancer - Public subnet (has public IP)
resource "aws_instance" "lb" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = local.key_name

  root_block_device { volume_size = 40 }

  tags = merge(var.common_tags, { Name = "haproxy-lb" })
}

# 2–3) AAP App Component Nodes (PGW + Controller + Hub + EDA) - Private subnet
resource "aws_instance" "app_nodes" {
  count                       = 2
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = local.key_name

  # No public IPs in private subnet; outbound via NAT
  root_block_device { volume_size = 100 } # a bit larger to host multiple AAP components

  tags = merge(var.common_tags, { Name = "aap-app-${count.index + 1}" })
}

# 4) Dedicated Database Node - Private subnet
resource "aws_instance" "database" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = local.key_name

  root_block_device { volume_size = 120 }

  tags = merge(var.common_tags, { Name = "aap-database" })
}

# 5) Execution Node - Private subnet
resource "aws_instance" "execution_node" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.aap_sg.id]
  key_name                    = local.key_name

  root_block_device { volume_size = 60 }

  tags = merge(var.common_tags, { Name = "aap-execution" })
}
