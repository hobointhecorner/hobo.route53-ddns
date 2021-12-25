# Authenticating with AWS Route53
The Route53 PowerShell module uses the pre-existing AWS local login flow, so you can handle authentication in the following ways:

## IAM Permissions
| Action                             | Scope |
|------------------------------------|-------|
| `route53:ListHostedZones`          | `'*'` |
| `route53:ListHostedZonesByName`    | `'*'` |
| `route53:ChangeResourceRecordSets` | Zone  |
| `route53:ListResourceRecordSets`   | Zone  |

## Environment variables
Set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables to the access key ID and secret of an IAM user with required permissions

**Preferred for:**
* Docker service
* Docker container

## AWS CLI Configuration
Running `aws config` through the AWS CLI will guide you through the steps to save an `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as the default authentication profile when using the AWS CLI or using this module

**Preferred for:**
* Running module commands directly
* Docker container
    * You can mount your `~/.aws` directory to `/root/.aws` in the container to use your already-configured credentials
