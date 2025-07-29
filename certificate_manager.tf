resource "aws_acm_certificate" "frontend_ssl_cert" {
  domain_name       = "alwayssaved.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.alwayssaved.com"
  ]

  tags = {
    Name = "alwayssaved-frontend-ssl-cert"
  }
}

resource "aws_route53_record" "cert_dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend_ssl_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300

}

resource "aws_acm_certificate_validation" "cert_validation_complete" {
  certificate_arn         = aws_acm_certificate.frontend_ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_dns_validation : record.fqdn]
}


resource "aws_acm_certificate" "llm_ssl_cert" {
  domain_name       = "llm.alwayssaved.com"
  validation_method = "DNS"

  tags = {
    Name = "alwayssaved-llm-cert"
  }
}

resource "aws_route53_record" "llm_cert_dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.llm_ssl_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "llm_cert_validation" {
  certificate_arn = aws_acm_certificate.llm_ssl_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.llm_cert_dns_validation : record.fqdn
  ]
}