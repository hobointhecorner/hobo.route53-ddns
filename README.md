# Powershell Route53 DDNS Client
PowerShell module that acts as a Dynamic DNS (DDNS) client for Amazon AWS Route53

[Module usage](Hobo.Route53Ddns/README.md)

[Module configuration](Hobo.Route53Ddns/CONFIG.md)

[AWS Authentication](Hobo.Route53Ddns/AUTH.md)

[Install with Ansible](ansible/README.md)

## Container Management
### Build the Container
`docker build . -t ghcr.io/hobointhecorner/hobo.route53-ddns:stable`

### Run the Container
`docker run ghcr.io/hobointhecorner/hobo.route53-ddns:stable Update-Route53Ddns`
