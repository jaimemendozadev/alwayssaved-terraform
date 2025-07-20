##############################################
# Common Variables
##############################################
variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_pub_key_name" {
  description = "AWS Public Key File Name"
  type        = string
}

variable "aws_s3_code_bucket_name" {
  description = "AWS s3 Code Bucket Name"
  type        = string
}
##############################################




##############################################
# Extractor Service Variables
##############################################
variable "ubuntu_ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "aws_instance_type" {
  description = "AWS Instance Type"
  type        = string
}

variable "aws_ecr_extractor_service_url" {
  description = "AWS ECR Url for Extractor Service"
  type        = string
}


##############################################




##############################################
# Embedding Service Variables
##############################################

variable "embedding_ami_id" {
  description = "ami ID for Embedding Service"
  type        = string
}

variable "embedding_instance_type" {
  description = "AWS Instance Type for Embedding Service"
  type        = string
}

variable "aws_ecr_embedding_service_url" {
  description = "AWS ECR Url for Embedding Service"
}

##############################################





##############################################
# LLM Service Variables
##############################################
variable "llm_service_ami_id" {
  description = "ami ID for LLM Service"
  type        = string
}

variable "llm_service_instance_type" {
  description = "AWS Instance Type for LLM Service"
  type        = string
}

variable "aws_ecr_llm_service_url" {
  description = "AWS ECR Url for LLM Service"
  type        = string
}

##############################################




##############################################
# Next.js Frontend Variables
##############################################
variable "frontend_ami_id" {
  description = "ami ID for Next.js Frontend"
  type        = string

}

variable "frontend_instance_type" {
  description = "AWS Instance Type for Next.js Frontend"
  type        = string
}

variable "aws_ecr_frontend_service_url" {
  description = "AWS ECR Url for Next.js Frontend"
  type        = string
}

##############################################


