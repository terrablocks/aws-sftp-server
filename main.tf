resource "random_pet" "sftp" {
  length    = 2
  separator = "-"
}

locals {
  name = var.name == null ? random_pet.sftp.id : var.name
}

resource "aws_iam_role" "logging" {
  count = var.logging_role == null ? 1 : 0
  name  = "${local.name}-transfer-logging"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "logging" {
  count = var.logging_role == null ? 1 : 0
  name  = "${local.name}-transfer-logging"
  role  = join(",", aws_iam_role.logging.*.id)

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "auth" {
  count = var.identity_provider_type == "API_GATEWAY" ? 1 : 0
  name  = "${local.name}-api-gateway-auth"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "auth" {
  count = var.identity_provider_type == "API_GATEWAY" ? 1 : 0
  name  = "${local.name}-api-gateway-auth"
  role  = join(",", aws_iam_role.auth.*.id)

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_transfer_server" "this" {
  # checkov:skip=CKV_AWS_164: Exposing server publicly depends on user
  endpoint_type = var.sftp_type
  protocols     = var.protocols
  certificate   = var.certificate_arn

  dynamic "endpoint_details" {
    for_each = length(var.endpoint_details) == 0 ? [] : [var.endpoint_details]
    content {
      vpc_id                 = lookup(endpoint_details.value, "vpc_id", null)
      subnet_ids             = lookup(endpoint_details.value, "subnet_ids", null)
      address_allocation_ids = lookup(endpoint_details.value, "address_allocation_ids", null)
    }
  }

  identity_provider_type = var.identity_provider_type
  url                    = var.api_gw_url
  invocation_role        = var.invocation_role

  logging_role         = var.logging_role == null ? join(",", aws_iam_role.logging.*.arn) : var.logging_role
  force_destroy        = var.force_destroy
  security_policy_name = var.security_policy_name
  host_key             = var.host_key

  tags = merge({
    Name = local.name
  }, var.tags)
}

locals {
  server_id = aws_transfer_server.this.id
  server_ep = aws_transfer_server.this.endpoint
}

data "aws_route53_zone" "primary" {
  count = var.hosted_zone == null ? 0 : 1
  name  = var.hosted_zone
}

resource "aws_route53_record" "sftp" {
  count   = var.hosted_zone == null ? 0 : 1
  zone_id = join(",", data.aws_route53_zone.primary.*.zone_id)
  name    = "${var.sftp_sub_domain}.${var.hosted_zone}"
  type    = "CNAME"
  ttl     = "60"
  records = [local.server_ep]
}

resource "aws_iam_role" "user" {
  for_each           = var.sftp_users
  name               = "${local.name}-sftp-user-${each.key}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "user" {
  for_each = var.sftp_users
  name     = "${local.name}-sftp-user-${each.key}"
  role     = aws_iam_role.user[each.key].id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListingOfUserFolder",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::$${Transfer:HomeBucket}"
      ]
    },
    {
      "Sid": "HomeDirObjectAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObjectVersion",
        "s3:DeleteObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::${trimsuffix(each.value, "/")}/*"
    }
  ]
}
POLICY
}

resource "aws_transfer_user" "this" {
  for_each       = var.sftp_users
  server_id      = local.server_id
  user_name      = each.key
  home_directory = "/${each.value}"
  role           = aws_iam_role.user[each.key].arn
  tags           = merge({ User = each.key }, var.tags)
}

resource "aws_transfer_ssh_key" "this" {
  for_each  = var.sftp_users_ssh_key
  server_id = local.server_id
  user_name = each.key
  body      = each.value
}
