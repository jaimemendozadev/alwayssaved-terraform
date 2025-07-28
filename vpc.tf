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

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.always_saved_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b" # Different AZ from the first subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "always-saved-public-subnet-2"
  }
}

resource "aws_security_group" "always_saved_sg" {
  name        = "always_saved_sg"
  description = "Allow internal access from ALB and internal services"
  vpc_id      = aws_vpc.always_saved_vpc.id

  # Allow SSH for admin access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH (consider restricting in production)"
  }


  # ALLOW port 80 ONLY from the ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow ALB to reach EC2 on port 80"
  }

  # Optional: Allow LLM ↔ frontend access (8000)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow internal app communication on 8000"
  }



  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }


  tags = {
    Name = "always-saved-sg"
  }
}

resource "aws_security_group" "internal_sg" {
  name        = "always-saved-internal-sg"
  description = "Allow EC2 instances to talk to each other"
  vpc_id      = aws_vpc.always_saved_vpc.id

  # Allow all members of this SG to reach each other on 8000
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    self        = true
    description = "Frontend EC2 can talk to LLM EC2 on port 8000"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "always-saved-internal-sg"
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

resource "aws_route_table_association" "always_saved_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.always_saved_rt.id
}



##############################################
# ALB Security Group
##############################################
resource "aws_security_group" "alb_sg" {
  name        = "always-saved-alb-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.always_saved_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "always-saved-alb-sg"
  }
}
