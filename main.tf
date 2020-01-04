resource "random_id" "id" {
  byte_length = 8
}

resource "aws_iam_role" "sftp_role" {
  name = "sftp-server-role-${random_id.id.hex}"

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

resource "aws_iam_role_policy" "sftp_role_policy" {
  name = "sftp-server-role-policy-${random_id.id.hex}"
  role = "${aws_iam_role.sftp_role.id}"

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

resource "aws_iam_role" "sftp_auth_role" {
  count = "${var.auth_type == "API_GATEWAY" ? 1 : 0}"
  name = "sftp-server-auth-role-${random_id.id.hex}"

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

resource "aws_iam_role_policy" "sftp_auth_role_policy" {
  count = "${var.auth_type == "API_GATEWAY" ? 1 : 0}"
  name = "sftp-server-auth-role-policy-${random_id.id.hex}"
  role = "${aws_iam_role.sftp_auth_role.0.id}"

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

resource "aws_transfer_server" "pub_sftp" {
  count = "${var.sftp_type == "private" ? 0 : 1}"
  endpoint_type = "PUBLIC"
  
  identity_provider_type = "${var.auth_type}"
  invocation_role        = "${var.auth_type == "API_GATEWAY" ? "${aws_iam_role.sftp_auth_role.0.arn}" : null}"
  url                    = "${var.auth_type == "API_GATEWAY" ? "${var.api_url}" : null}"

  logging_role = "${aws_iam_role.sftp_role.arn}"

  force_destroy = true

  tags = {
    Name = "${var.sftp_server_name}"
    Tier = "public"
  }
}

resource "aws_transfer_server" "pvt_sftp" {
  count = "${var.sftp_type == "private" ? 1 : 0}"
  endpoint_type = "VPC_ENDPOINT"
  endpoint_details {
    vpc_endpoint_id = "${var.vpc_endpoint_id}"
  }

  identity_provider_type = "${var.auth_type}"
  invocation_role        = "${var.auth_type == "API_GATEWAY" ? "${aws_iam_role.sftp_auth_role.0.arn}" : null}"
  url                    = "${var.auth_type == "API_GATEWAY" ? "${var.api_url}" : null}"

  logging_role = "${aws_iam_role.sftp_role.arn}"

  force_destroy = true

  tags = {
    Name = "${var.sftp_server_name}"
    Tier = "private"
  }
}

locals {
  sftp_server_id = "${var.sftp_type == "private" ? aws_transfer_server.pvt_sftp.0.id : aws_transfer_server.pub_sftp.0.id}"
  sftp_server_ep = "${var.sftp_type == "private" ? aws_transfer_server.pvt_sftp.0.endpoint : aws_transfer_server.pub_sftp.0.endpoint}"
}

data "aws_route53_zone" "hosted_zone" {
  name = "${var.root_hosted_zone}"
}

resource "aws_route53_record" "sftp_record" {
  zone_id = "${data.aws_route53_zone.hosted_zone.zone_id}"
  name    = "${var.sftp_domain}.${var.root_hosted_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${local.sftp_server_ep}"]
}

resource "aws_iam_role" "sftp_user_role" {
  count              = "${length(var.sftp_users)}"
  name               = "sftp-user-iam-role-${var.sftp_users[count.index]}"
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

resource "aws_iam_role_policy" "sftp_user_policy" {
  count = "${length(var.sftp_users)}"
  name  = "sftp-user-iam-role-policy-${var.sftp_users[count.index]}"
  role  = "${aws_iam_role.sftp_user_role[count.index].id}"

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
                "arn:aws:s3:::${join("", slice(split("/", var.sftp_user_home_dir[count.index]), 0, 1))}"
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
            "Resource": "arn:aws:s3:::${trimsuffix(var.sftp_user_home_dir[count.index], "/")}/*"
        }
    ]
}
POLICY
}

resource "aws_transfer_user" "sftp_user" {
  count          = "${length(var.sftp_users)}"
  server_id      = "${local.sftp_server_id}"
  user_name      = "${var.sftp_users[count.index]}"
  home_directory = "/${var.sftp_user_home_dir[count.index]}"
  role           = "${aws_iam_role.sftp_user_role[count.index].arn}"
}

resource "aws_transfer_ssh_key" "foo" {
  count     = "${length(var.sftp_users)}"
  server_id = "${local.sftp_server_id}"
  user_name = "${aws_transfer_user.sftp_user[count.index].user_name}"
  body      = "${var.sftp_user_ssh_key[count.index]}"
}
