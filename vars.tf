variable "name" {
  type        = string
  default     = null
  description = "Name of SFTP server. Ignore it to generate a random name for server"
}

variable "sftp_type" {
  type        = string
  default     = "PUBLIC"
  description = "Type of SFTP server. **Valid values:** PUBLIC or VPC"
}

variable "protocols" {
  type        = list(string)
  default     = ["SFTP"]
  description = "List of file transfer protocol(s) over which your FTP client can connect to your server endpoint. **Possible Values:** FTP, FTPS and SFTP"
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "ARN of ACM certificate. Required only in case of FTPS protocol"
}

variable "endpoint_details" {
  type = object({
    vpc_id                 = string
    subnet_ids             = list(string)
    address_allocation_ids = list(string)
  })
  default     = null
  description = <<-EOT
    A block required to setup internal or public facing SFTP server endpoint within a VPC
    ```{
      vpc_id                 = ID of VPC in which SFTP server endpoint will be hosted
      subnet_ids             = List of subnets ids within the VPC for hosting SFTP server endpoint
      address_allocation_ids = List of address allocation IDs to attach an Elastic IP address to your SFTP server endpoint
    }```
  EOT
}

variable "identity_provider_type" {
  type        = string
  default     = "SERVICE_MANAGED"
  description = "Mode of authentication to use for accessing the service. **Valid Values:** SERVICE_MANAGED or API_GATEWAY"
}

variable "api_gw_url" {
  type        = string
  default     = null
  description = "URL of the service endpoint to authenticate users when `identity_provider_type` is of type `API_GATEWAY`"
}

variable "invocation_role" {
  type        = string
  default     = null
  description = "ARN of the IAM role to authenticate the user when `identity_provider_type` is set to `API_GATEWAY`"
}

variable "logging_role" {
  type        = string
  default     = null
  description = "ARN of an IAM role to allow to write your SFTP users’ activity to Amazon CloudWatch logs"
}

variable "force_destroy" {
  type        = bool
  default     = true
  description = "Whether to delete all the users associated with server so that server can be deleted successfully"
}

variable "security_policy_name" {
  type        = string
  default     = "TransferSecurityPolicy-2018-11"
  description = "Specifies the name of the [security policy](https://docs.aws.amazon.com/transfer/latest/userguide/security-policies.html) to associate with the server. **Possible values:** TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06 or TransferSecurityPolicy-FIPS-2020-06"
}

variable "host_key" {
  type        = string
  default     = null
  description = "RSA private key that will be used to identify your server when clients connect to it over SFTP"
}

variable "hosted_zone" {
  type        = string
  default     = null
  description = "Hosted zone name to create DNS entry for SFTP server"
}

variable "sftp_sub_domain" {
  type        = string
  default     = "sftp"
  description = "DNS name for SFTP server. **NOTE: Only sub-domain required. DO NOT provide entire URL**"
}

variable "sftp_users" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Map of users with key as username and value as their home directory
    ```{
      user = home_dir_path
    }```
  EOT
}

variable "sftp_users_ssh_key" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Map of users with key as username and value as their public SSH key
    ```{
      user = ssh_public_key_content
    }```
  EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of key value pair to assign to resources"
}
