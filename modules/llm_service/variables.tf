variable "llm_service_ami_id" {
    type = string
}

variable "llm_service_instance_type" {
    type = string
}

variable "public_subnet_id" {
    type = string
}

variable "llm_service_vpc_security_group_ids" {
    type = list(string)
}

variable "llm_service_iam_instance_profile" {
    type = string
}

variable "aws_pub_key_name" {
    type = string
}

variable "aws_ecr_llm_service_url" {
    type = string
}