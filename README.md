<!-- BEGIN_TF_DOCS -->
# Create a managed public or internal facing SFTP server using AWS Transfer service

![License](https://img.shields.io/github/license/terrablocks/aws-sftp-server?style=for-the-badge) ![Tests](https://img.shields.io/github/actions/workflow/status/terrablocks/aws-sftp-server/tests.yml?branch=main&label=Test&style=for-the-badge) ![Checkov](https://img.shields.io/github/actions/workflow/status/terrablocks/aws-sftp-server/checkov.yml?branch=main&label=Checkov&style=for-the-badge) ![Commit](https://img.shields.io/github/last-commit/terrablocks/aws-sftp-server?style=for-the-badge) ![Release](https://img.shields.io/github/v/release/terrablocks/aws-sftp-server?style=for-the-badge)

This terraform module will deploy the following services:
- IAM
  - Role
  - Role Policy
- Route53
  - DNS Record
- Transfer
  - Server
  - User
  - SSH Key

# Usage Instructions
## Example
```hcl
module "sftp" {
  source = "github.com/terrablocks/aws-sftp-server.git" # Always use `ref` to point module to a specific version or hash
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 5.13.1 |
| random | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| api_gw_url | URL of the service endpoint to authenticate users when `identity_provider_type` is of type `API_GATEWAY` | `string` | `null` | no |
| as2_transports | Transport method to use for AS2 messages. **Valid values:** `HTTP` | `set(string)` | `null` | no |
| certificate_arn | ARN of ACM certificate. Required only in case of FTPS protocol | `string` | `null` | no |
| cloudwatch_log_group_arns | Set of ARN of the CloudWatch log group to which SFTP server will write JSON logs. Required if `enable_json_logging` is set to `true` | `set(string)` | `[]` | no |
| directory_id | ID of the directory service to authenticate users when `identity_provider_type` is of type `AWS_DIRECTORY_SERVICE` | `string` | `null` | no |
| endpoint_details | A block required to setup SFTP server if type is set to `VPC` or `VPC_ENDPOINT` ```{ vpc_id = (Optional) ID of VPC in which SFTP server endpoint will be hosted. Required if endpoint type is set to VPC vpc_endpoint_id = (Optional) The ID of VPC endpoint to use for hosting internal SFTP server. Required if endpoint type is set to VPC_ENDPOINT subnet_ids = (Optional) List of subnets ids within the VPC for hosting SFTP server endpoint. Required if endpoint type is set to VPC security_group_ids = (Optional) List of security groups to attach to the SFTP endpoint. Supported only if endpoint is to type VPC. If left blank for VPC, a security group with port 22 open to the world will be created and attached address_allocation_ids = (Optional) List of address allocation IDs to attach an Elastic IP address to your SFTP server endpoint. Supported only if endpoint type is set to VPC. If left blank for VPC, an EIP will be automatically created per subnet and attached }``` | ```object({ vpc_id = optional(string) vpc_endpoint_id = optional(string) subnet_ids = optional(list(string)) security_group_ids = optional(list(string)) address_allocation_ids = optional(list(string)) })``` | `{}` | no |
| force_destroy | Whether to delete all the users associated with server so that server can be deleted successfully. **Note:** Supported only if `identity_provider_type` is set to `SERVICE_MANAGED` | `bool` | `true` | no |
| function_arn | ARN of the lambda function to authenticate users when `identity_provider_type` is of type `AWS_LAMBDA` | `string` | `null` | no |
| host_key | RSA private key that will be used to identify your server when clients connect to it over SFTP | `string` | `null` | no |
| hosted_zone | Hosted zone name to create DNS entry for SFTP server | `string` | `null` | no |
| identity_provider_type | Mode of authentication to use for accessing the service. **Valid Values:** `SERVICE_MANAGED`, `API_GATEWAY`, `AWS_DIRECTORY_SERVICE` or `AWS_LAMBDA` | `string` | `"SERVICE_MANAGED"` | no |
| invocation_role | ARN of the IAM role to authenticate the user when `identity_provider_type` is set to `API_GATEWAY` | `string` | `null` | no |
| logging_role | ARN of an IAM role to allow to write SFTP users activity to Amazon CloudWatch logs | `string` | `null` | no |
| name | Name of SFTP server. Ignore it to generate a random name for server | `string` | `null` | no |
| passive_ip | Use passive IP (PASV) capability to attach the IP address of the firewall or the load balancer to your FTPS/FTP server | `string` | `null` | no |
| post_authentication_login_banner | Message to display to user when trying to connect to the server **after** authentication | `string` | `null` | no |
| pre_authentication_login_banner | Message to display to user when trying to connect to the server **before** authentication | `string` | `null` | no |
| protocols | List of file transfer protocol(s) over which your FTP client can connect to your server endpoint. **Possible Values:** FTP, FTPS and SFTP | `list(string)` | ```[ "SFTP" ]``` | no |
| security_policy_name | Specifies the name of the [security policy](https://docs.aws.amazon.com/transfer/latest/userguide/security-policies.html) to associate with the server | `string` | `"TransferSecurityPolicy-2023-05"` | no |
| set_stat_option | Whether the server should ignore SETSTAT command. **Valid values:** `DEFAULT`, `ENABLE_NO_OP` | `string` | `null` | no |
| sftp_sub_domain | DNS name for SFTP server. **NOTE: Only sub-domain name required. DO NOT provide entire URL** | `string` | `"sftp"` | no |
| sftp_type | Type of SFTP server. **Valid values:** `PUBLIC`, `VPC` or `VPC_ENDPOINT` | `string` | `"PUBLIC"` | no |
| sftp_users | Map of users with key as username and value as their home directory. Home directory is the S3 bucket path which user should have access to ```{ user = home_dir_path }``` | `map(string)` | `{}` | no |
| sftp_users_ssh_key | Map of users with key as username and value as their public SSH key ```{ user = ssh_public_key_content }``` | `map(string)` | `{}` | no |
| storage_type | Where to store the files. **Valid values:** `S3` or `EFS` | `string` | `"S3"` | no |
| tags | A map of key value pair to assign to resources | `map(string)` | `{}` | no |
| tls_session_resumption_mode | TLS session resumption mode provides a mechanism to resume recently negotiated encrypted TLS sessions between the client and the FTPS server. Using one of the TLS session resumption modes, you can customize how you want to your FTPS server to process TLS session resumption requests | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | ARN of transfer server |
| domain_name | Custom DNS name mapped in Route53 for transfer server |
| endpoint | Endpoint of transfer server |
| id | ID of transfer server |
| sftp_eip | Elastic IP attached to the SFTP server. Available only if SFTP type is VPC and allocation id is not provided by you |
| sftp_sg_id | ID of security group created for SFTP server. Available only if SFTP type is VPC and security group is not provided by you |


<!-- END_TF_DOCS -->
