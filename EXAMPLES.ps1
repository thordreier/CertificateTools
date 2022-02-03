############################ Find-NewestCertificate ############################

# Find the certificate with thumbprint D568.. from Cert:\LocalMachine\My
# Take the common name from that certificate
# Find the newest certificate, with the same common name, in Cert:\LocalMachine\My.
#   (This certificate can be D568.., if that is already the newest)
Find-NewestCertificate -CertificateHash D5681CB21FC812AF764F5FB491DA6430C9EA73A9

# Find the newest certificate with CN=*.foobar.tld that has a private key
Find-NewestCertificate -CommonName '*.foobar.tld' -Path Cert:\LocalMachine\WebHosting -HasPrivateKey

# 75e0... should be a root certificate with CN=GlobalSign that expire in 2021
# It should return a certificate with same CN that expire in 2029 with thumbprint D69B...
#   (at least on some computers)
Get-Item -Path Cert:\LocalMachine\Root\75e0abb6138512271c04f85fddde38e4b7242efe | Find-NewestCertificate



############################### Get-HttpsBinding ###############################

#Get all SSL bindings - it's "netsh http show sslcert" wrapped in some PowerShell
Get-HttpsBinding
# Returns something like
# Binding                   CertificateHash                            Expire     Application   Subject
# -------                   ---------------                            ------     -----------   -------
# example1.foobar.tld:443   0123456789abcdef0123456789abcdef01234567   5/4/2022   IIS           CN=example1.foobar.tld
# example2.foobar.tld:443   fedcba9876543210fedcba9876543210fedcba98   5/4/2022   IIS           CN=example2.foobar.tld

# Format list will show more info
Get-HttpsBinding | Format-List
# Returns something like
# Binding               : example1.foobar.tld:443
# IpPort                :
# HostnamePort          : example1.foobar.tld:443
# CertificateHash       : 0123456789abcdef0123456789abcdef01234567
# ApplicationId         : 4dc3e181-e14b-4a21-b022-59fc669b0914
# CertificateStoreName  : WebHosting
# ...
# ...

# Get all bindings that use TCP port 443
Get-HttpsBinding -Port 443

# Get all bindings that use a specific SSL certificate
dir Cert:\LocalMachine\My\1234FBC46BB66309EBD861BE4F95062B7C9E5E61 | Get-HttpsBinding

# Get SSL bindings and find IIS bindings (requires that IIS PowerShell tools are installed)
Get-HttpsBinding | Get-WebBinding

# Get IIS bindings and find SSL bindings (requires that IIS PowerShell tools are installed)
Get-WebBinding | Get-HttpsBinding



############################### Set-HttpsBinding ###############################

# Replace certificates on all bindings where a newer certificate is found (same CN).
# But don't actuall run netsh - only show what would have run
Set-HttpsBinding -ReplaceAllWithNewest -DryRun

# Update binding on 0.0.0.0:443 with certificate with thumbprint 1234...
Set-HttpsBinding -IpPort 0.0.0.0:443 -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'

# Change all binding that use 4321... to 1234...
Set-HttpsBinding -OldCertificateHash '4321fbc46bb66309ebd861be4f95062b7c9e5e61' -CertificateHash '12341cb21fc912af764f5fb491da6430c9ea73a8'

# Change all binding on TCP port 443399 to certificate with hash 1234...
Get-HttpsBinding -Port 44399 | Set-HttpsBinding -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'

# Import foobar.pfx to certificate store (and make private key exportable)
# and change binding on www.foobar.tld:443 to use that certificate
Set-HttpsBinding -HostnamePort 'www.foobar.tld:443' -PfxPath 'foobar.pfx' -Exportable -PasswordClear 'Password1!'
