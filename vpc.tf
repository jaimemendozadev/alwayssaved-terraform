############################################
# VPC
############################################
resource "aws_vpc" "always_saved_vpc" {
  cidr_block           = "10.0.0.0/16" # Defines the private IP range (can hold up to ~65,000 IPs).
  enable_dns_support   = true          # Allows instances in this VPC to resolve DNS hostnames.
  enable_dns_hostnames = true          # Assigns DNS hostnames to instances for easier management.

  tags = {
    Name = "always-saved-vpc"
  }
}






############################################
# Internet Gateway
############################################

resource "aws_internet_gateway" "always_saved_igw" {
  vpc_id = aws_vpc.always_saved_vpc.id

  tags = {
    Name = "always-saved-igw"
  }
}






############################################
# Public Subnets
############################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.always_saved_vpc.id
  cidr_block              = "10.0.1.0/24" # Allocates a smaller chunk of IPs for this subnet (~256 IPs).
  map_public_ip_on_launch = true          # Ensures instances launched in this subnet get a public IP.
  availability_zone       = "us-east-1a"

  tags = {
    Name = "always-saved-public-subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.always_saved_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b" # Different AZ from the first subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "always-saved-public-subnet-2"
  }
}




############################################
# Route Tables
############################################

resource "aws_route_table" "always_saved_rt" {
  vpc_id = aws_vpc.always_saved_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.always_saved_igw.id
  }

  tags = {
    Name = "always-saved-route-table"
  }
}

resource "aws_route_table_association" "always_saved_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.always_saved_rt.id
}

resource "aws_route_table_association" "always_saved_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.always_saved_rt.id
}