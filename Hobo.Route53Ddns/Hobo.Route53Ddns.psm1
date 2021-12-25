if ($IsLinux)
{
    $Default_ConfigDirectory = Join-Path $env:HOME '.route53-ddns'
}
else
{
    $Default_ConfigDirectory = Join-Path $env:APPDATA 'route53-ddns'
}

$logPref = @{
    LogEvent     = $IsLinux -ne $true
    LogEventPref = @{
        LogName   = 'Route53DDNS'
        LogSource = 'Route53DDNS'
    }
}

#
#region PREFERENCES
#

function Get-Route53DdnsPrefPath
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    process
    {
        return (Join-Path $Default_ConfigDirectory "ddns_$($Name.ToLower()).json")
    }
}

function Get-Route53DdnsPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Zone', 'Record', 'Ttl')]
        [string]$Name,
        $InputObject,
        [switch]$File
    )

    begin
    {
        $prefParam = @{
            PrefFilePath   = Get-Route53DdnsPrefPath $Name
            PrefFileFormat = 'json'
        }

        if (!$File)
        {
            switch ($Name)
            {
                'Zone' { $envVarName = 'DDNS_ZONE' }
                'Record' { $envVarName = 'DDNS_RECORD' }
                'Ttl' { $envVarNAme = 'DDNS_TTL' }
            }

            $prefParam += @{
                InputObject = $InputObject
                VarName     = $envVarName
                Delimiter   = ','
            }
        }
    }

    process
    {
        Get-Pref @prefParam
    }
}

function Set-Route53DdnsPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Ttl')]
        [string]$Name,
        $InputObject
    )

    begin
    {
        $prefPath = Get-Route53DdnsPrefPath $Name
    }

    process
    {
        Set-Pref -Content $InputObject -Path $prefPath -Format json
    }
}

function Add-Route53DdnsPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Zone', 'Record')]
        [string]$Name,
        $InputObject
    )

    begin
    {
        $prefPath = Get-Route53DdnsPrefPath $Name

        $prefList = @()
        Get-Route53DdnsPref $Name -File | ForEach-Object { $prefList += $_ }
    }

    process
    {
        if ($InputObject -inotin $prefList)
        {
            $prefList += $InputObject
            Set-Pref -Content $prefList -Path $prefPath -Format json
        }
        else
        {
            Write-Warning "$Name $InputObject already exists"
        }
    }
}

function Remove-Route53DdnsPref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateSet('Zone', 'Record')]
        [string]$Name,
        $InputObject
    )

    begin
    {
        $prefPath = Get-Route53DdnsPrefPath $Name

        $prefList = @()
        Get-Route53DdnsPref $Name -File | ForEach-Object { $prefList += $_ }
    }

    process
    {
        if ($InputObject -iin $prefList)
        {
            $newPrefList = @()
            $prefList | Where-Object { $_ -ine $InputObject } | ForEach-Object { $newPrefList += $_ }

            Set-Pref -Content $newPrefList -Path $prefPath -Format json
        }
    }
}

#
#endregion
#

#
# Every function below here should be exported
#region TOOLS
#

function Get-Route53DdnsIp
{
    [cmdletbinding()]
    param()

    process
    {
        $ip = Invoke-RestMethod 'wtfismyip.com/text'
        if ($ip)
        {
            return $ip.Trim()
        }
    }
}

function Get-Route53DdnsZoneName
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$ZoneName
    )

    process
    {
        if (!$ZoneName.EndsWith('.')) { $ZoneName += '.' }
        return $ZoneName
    }
}

function Get-Route53DdnsZoneId
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$ZoneId
    )

    process
    {
        if (!$ZoneId.StartsWith('/hostedzone/')) { $ZoneId = "/hostedzone/$ZoneId" }
        return $ZoneId
    }

}

function Find-Route53DdnsZone
{
    [cmdletbinding()]
    param(
        [string]$Zone
    )

    begin
    {
        $zoneList = Get-R53HostedZoneList
        $zoneName = Get-Route53DdnsZoneName $Zone
        $zoneId = Get-Route53DdnsZoneId $Zone
    }

    process
    {
        if ($zoneObject = $zoneList | Where-Object { $_.Id -ieq $zoneId })
        {
            return $zoneObject
        }
        elseif ($zoneObject = $zoneList | Where-Object { $_.Name -ieq $zoneName })
        {
            return $zoneObject
        }
        else
        {
            throw "Unable to find route53 zone $Zone"
        }
    }
}

function Get-Route53DdnsRecordName
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$RecordName,
        [string]$ZoneName
    )

    begin
    {
        if ($ZoneName)
        {
            $ZoneName = Get-Route53DdnsZoneName $ZoneName

            if ($RecordName -eq '@')
            {
                $RecordName = $ZoneName
            }

            if ($RecordName -ine $ZoneName)
            {
                $RecordName = Get-Route53DdnsRecordName $RecordName
                $RecordName = "$RecordName$ZoneName"
            }
        }
    }

    process
    {
        if (!$RecordName.EndsWith('.')) { $RecordName += '.' }
        return $RecordName
    }
}

function Get-Route53DdnsRecord
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$RecordName,

        [parameter(Mandatory)]
        [Amazon.Route53.Model.HostedZone]$Zone
    )

    begin
    {
        $RecordName = Get-Route53DdnsRecordName $RecordName $Zone.Name
    }

    process
    {
        Get-R53ResourceRecordSet -HostedZoneId $Zone.Id -StartRecordName $RecordName |
            Select-Object -ExpandProperty resourcerecordsets |
                Where-Object { $_.Type -ieq 'A' } |
                Where-Object { $_.Name -ieq $RecordName } |
                    Select-Object -ExpandProperty ResourceRecords |
                    Select-Object -ExpandProperty Value
    }
}

#
#endregion
#

#
# No function above here should use the below functions
#region OUTPUT
#

function Write-Route53DdnsOutput
{
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Content,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Type = 'INFO'
    )

    begin
    {
        $oldInfoPref = $InformationPreference
        $InformationPreference = 'Continue'
    }

    process
    {
        foreach ($message in $Content)
        {
            Write-LogTee @logPref -Message $message -LogType $Type
        }
    }

    end
    {
        $InformationPreference = $oldInfoPref
    }
}

#
#endregion
#


#
#region JOBS
#

function Get-Route53DdnsJob
{
    [cmdletbinding()]
    param(
        [string]$Category = '*'
    )

    process
    {
        Get-PSBackgroundJob -Module 'Route53Ddns' -Category $Category
    }
}

function Start-Route53DdnsJob
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$Zone,

        [parameter(Position = 1)]
        [string[]]$Record,

        [parameter(Position = 2)]
        [int]$TtlSec,

        [parameter(Position = 3)]
        [bool]$Quiet = $false,

        [parameter(Position = 4)]
        [bool]$Wait = $false,

        [parameter(Position = 5)]
        [timespan]$PollingInterval = "00:00:30"
    )

    begin
    {
        $firstRun = $true
    }

    process
    {
        while ($firstRun -or $Wait)
        {
            try
            {
                if ($zoneObject = Find-Route53DdnsZone $Zone -ErrorAction Continue)
                {
                    if (!$Quiet) { Write-Route53DdnsOutput "Updating zone $($zoneObject.Name)" }
                    foreach ($rec in $Record)
                    {
                        $recordName = Get-Route53DdnsRecordName -RecordName $rec -ZoneName $zoneObject.Name
                        $currentValue = Get-Route53DdnsRecord -Zone $zoneObject -RecordName $rec
                        $ddnsIp = Get-Route53DdnsIp

                        if ($currentValue -ne $ddnsIp)
                        {
                            $change = New-Object Amazon.Route53.Model.Change
                            $change.Action = 'UPSERT'

                            $recordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                            $recordSet.Name = $recordName
                            $recordSet.Type = 'A'
                            $recordSet.TTL = $TtlSec
                            $recordSet.ResourceRecords.Add(@{ Value = $ddnsIp })
                            $change.ResourceRecordSet = $recordSet

                            Write-Route53DdnsOutput -Content "Updating $recordName ($currentValue -> $ddnsIp)"
                            Edit-R53ResourceRecordSet -HostedZoneId $zoneObject.Id -ChangeBatch_Change $change -Confirm:$false | Out-Null
                        }
                        elseif (!$Quiet)
                        {
                            Write-Route53DdnsOutput "No changes needed for $recordName"
                        }
                    }
                }
            }
            catch
            {
                Write-Route53DdnsOutput $_.Exception.Message -Type ERROR
            }
            finally
            {
                $firstRun = $false

                if ($Wait)
                {
                    Start-Sleep -Seconds $PollingInterval.TotalSeconds
                }
            }
        }
    }
}

#
#endregion
#

function Update-Route53Ddns
{
    [cmdletbinding()]
    param(
        [string[]]$Zone,
        [string[]]$RecordName,
        [int]$TtlSec,

        [switch]$Quiet,
        [switch]$Wait,

        [switch]$ConfigRefresh,
        [ValidateNotNullOrEmpty()]
        [timespan]$ConfigRefreshInterval = "01:00:00",

        [ValidateNotNullOrEmpty()]
        [timespan]$PollingInterval = "00:00:30",

        [ValidateNotNullOrEmpty()]
        [timespan]$OutputInterval = "00:00:10"
    )

    begin
    {
        $firstRun = $true
        $lastConfigRefresh = [datetime]::MinValue
        $defaultTtl = ([timespan]'00:06:00').TotalSeconds

        Get-Route53DdnsJob -Category 'dns-update' | Remove-PsBackgroundJob -Force
    }

    process
    {
        while ($firstRun -or (Get-Route53DdnsJob -Category 'dns-update'))
        {
            try
            {
                # Refresh config
                $currentTime = Get-Date
                $needsRefresh = $lastConfigRefresh -lt ($currentTime - $ConfigRefreshInterval)
                if ($firstRun -or ($ConfigRefresh -and $needsRefresh))
                {
                    $zoneList = Get-Route53DdnsPref Zone $Zone
                    $zoneCount = $zoneList | Measure-Object | Select-Object -ExpandProperty Count
                    Write-Route53DdnsOutput "Zones ($zoneCount): $($zoneList -join ', ')"

                    $recordList = Get-Route53DdnsPref Record $RecordName
                    $recordCount = $recordList | Measure-Object | Select-Object -ExpandProperty Count
                    Write-Route53DdnsOutput "Records ($recordCount): $($recordList -join ', ')"

                    $TtlSec = Get-Route53DdnsPref Ttl $TtlSec
                    if (!($TtlSec)) { $TtlSec = $defaultTtl }
                    Write-Route53DdnsOutput "TTL: $([timespan]::FromSeconds($TtlSec))"
                }

                # Receive job output
                Get-Route53DdnsJob -Category 'dns-update' | Receive-PSBackgroundJob

                # Remove completed jobs
                Get-Route53DdnsJob -Category 'dns-update' | Where-Object { $_.Status -ine 'running' } | Remove-PSBackgroundJob

                # Start new jobs if needed
                if ($FirstRun -or $Wait)
                {
                    $jobList = Get-Route53DdnsJob -Category 'dns-update'
                    $zoneList |
                        Where-Object { $_ -inotin $jobList.Name } |
                        ForEach-Object {
                            Start-PsBackgroundJob -Name $_ `
                                -Module Route53Ddns -Category 'dns-update' `
                                -ScriptBlock ${Function:Start-Route53DdnsJob} `
                                -ArgumentList $_, $recordList, $TtlSec, $Quiet, $Wait, $PollingInterval
                        } | Out-Null

                }
            }
            catch
            {
                Write-Route53DdnsOutput "Uncaught exception: $($_.Exception.Message)" -Type ERROR
            }
            finally
            {
                $firstRun = $false

                if ($Wait -or (Get-Route53DdnsJob -Category 'dns-update'))
                {
                    Start-Sleep -Seconds $OutputInterval.Seconds
                }
            }
        }
    }
}
