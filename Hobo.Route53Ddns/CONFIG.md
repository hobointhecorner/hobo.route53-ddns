# List of Hobo.Route53Ddns Parameters

## Configuration
### Zone
One or more zones in which to create the DDNS record(s)

| Info         | Value |
---------------|-------|
| **Required** | Yes |
| **Command**  | `-Zone <String[]>` |
| **Env**      | `DDNS_ZONE=<comma-delimited String>` |
| **File**     | `Get-Route53DdnsPref Zone ; Add/Remove-Route53DdnsPref Zone '{{ zone_name_or_id }}'` |

### RecordName
One or more record names to create in each zone.  `@` can be used to denote the record name will match the zone name
For example: `test.dev` record name with zone name 'corp.local' would result in `test.dev.corp.local.`

| Info         | Value |
---------------|-------|
| **Required** | Yes |
| **Command**  | `-RecordName <String[]>` |
| **Env**      | `DDNS_RECORD=<comma-delimited String>` |
| **File**     | `Get-Route53DdnsPref Record ; Add/Remove-Route53DdnsPref Record '{{ record_name }}'` |

### Ttl
The DNS TTL in seconds of the DNS records

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-TtlSec <Int>` |
| **Env**      | `DDNS_TTL=<Int>` |
| **File**     | `Get-Route53DdnsPref Ttl ; Set-Route53DdnsPref Ttl '{{ ttl_seconds }}'` |


## Script Behavior
### Wait
Continuously run, periodically validating record matches the public IP of this host

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-Wait` |

### ConfigRefresh
When used with `Wait` enables configuration variable auto-refresh

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-ConfigRefresh` |

### ConfigRefreshInterval
The minimum amount of time to wait between configuration refreshes when `ConfigRefresh` is enabled

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-ConfigRefreshInterval '01:00:00'` |

### PollingInterval
The amount of time between recordd validation checks

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-PollingInterval '00:00:30'` |

### OutputInterval
The amount of time between job status checks

| Info         | Value |
---------------|-------|
| **Required** | No |
| **Command**  | `-OutputInterval '00:00:10'` |
