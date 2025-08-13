# Terraform AWS docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC
# A Virtual Private Cloud (VPC) is a logically isolated section of the AWS cloud where you can launch AWS resources in a virtual network that you define. You have complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
# It is used for routing traffic between the VPC and the internet.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Subnets
# Subnets are segments of a VPC's IP address range where you can place groups of isolated resources.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true # false by default
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "compute" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.compute_subnet_cidr
  tags = {
    Name = "compute-subnet"
  }
}

resource "aws_subnet" "database" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr
  tags = {
    Name = "database-subnet"
  }
}

# Elastic IP used for the NAT Gateway
# An Elastic IP address is a static IPv4 address designed for dynamic cloud computing. Unlike traditional static IP addresses, which are tied to a specific instance, an Elastic IP address can be associated with any instance in your account, allowing you to quickly remap it to another instance in case of failure or for maintenance purposes. This flexibility is particularly useful in cloud environments where instances may be frequently started, stopped, or replaced.
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html

resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
# A NAT gateway is a managed NAT service that provides network address translation (NAT) for instances in a private subnet. It allows instances in a private subnet to initiate outbound traffic to the internet while preventing unsolicited inbound traffic from reaching those instances. This is particularly useful for scenarios where you want to allow instances in a private subnet to access the internet for updates or external services without exposing them directly to the internet.
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
#
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Public Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html

### Public

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table"
  }
}

# This is needed to allow instances in the public subnet to access the internet, and be accessed via the Internet Gateway. See how we are referencing the Internet Gateway created above, using its ID.
resource "aws_route" "public_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

### Compute

resource "aws_route_table" "compute" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "compute-route-table"
  }
}

# This is needed to allow instances in the compute subnet to access the internet via the NAT Gateway. See how we are referencing the NAT Gateway created above, using its ID, just like the public_access route.
resource "aws_route" "compute_nat_access" {
  route_table_id         = aws_route_table.compute.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "compute_association" {
  subnet_id      = aws_subnet.compute.id
  route_table_id = aws_route_table.compute.id
}

### Database

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "database-route-table"
  }
}

resource "aws_route_table_association" "database_association" {
  subnet_id      = aws_subnet.database.id
  route_table_id = aws_route_table.database.id
}

### Security Groups
# A security group controls the traffic that is allowed to reach and leave the resources that it is associated with. For example, after you associate a security group with an EC2 instance, it controls the inbound and outbound traffic for the instance.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html#

# Public subnet - used for web servers, load balancers
resource "aws_security_group" "public" {
  name_prefix = "public-"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH for management (please restrict this in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

# Compute subnet - used for application servers
resource "aws_security_group" "compute" {
  name_prefix = "compute-"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from public subnet (web -> app)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  # Allow SSH from public subnet for management
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  # Allow all outbound traffic (for internet access via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "compute-sg"
  }
}

# Database subnet
resource "aws_security_group" "database" {
  name_prefix = "database-"
  vpc_id      = aws_vpc.main.id

  # Allow MySQL/PostgreSQL from compute subnet only
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.compute.id]
  }

  # Allow PostgreSQL from compute subnet only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.compute.id]
  }

  tags = {
    Name = "database-sg"
  }
}
