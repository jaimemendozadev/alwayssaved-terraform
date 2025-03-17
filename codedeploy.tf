resource "aws_codedeploy_app" "notecasts" {
  name = "notecasts-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "notecasts" {
  app_name              = aws_codedeploy_app.notecasts.name
  deployment_group_name = "notecasts-deployment-group"
  service_role_arn      = aws_iam_role.notecasts_codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "notecasts-audio-extractor"
    }
  }

  autoscaling_groups = []
}
