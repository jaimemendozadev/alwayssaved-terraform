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