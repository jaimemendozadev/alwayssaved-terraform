#################################################
# SES Domain Identity (Sending: alwayssaved.com)
#################################################

# This resource is IMPORTED, not created fresh — the identity already
# exists in AWS (currently "Unverified") because it was made manually
# in the console. Run this BEFORE terraform apply:
#
#   terraform import aws_ses_domain_identity.alwayssaved alwayssaved.com
#
# ---------------------------------------------------------------------
# READ ME IF "terraform destroy" EVER FAILS ON THIS RESOURCE:
#
# prevent_destroy below is intentional, not a bug. SES domain
# verification takes several minutes to re-propagate through DNS every
# time it's torn down and recreated. Since this project gets destroyed
# and rebuilt often during dev, this flag stops THIS resource (and only
# this one) from being wiped out along with the EC2/SQS/ALB stuff.
#
# If you actually want to delete this for good (e.g. retiring the
# domain, or migrating SES to a different AWS account):
#   1. Remove the `lifecycle { prevent_destroy = true }` block below
#   2. Run `terraform apply` once (no infra changes, just updates state
#      to drop the protection)
#   3. THEN `terraform destroy` will be able to remove it
#
# Until you do that, `terraform destroy` will error out specifically on
# this resource and stop — that's the safety working as intended, not
# something broken. No other resources are affected by that error.
# ---------------------------------------------------------------------
resource "aws_ses_domain_identity" "alwayssaved" {
  domain = "alwayssaved.com"

  lifecycle {
    prevent_destroy = true
  }
}

#################################################
# DKIM — proves mail genuinely came from us
#################################################

resource "aws_ses_domain_dkim" "alwayssaved" {
  domain = aws_ses_domain_identity.alwayssaved.domain
}

resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.alwayssaved.dkim_tokens[count.index]}._domainkey.alwayssaved.com"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.alwayssaved.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

#################################################
# Domain ownership verification (the TXT record AWS checks
# to flip "Unverified" -> "Verified")
#################################################

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.alwayssaved.com"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.alwayssaved.verification_token]
}

# Tells Terraform to actually wait/poll until AWS confirms verification
# succeeded, instead of just creating the records and moving on blind.
resource "aws_ses_domain_identity_verification" "alwayssaved_verification" {
  domain     = aws_ses_domain_identity.alwayssaved.id
  depends_on = [aws_route53_record.ses_verification]
}

#################################################
# SPF — declares SES as an authorized sender for our domain
#
# NOTE: when Google Workspace MX records get added later (for receiving
# support email), this record must be EDITED to a single combined TXT,
# e.g. "v=spf1 include:amazonses.com include:_spf.google.com ~all"
# A domain can only have ONE spf TXT record — never two separate ones.
#################################################

resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = "alwayssaved.com"
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}
