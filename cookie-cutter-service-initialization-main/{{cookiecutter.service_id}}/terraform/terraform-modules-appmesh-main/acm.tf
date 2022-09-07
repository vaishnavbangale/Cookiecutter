resource "aws_acmpca_certificate_authority" "rootcloudmap" {
  count = var.cloudmap_tls_cert_enabled ? 1 : 0
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = var.cloudmap_namespace
      country     = "US"
    }
  }
  type                            = "ROOT"
  permanent_deletion_time_in_days = 7
  tags = merge(
    var.tags,
    {
      terraform-resource = "aws_acmpca_certificate_authority.rootcloudmap"
    }
  )
}

# Issue certificate
resource "aws_acmpca_certificate" "certcloudmap" {
  count                       = var.cloudmap_tls_cert_enabled ? 1 : 0
  certificate_authority_arn   = aws_acmpca_certificate_authority.rootcloudmap[0].arn
  certificate_signing_request = aws_acmpca_certificate_authority.rootcloudmap[0].certificate_signing_request
  signing_algorithm           = "SHA256WITHRSA"
  template_arn                = "arn:aws:acm-pca:::template/RootCACertificate/V1"
  validity {
    type  = var.acmpca_validity_type
    value = var.acmpca_validity_value
  }
}

# ImportCertificateAuthorityCertificate
# Associate a cert with ACMPCA. ACMPCA can't issue cert until it has a certificate associated with it. Root level ACM cert auth is able to self-sign its own root cert.
resource "aws_acmpca_certificate_authority_certificate" "root_cert_cloudmap" {
  count                     = var.cloudmap_tls_cert_enabled ? 1 : 0
  certificate_authority_arn = aws_acmpca_certificate_authority.rootcloudmap[0].arn

  certificate       = aws_acmpca_certificate.certcloudmap[0].certificate
  certificate_chain = aws_acmpca_certificate.certcloudmap[0].certificate_chain
}

# Grant permission for automatic renewal
resource "null_resource" "acm_pca_permission_cloudmap" {
  count = var.cloudmap_tls_cert_enabled ? 1 : 0
  triggers = {
    cert = aws_acmpca_certificate_authority.rootcloudmap[0].arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      ROLE_ARN = var.use_assume_role ? "arn:aws:iam::${split(":", data.aws_caller_identity.current.arn)[4]}:role/${split("/", data.aws_caller_identity.current.arn)[1]}" : ""
    }
    command = <<-EOT
      if [ "$ROLE_ARN" != "" ]
      then
        aws_credentials=$(aws sts assume-role --role-arn $ROLE_ARN --role-session-name "appmesh")
        export AWS_ACCESS_KEY_ID=$(echo $aws_credentials|jq '.Credentials.AccessKeyId'|tr -d '"')
        export AWS_SECRET_ACCESS_KEY=$(echo $aws_credentials|jq '.Credentials.SecretAccessKey'|tr -d '"')
        export AWS_SESSION_TOKEN=$(echo $aws_credentials|jq '.Credentials.SessionToken'|tr -d '"')
      fi
      aws acm-pca create-permission --certificate-authority-arn ${aws_acmpca_certificate_authority.rootcloudmap[0].arn} --actions IssueCertificate GetCertificate ListPermissions --principal acm.amazonaws.com
    EOT
  }

  depends_on = [aws_acmpca_certificate_authority_certificate.root_cert_cloudmap]
}

# Request a managed cert from ACM from private CA issued cert
resource "aws_acm_certificate" "star_cloudmap_domain" {
  count       = var.cloudmap_tls_cert_enabled ? 1 : 0
  domain_name = "*.${var.cloudmap_namespace}"

  certificate_authority_arn = aws_acmpca_certificate_authority.rootcloudmap[0].arn

  tags = merge(
    var.tags,
    {
      Name               = "acm-cert-${var.mesh_name}-${var.region_abbrv}"
      terraform-resource = "aws_acm_certificate.star_cloudmap_domain"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_acmpca_certificate_authority_certificate.root_cert_cloudmap]
}
