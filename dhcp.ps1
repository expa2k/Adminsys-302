Install-WindowsFeature -Name DHCP -IncludeManagementTools
Add-DHCPServerV4Scope
Set-DHCPServerV4OptionValue -ScopeId 192.168.0.0 -DnsServer 8.8.8.8 -Router 192.168.0.1
Restart-Service dhcpserver