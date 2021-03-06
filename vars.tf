variable "sftp_type" {
  default = "public"
}
variable "sftp_server_name" {
  default = "sftp-server"
}
variable "vpc_endpoint_id" {
  default = null
}
variable "auth_type" {
  default = "SERVICE_MANAGED"
}
variable "api_url" {
  default = null
}
variable "root_hosted_zone" {}
variable "sftp_domain" {
  default = "sftp"
}
variable "sftp_users" {
  type = list(any)
}
variable "sftp_user_home_dir" {
  type = list(any)
}
variable "sftp_user_ssh_key" {
  type = list(any)
}
