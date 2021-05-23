# Create a managed SFTP server using AWS Transfer service

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

## Licence:
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

MIT Licence. See [Licence](LICENCE) for full details.

# Usage Instructions:
## Variables
| Parameter          | Type   | Description                                                                              | Default         | Required |
|--------------------|--------|------------------------------------------------------------------------------------------|-----------------|----------|
| sftp_type          | string | Type of SFTP server. Valid values: public or private                                     | public          | N        |
| name   | string | Name of SFTP server                                                                      | sftp-server     | N        |
| vpc_endpoint_id    | string | Id of VPC Endpoint. Required if you are creating private SFTP server                     | null            | N        |
| auth_type          | string | Identity provider type for AuthN and AuthZ. Valid values: SERVICE_MANAGED or API_GATEWAY | SERVICE_MANAGED | N        |
| api_url            | string | URL of API Gateway resource. Required if auth_type is set to API_GATEWAY                 | null            | N        |
| root_hosted_zone   | string | Hosted zone name to create DNS entry for SFTP server                                     |                 | Y        |
| sftp_domain        | string | DNS name for SFTP server. **NOTE: Only sub-domain required. DO NOT provide entire URL**  | sftp            | N        |
| sftp_users         | list   | List of users to create on SFTP server                                                   |                 | Y        |
| sftp_user_home_dir | list   | List of home dir for users                                                               |                 | Y        |
| sftp_user_ssh_key  | list   | List of user SSH key for authentication                                                  |                 | Y        |

## Outputs
| Parameter        | Type   | Description             |
|------------------|--------|-------------------------|
| sftp_id          | string | ID of SFTP server       |
| sftp_endpoint    | string | Endpoint of SFTP server |
| sftp_domain_name | string | DNS name of SFTP server |

## Deployment
- `terraform init` - download plugins required to deploy resources
- `terraform plan` - get detailed view of resources that will be created, deleted or replaced
- `terraform apply -auto-approve` - deploy the template without confirmation (non-interactive mode)
- `terraform destroy -auto-approve` - terminate all the resources created using this template without confirmation (non-interactive mode)
