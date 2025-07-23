resource "aws_vpc" "always_saved_vpc" {
  cidr_block           = "10.0.0.0/16" # Defines the private IP range (can hold up to ~65,000 IPs).
  enable_dns_support   = true          # Allows instances in this VPC to resolve DNS hostnames.
  enable_dns_hostnames = true          # Assigns DNS hostnames to instances for easier management.

  tags = {
    Name = "always-saved-vpc"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.always_saved_vpc.id
  cidr_block              = "10.0.1.0/24" # Allocates a smaller chunk of IPs for this subnet (~256 IPs).
  map_public_ip_on_launch = true          # Ensures instances launched in this subnet get a public IP.
  availability_zone       = "us-east-1a"

  tags = {
    Name = "always-saved-public-subnet"
  }
}

resource "aws_security_group" "always_saved_sg" {
  vpc_id = aws_vpc.always_saved_vpc.id

  # Allow inbound SSH from GitHub Actions
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 🔴 Might have to change this later for security
  }


  # Allow inbound HTTP/HTTPS for API
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow from within your VPC
  }

  tags = {
    Name = "always-saved-sg"
  }
}

resource "aws_internet_gateway" "always_saved_igw" {
  vpc_id = aws_vpc.always_saved_vpc.id

  tags = {
    Name = "always-saved-igw"
  }
}

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