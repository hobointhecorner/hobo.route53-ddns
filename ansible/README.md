# Install route53-ddns with Ansible

`ansible_playbook install_route53ddns.yml`

If you prefer, you can use Ansible to install the route53-ddns container as a systemd service that runs `Update-Route53Ddns -Quiet -Wait`.

## Setting up Inventory
Configuration of the container is handled via inventory variables.  By default, inventory is pulled from a directory named inventory in this directory.

### Example inventory/main.yml
```
---
all:
  hosts:
    ddns:
      ddns_zones:
        - hobo.internal
      ddns_record_names:
        - '@' # Create a record named 'hobo.internal'
      ddns_access_key: # AWS_ACCESS_KEY_ID
      ddns_access_secret: # AWS_SECRET_ACCESS_KEY
```

### Configuration Variables
| Name                             | Required | Type         | Default | Description | More info |
|----------------------------------|----------|--------------|---------|-------------|-----------|
| ddns_zones                       | true     | list(string) |         | List of zones in which to create DNS records | [Zone](../Hobo.Route53Ddns/CONFIG.md#zone) |
| ddns_record_names                | true     | list(string) |         | List of names from which DNS records will be created in each zone | [Record](../Hobo.Route53Ddns/CONFIG.md#record) |
| ddns_ttl_sec                     | false    | number       | 21600 (6hrs) | TTL in seconds of created DNS records | [Ttl](../Hobo.Route53Ddns/CONFIG.md#ttl) |
| ddns_access_key                  | true     | string       |         | Access Key ID to use for AWS authentication | [Authentication](../Hobo.Route53Ddns/AUTH.md#environment-variables) |
| ddns_access_secret               | true     | string       |         | Secret Access Key to use for AWS authentication | [Authentication](../Hobo.Route53Ddns/AUTH.md#environment-variables) |
| ddns_additional_parameters       | false    | list(string) |         | Any additional command-line parameters to pass to the `Update-Route53Ddns` cmdlet | [Script Behavior](../Hobo.Route53Ddns/CONFIG.md#script-behavior) |
| ddns_config_dir                  | false    | string       | /opt/route53-ddns | Destination directory for config files | |
| ddns_container_registry          | false    | string       | ghcr.io | The container registry from which to pull the route53-ddns container | |
| ddns_container_name              | false    | string       | hobointhecorner/Hobo.Route53Ddns | The name of the route53-ddns container to pull | |
| ddns_container_tag               | false    | string       | stable  | The tag of the container to pull. Can be `latest`, `stable`, or any tagged version | |
| ddns_container_force_pull        | false    | bool         | false   | Always pull the container image and restart the service | |
| ddns_container_registry_username | false    | string       |         | The username with which to authenticate to the container registry | |
| ddns_container_registry_password | false    | string       |         | The password with which to authenticate to the container registry | |
