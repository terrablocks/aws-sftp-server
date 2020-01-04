output "sftp_id" {
  value = "${local.sftp_server_id}"
}

output "sftp_endpoint" {
  value = "${local.sftp_server_ep}"
}

output "sftp_domain_name" {
  value = "${aws_route53_record.sftp_record.fqdn}"
}
