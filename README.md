# Create a managed public or internal facing SFTP server using AWS Transfer service

![License](https://img.shields.io/github/license/terrablocks/aws-sftp-server?style=for-the-badge) ![Tests](https://img.shields.io/github/workflow/status/terrablocks/aws-sftp-server/tests/main?label=Test&style=for-the-badge) ![Checkov](https://img.shields.io/github/workflow/status/terrablocks/aws-sftp-server/checkov/main?label=Checkov&style=for-the-badge) ![Commit](https://img.shields.io/github/last-commit/terrablocks/aws-sftp-server?style=for-the-badge) ![Release](https://img.shields.io/github/v/release/terrablocks/aws-sftp-server?style=for-the-badge)

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
```terraform
module "sftp" {
  source = "github.com/terrablocks/aws-sftp-server.git"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15 |
| aws | >= 3.37.0 |
| random | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of SFTP server. Ignore it to generate a random name for server | `string` | `null` | no |
| sftp_type | Type of SFTP server. **Valid values:** PUBLIC, VPC or VPC_ENDPOINT | `string` | `"PUBLIC"` | no |
| protocols | List of file transfer protocol(s) over which your FTP client can connect to your server endpoint. **Possible Values:** FTP, FTPS and SFTP | `list(string)` | <pre>[<br>  "SFTP"<br>]</pre> | no |
| certificate_arn | ARN of ACM certificate. Required only in case of FTPS protocol | `string` | `null` | no |
| endpoint_details | A block required to setup internal or public facing SFTP server endpoint within a VPC<pre>{<br>  vpc_id                 = (Optional) ID of VPC in which SFTP server endpoint will be hosted. Required if endpoint type is set to VPC<br>  vpc_endpoint_id        = (Optional) The ID of VPC endpoint to use for hosting internal SFTP server. Required if endpoint type is set to VPC_ENDPOINT<br>  subnet_ids             = (Optional) List of subnets ids within the VPC for hosting SFTP server endpoint. Supported only if endpoint type is set to VPC<br>  security_group_ids     = (Optional) List of security groups to attach to the SFTP endpoint. Supported only if endpoint is to type VPC. If left blank for VPC endpoint a security group with port 22 open to the world will be created and attached<br>  address_allocation_ids = (Optional) List of address allocation IDs to attach an Elastic IP address to your SFTP server endpoint. Supported only if endpoint type is set to VPC<br>}</pre> | <pre>object({<br>    vpc_id                 = optional(string)<br>    vpc_endpoint_id        = optional(string)<br>    subnet_ids             = optional(list(string))<br>    security_group_ids     = optional(list(string))<br>    address_allocation_ids = optional(list(string))<br>  })</pre> | `null` | no |
| identity_provider_type | Mode of authentication to use for accessing the service. **Valid Values:** `SERVICE_MANAGED`, `API_GATEWAY`, `AWS_DIRECTORY_SERVICE` or `AWS_LAMBDA` | `string` | `"SERVICE_MANAGED"` | no |
| api_gw_url | URL of the service endpoint to authenticate users when `identity_provider_type` is of type `API_GATEWAY` | `string` | `null` | no |
| invocation_role | ARN of the IAM role to authenticate the user when `identity_provider_type` is set to `API_GATEWAY` | `string` | `null` | no |
| directory_id | ID of the directory service to authenticate users when `identity_provider_type` is of type `AWS_DIRECTORY_SERVICE` | `string` | `null` | no |
| function_arn | ARN of the lambda function to authenticate users when `identity_provider_type` is of type `AWS_LAMBDA` | `string` | `null` | no |
| logging_role | ARN of an IAM role to allow to write SFTP users activity to Amazon CloudWatch logs | `string` | `null` | no |
| force_destroy | Whether to delete all the users associated with server so that server can be deleted successfully. **Note:** Supported only if `identity_provider_type` is set to `SERVICE_MANAGED` | `bool` | `true` | no |
| security_policy_name | Specifies the name of the [security policy](https://docs.aws.amazon.com/transfer/latest/userguide/security-policies.html) to associate with the server | `string` | `"TransferSecurityPolicy-2020-06"` | no |
| host_key | RSA private key that will be used to identify your server when clients connect to it over SFTP | `string` | `null` | no |
| hosted_zone | Hosted zone name to create DNS entry for SFTP server | `string` | `null` | no |
| sftp_sub_domain | DNS name for SFTP server. **NOTE: Only sub-domain required. DO NOT provide entire URL** | `string` | `"sftp"` | no |
| sftp_users | Map of users with key as username and value as their home directory<pre>{<br>  user = home_dir_path<br>}</pre> | `map(string)` | `{}` | no |
| sftp_users_ssh_key | Map of users with key as username and value as their public SSH key<pre>{<br>  user = ssh_public_key_content<br>}</pre> | `map(string)` | `{}` | no |
| tags | A map of key value pair to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | ARN of transfer server |
| id | ID of transfer server |
| endpoint | Endpoint of transfer server |
| domain_name | Custom DNS name mapped in Route53 for transfer server |
| sftp_sg_id | ID of security group created for SFTP server if of type VPC and security group is not provided by you |
