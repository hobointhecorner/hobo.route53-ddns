FROM mcr.microsoft.com/powershell:latest

LABEL org.opencontainers.image.source https://github.com/hobointhecorner/hobo.route53-ddns

COPY ["Hobo.Route53Ddns", "/usr/local/share/powershell/Modules/Hobo.Route53Ddns/"]
RUN pwsh -command /usr/local/share/powershell/Modules/Hobo.Route53Ddns/Install-Route53Ddns.ps1

ENTRYPOINT [ "pwsh", "-Command" ]
