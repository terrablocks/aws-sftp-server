resource "aws_iam_role" "sftp_logging" {
  name = "${var.name}-transfer-logging"

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

resource "aws_iam_role_policy" "sftp_logging" {
  name = "${var.name}-transfer-logging"
  role = aws_iam_role.sftp_logging.id

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

resource "aws_iam_role" "sftp_auth" {
  count = var.auth_type == "API_GATEWAY" ? 1 : 0
  name  = "${var.name}-api-gateway-auth"

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

resource "aws_iam_role_policy" "sftp_auth" {
  count = var.auth_type == "API_GATEWAY" ? 1 : 0
  name  = "${var.name}-api-gateway-auth-role-policy"
  role  = join(",", aws_iam_role.sftp_auth.*.id)

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

resource "aws_transfer_server" "public" {
  count         = var.sftp_type == "private" ? 0 : 1
  endpoint_type = "PUBLIC"

  identity_provider_type = var.auth_type
  invocation_role        = var.auth_type == "API_GATEWAY" ? join(",", aws_iam_role.sftp_auth.*.arn) : null
  url                    = var.auth_type == "API_GATEWAY" ? var.api_url : null

  logging_role = aws_iam_role.sftp_logging.arn

  force_destroy = true

  tags = merge({
    Name = var.name
  }, var.tags)
}

resource "aws_transfer_server" "private" {
  count         = var.sftp_type == "private" ? 1 : 0
  endpoint_type = "VPC_ENDPOINT"

  endpoint_details {
    vpc_endpoint_id = var.vpc_endpoint_id
  }

  identity_provider_type = var.auth_type
  invocation_role        = var.auth_type == "API_GATEWAY" ? join(",", aws_iam_role.sftp_auth.*.arn) : null
  url                    = var.auth_type == "API_GATEWAY" ? var.api_url : null

  logging_role = aws_iam_role.sftp_logging.arn

  force_destroy = true

  tags = merge({
    Name = var.name
  }, var.tags)
}

locals {
  sftp_server_id = var.sftp_type == "private" ? join(",", aws_transfer_server.private.*.id) : join(",", aws_transfer_server.public.*.id)
  sftp_server_ep = var.sftp_type == "private" ? join(",", aws_transfer_server.private.*.endpoint) : join(",", aws_transfer_server.public.*.endpoint)
}

data "aws_route53_zone" "primary" {
  name = var.root_hosted_zone
}

resource "aws_route53_record" "sftp_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.sftp_domain}.${var.root_hosted_zone}"
  type    = "CNAME"
  ttl     = "60"
  records = [local.sftp_server_ep]
}

resource "aws_iam_role" "sftp_user" {
  for_each           = var.sftp_users
  name               = "${var.name}-sftp-user-${each.key}"
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

resource "aws_iam_role_policy" "sftp_user" {
  for_each = var.sftp_users
  name     = "${var.name}-sftp-user-${each.key}"
  role     = aws_iam_role.sftp_user[each.key].id

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
                "arn:aws:s3:::${join("", slice(split("/", each.value), 0, 1))}"
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

resource "aws_transfer_user" "sftp" {
  for_each       = var.sftp_users
  server_id      = local.sftp_server_id
  user_name      = each.key
  home_directory = "/${each.value}"
  role           = aws_iam_role.sftp_user[count.index].arn
  tags           = merge({ User = each.key }, var.tags)
}

resource "aws_transfer_ssh_key" "sftp" {
  for_each  = var.sftp_users
  server_id = local.sftp_server_id
  user_name = each.key
  body      = each.value
}
