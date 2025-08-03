variable "frontend_ami_id" {
  type = string
}

variable "frontend_instance_type" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "frontend_vpc_security_group_ids" {
  type = list(string)
}

variable "frontend_instance_profile_name" {
  type = string
}

variable "aws_pub_key_name" {
  type = string
}

variable "aws_ecr_frontend_service_url" {
  type = string
}