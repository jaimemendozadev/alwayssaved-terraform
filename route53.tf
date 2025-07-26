resource "aws_route53_record" "app_alias" {
  zone_id = var.route53_zone_id
  name    = "alwayssaved.com"
  type    = "A"

  alias {
    name                   = aws_lb.alwayssaved_alb.dns_name
    zone_id                = aws_lb.alwayssaved_alb.zone_id
    evaluate_target_health = true
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_route53_record" "app_alias_www" {
  zone_id = var.route53_zone_id
  name    = "www.alwayssaved.com"
  type    = "A"

  alias {
    name                   = aws_lb.alwayssaved_alb.dns_name
    zone_id                = aws_lb.alwayssaved_alb.zone_id
    evaluate_target_health = true
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}
