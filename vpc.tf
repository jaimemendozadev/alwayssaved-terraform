resource "aws_vpc" "notecasts_vpc" {
  cidr_block           = "10.0.0.0/16" # Defines the private IP range (can hold up to ~65,000 IPs).
  enable_dns_support   = true          # Allows instances in this VPC to resolve DNS hostnames.
  enable_dns_hostnames = true          # Assigns DNS hostnames to instances for easier management.

  tags = {
    Name = "notecasts-vpc"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.notecasts_vpc.id
  cidr_block              = "10.0.1.0/24" # Allocates a smaller chunk of IPs for this subnet (~256 IPs).
  map_public_ip_on_launch = true          # Ensures instances launched in this subnet get a public IP.
  availability_zone       = "us-east-1a"

  tags = {
    Name = "notecasts-public-subnet"
  }
}

resource "aws_security_group" "notecasts_sg" {
  vpc_id = aws_vpc.notecasts_vpc.id

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

  tags = {
    Name = "notecasts-sg"
  }
}