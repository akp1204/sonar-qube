#### ACM certificate #####
resource "aws_acm_certificate" "sonarqube-acm" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

##### ACM validation #####
resource "aws_acm_certificate_validation" "sonarqube-acm-validation" {
  certificate_arn         = aws_acm_certificate.sonarqube-acm.arn
  validation_record_fqdns = [for record in aws_route53_record.sonarqube-record : record.fqdn]
}

##### Data for Hosted zone #####
data "aws_route53_zone" "sonarqube-zone" {
  name         = var.domain_name
  private_zone = false
}

#### A record for ACM certificate ####
resource "aws_route53_record" "sonarqube-record" {
  for_each = {
    for dvo in aws_acm_certificate.sonarqube-acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.sonarqube-zone.zone_id
#  zone_id         = aws_route53_zone.sonarqube-zone.zone_id
}


