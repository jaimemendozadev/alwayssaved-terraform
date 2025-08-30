##############################################
# AlwaysSaved Security Group
##############################################

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

##############################################
# Internal Security Group
##############################################


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

##############################################
# LLM ALB Security Group
##############################################


resource "aws_security_group" "llm_alb_sg" {
  name        = "always-saved-llm-alb-sg"
  description = "Allow HTTPS traffic to LLM ALB"
  vpc_id      = aws_vpc.always_saved_vpc.id

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
    Name = "always-saved-llm-alb-sg"
  }
}



##############################################
# LLM ec2 Security Group
##############################################

resource "aws_security_group" "llm_ec2_sg" {
  name        = "always-saved-llm-ec2-sg"
  description = "Allow HTTPS (port 8000) from the LLM ALB to the LLM EC2"
  vpc_id      = aws_vpc.always_saved_vpc.id

  # Allow inbound from the LLM ALB on port 8000
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.llm_alb_sg.id]
    description     = "Allow LLM ALB to reach LLM EC2 on port 8000"
  }

  # Allow SSH (optional — for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for admin"
  }

  # Outbound: allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "always-saved-llm-ec2-sg"
  }
}
