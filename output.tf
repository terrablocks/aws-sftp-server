output "arn" {
  value       = aws_transfer_server.this.arn
  description = "ARN of transfer server"
}

output "id" {
  value       = local.server_id
  description = "ID of transfer server"
}

output "endpoint" {
  value       = local.server_ep
  description = "Endpoint of transfer server"
}

output "domain_name" {
  value       = var.hosted_zone == null ? null : join(",", aws_route53_record.sftp.*.fqdn)
  description = "Custom DNS name mapped in Route53 for transfer server"
}

output "sftp_sg_id" {
  value       = var.sftp_type == "VPC" && length(lookup(var.endpoint_details, "security_group_ids", [])) == 0 ? join(",", aws_security_group.sftp_vpc.*.id) : null
  description = "ID of security group created for SFTP server if of type VPC and security group is not provided by you"
}
