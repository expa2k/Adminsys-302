
function Install-DHCP {
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
}

function Restart-DHCP {
    Restart-Service dhcpserver
}

function Configure-DHCP {
    param (
        [string]$ScopeId,
        [string]$DnsServer,
        [string]$Router
    )
    Add-DHCPServerV4Scope
    Restart-DHCP
}

function Validate-IP {
    param ([string]$IP)
    if ($IP -match '^([0-9]{1,3}\.){3}[0-9]{1,3}$') {
        return $true
    } else {
        Write-Host "IP inválida"
        return $false
    }
}

Install-DHCP
Configure-DHCP 