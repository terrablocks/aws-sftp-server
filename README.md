# Create a managed SFTP server using AWS Transfer service

![License](https://img.shields.io/github/license/terrablocks/aws-sftp-server?style=for-the-badge) ![Tests](https://img.shields.io/github/workflow/status/terrablocks/aws-sftp-server/tests/master?label=Test&style=for-the-badge) ![Checkov](https://img.shields.io/github/workflow/status/terrablocks/aws-sftp-server/checkov/master?label=Checkov&style=for-the-badge) ![Commit](https://img.shields.io/github/last-commit/terrablocks/aws-sftp-server?style=for-the-badge) ![Release](https://img.shields.io/github/v/release/terrablocks/aws-sftp-server?style=for-the-badge)

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
| terraform | >= 0.13 |
| aws | >= 3.37.0 |
| random | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of SFTP server. Ignore it to generate a random name for server | `string` | `null` | no |
| sftp_type | Type of SFTP server. **Valid values:** PUBLIC or VPC | `string` | `"PUBLIC"` | no |
| protocols | List of file transfer protocol(s) over which your FTP client can connect to your server endpoint. **Possible Values:** FTP, FTPS and SFTP | `list(string)` | <pre>[<br>  "SFTP"<br>]</pre> | no |
| certificate_arn | ARN of ACM certificate. Required only in case of FTPS protocol | `string` | `null` | no |
| endpoint_details | A block required to setup internal or public facing SFTP server endpoint within a VPC<pre>{<br>  vpc_id                 = ID of VPC in which SFTP server endpoint will be hosted<br>  subnet_ids             = List of subnets ids within the VPC for hosting SFTP server endpoint<br>  address_allocation_ids = List of address allocation IDs to attach an Elastic IP address to your SFTP server endpoint<br>}</pre> | <pre>object({<br>    vpc_id                 = string<br>    subnet_ids             = list(string)<br>    address_allocation_ids = list(string)<br>  })</pre> | `null` | no |
| identity_provider_type | Mode of authentication to use for accessing the service. **Valid Values:** SERVICE_MANAGED or API_GATEWAY | `string` | `"SERVICE_MANAGED"` | no |
| api_gw_url | URL of the service endpoint to authenticate users when `identity_provider_type` is of type `API_GATEWAY` | `string` | `null` | no |
| invocation_role | ARN of the IAM role to authenticate the user when `identity_provider_type` is set to `API_GATEWAY` | `string` | `null` | no |
| logging_role | ARN of an IAM role to allow to write your SFTP users’ activity to Amazon CloudWatch logs | `string` | `null` | no |
| force_destroy | Whether to delete all the users associated with server so that server can be deleted successfully | `bool` | `true` | no |
| security_policy_name | Specifies the name of the [security policy](https://docs.aws.amazon.com/transfer/latest/userguide/security-policies.html) to associate with the server. **Possible values:** TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06 or TransferSecurityPolicy-FIPS-2020-06 | `string` | `"TransferSecurityPolicy-2018-11"` | no |
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
