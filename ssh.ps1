Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (ssh)' -Enable True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 22
Restart-Service sshd
Write-Output "ssh ya funcionando"
