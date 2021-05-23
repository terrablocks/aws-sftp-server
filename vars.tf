variable "sftp_type" {
  default = "public"
}

variable "name" {}

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
  type    = map(any)
  default = {}
}

variable "sftp_user_ssh_key" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}
