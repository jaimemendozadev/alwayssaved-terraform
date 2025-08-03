
module "llm_service" {
  source                             = "./modules/llm_service"
  llm_service_ami_id                 = var.llm_service_ami_id
  llm_service_instance_type          = var.llm_service_instance_type
  public_subnet_id                   = aws_subnet.public_subnet.id                                     # TODO: Refactor subnet?
  llm_service_vpc_security_group_ids = [aws_security_group.llm_ec2_sg.id]                              # TODO: Refactor security groups?
  llm_service_iam_instance_profile   = aws_iam_instance_profile.always_saved_llm_instance_profile.name #TODO: Refactor IAM instance profile?
  aws_pub_key_name                   = var.aws_pub_key_name
  aws_ecr_llm_service_url            = var.aws_ecr_llm_service_url

}


module "frontend_service" {
  source                          = "./modules/frontend_service"
  frontend_ami_id                 = var.frontend_ami_id
  public_subnet_id                = aws_subnet.public_subnet.id                                                # TODO: Refactor subnet?
  frontend_vpc_security_group_ids = [aws_security_group.always_saved_sg.id, aws_security_group.internal_sg.id] # TODO: Refactor security groups?
  frontend_instance_profile_name  = aws_iam_instance_profile.always_saved_frontend_instance_profile.name       #TODO: Refactor IAM instance profile?
  frontend_instance_type          = var.frontend_instance_type
  aws_pub_key_name                = var.aws_pub_key_name
  aws_ecr_frontend_service_url    = var.aws_ecr_frontend_service_url
}


# 8/3/25 TODO: Start implementing output module values that need to be used in root project file resources.