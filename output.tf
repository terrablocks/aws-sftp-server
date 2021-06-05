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
