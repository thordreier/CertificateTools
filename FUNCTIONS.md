# CertificateTools

Text in this document is automatically created - don't change it manually

## Index

[Find-NewestCertificate](#Find-NewestCertificate)<br>
[Get-HttpsBinding](#Get-HttpsBinding)<br>
[Set-HttpsBinding](#Set-HttpsBinding)<br>

## Functions

<a name="Find-NewestCertificate"></a>
### Find-NewestCertificate

```

NAME
    Find-NewestCertificate
    
SYNOPSIS
    Find newest "version" of a SSL certificate
    
    
SYNTAX
    Find-NewestCertificate -Certificate <X509Certificate> [-HasPrivateKey] [<CommonParameters>]
    
    Find-NewestCertificate -CertificateHash <String> [-CertStoreLocation <String>] [-HasPrivateKey] [<CommonParameters>]
    
    Find-NewestCertificate -CommonName <String> [-CertStoreLocation <String>] [-HasPrivateKey] [<CommonParameters>]
    
    
DESCRIPTION
    Find newest "version" of a SSL certificate
    Find the newest certificate based on common name (CN) - certificates are compared/matched based on the same CN
    Newest is the certificate with the highest NotAfter date
    If a non-wildcard certificate is provided, then a newer wildcard certificate will not be returned (because match is done on CN)
    

PARAMETERS
    -Certificate <X509Certificate>
        Find newest certificate based on (other older) certificate object
        
    -CertificateHash <String>
        Find newest certificate based on certificate hash
        
    -CommonName <String>
        Find newest certificate based on CN
        
    -CertStoreLocation <String>
        Look for certificates in this location
        Defaults to Cert:\LocalMachine\My
        
    -HasPrivateKey [<SwitchParameter>]
        Only return certificate if it has a private key
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Find-NewestCertificate -CertificateHash D5681CB21FC812AF764F5FB491DA6430C9EA73A9
    
    - Find the certificate with thumbprint D568.. from Cert:\LocalMachine\My
    - Take the common name from that certificate
    - Find the newest certificate, with the same common name, in Cert:\LocalMachine\My.
      (This certificate can be D568.., if that is already the newest)
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Find-NewestCertificate -CommonName '*.foobar.tld' -Path Cert:\LocalMachine\My -HasPrivateKey
    
    - Find the newest certificate with CN=*.foobar.tld that has a private key
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Get-Item -Path Cert:\LocalMachine\Root\75e0abb6138512271c04f85fddde38e4b7242efe | Find-NewestCertificate
    
    - 75e0... should be a root certificate with CN=GlobalSign that expire in 2021
    - It should return a certificate with same CN that expire in 2029 with thumbprint D69B...
      (at least on some computers)
    
    
    
    
REMARKS
    To see the examples, type: "get-help Find-NewestCertificate -examples".
    For more information, type: "get-help Find-NewestCertificate -detailed".
    For technical information, type: "get-help Find-NewestCertificate -full".

```

<a name="Get-HttpsBinding"></a>
### Get-HttpsBinding

```
NAME
    Get-HttpsBinding
    
SYNOPSIS
    Get certificates on HTTPS bindings
    
    
SYNTAX
    Get-HttpsBinding [[-Certificate] <X509Certificate>] [[-Binding] <String>] [[-IpPort] <String>] [[-HostnamePort] <String>] [[-Port] <UInt16>] [[-IPAddress] <String>] [[-HostHeader] <String>] [[-CertificateHash] <String>] [[-ApplicationId] <Guid>] [[-CertificateStoreName] 
    <String>] [[-Protocol] <String>] [[-BindingInformation] <String>] [[-SslFlags] <Int16>] [<CommonParameters>]
    
    
DESCRIPTION
    Get certificates on HTTPS bindings
    
    Microsofts own cmdlets:
    Add-NetIPHttpsCertBinding and Remove-NetIPHttpsCertBinding are just crap!!
    Remove-NetIPHttpsCertBinding removes ALL bindings, Add-NetIPHttpsCertBinding only works with IpPort (not HostnamePort) and there's no way to show/get bindings!
    

PARAMETERS
    -Certificate <X509Certificate>
        Find bindings using this certificate
        
    -Binding <String>
        Find binding (binding is the same as IpPort or HostnamePort)
        
    -IpPort <String>
        Find binding with IP:Port
        
    -HostnamePort <String>
        Find binding with Hostname:Port
        
    -Port <UInt16>
        Find bindings on this TCP port
        
    -IPAddress <String>
        Find bindding with this IP address
        
    -HostHeader <String>
        Find binding with this hostheader/hostname
        
    -CertificateHash <String>
        Find bindings that uses certificate with this hash/thumbprint
        Also used when piping object from Get-WebBinding
        
    -ApplicationId <Guid>
        Find bindings with this application id
        
    -CertificateStoreName <String>
        Find bindings with certificate in this location
        Also used when piping object from Get-WebBinding
        
    -Protocol <String>
        Find bindings with this protocol. Everyting but https is ignored
        Also used when piping object from Get-WebBinding
        
    -BindingInformation <String>
        Find bindings with this "bindinginformation"
        Also used when piping object from Get-WebBinding
        
    -SslFlags <Int16>
        Used together with BindingInformation
        Also used when piping object from Get-WebBinding
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Get-HttpsBinding
    
    Get all SSL bindings - it's "netsh http show sslcert" wrapped in some PowerShell
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Get-HttpsBinding -Port 443
    
    Get all bindings that use TCP port 443
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>dir Cert:\LocalMachine\My\1234FBC46BB66309EBD861BE4F95062B7C9E5E61 | Get-HttpsBinding
    
    Get all bindings that use a specific SSL certificate
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS C:\>Get-HttpsBinding | Get-WebBinding
    
    Get SSL bindings and find IIS bindings (requires that IIS PowerShell tools are installed)
    
    
    
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS C:\>Get-WebBinding | Get-HttpsBinding
    
    Get IIS bindings and find SSL bindings (requires that IIS PowerShell tools are installed)
    
    
    
    
REMARKS
    To see the examples, type: "get-help Get-HttpsBinding -examples".
    For more information, type: "get-help Get-HttpsBinding -detailed".
    For technical information, type: "get-help Get-HttpsBinding -full".

```

<a name="Set-HttpsBinding"></a>
### Set-HttpsBinding

```
NAME
    Set-HttpsBinding
    
SYNOPSIS
    Set/replace certificates on HTTPS bindings
    
    
SYNTAX
    Set-HttpsBinding [-DryRun] -ReplaceAllWithNewest [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -Binding <HttpsBinding> -PfxPath <String> [-Exportable] -PasswordClear <String> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -Binding <HttpsBinding> -PfxPath <String> [-Exportable] -Password <SecureString> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -Binding <HttpsBinding> -CertificateHash <String> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -IpPort <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] -PfxPath <String> [-Exportable] -PasswordClear <String> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -IpPort <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] -PfxPath <String> [-Exportable] -Password <SecureString> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -IpPort <String> -CertificateHash <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -HostnamePort <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] -PfxPath <String> [-Exportable] -PasswordClear <String> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -HostnamePort <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] -PfxPath <String> [-Exportable] -Password <SecureString> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -HostnamePort <String> -CertificateHash <String> [-ApplicationId <Guid>] [-CertificateStoreName <String>] [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -OldCertificateHash <String> -PfxPath <String> [-Exportable] -PasswordClear <String> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -OldCertificateHash <String> -PfxPath <String> [-Exportable] -Password <SecureString> [<CommonParameters>]
    
    Set-HttpsBinding [-DryRun] -OldCertificateHash <String> -CertificateHash <String> [<CommonParameters>]
    
    
DESCRIPTION
    Set/replace certificates on HTTPS bindings
    
    Microsofts own cmdlets:
    Add-NetIPHttpsCertBinding and Remove-NetIPHttpsCertBinding are just crap!!
    Remove-NetIPHttpsCertBinding removes ALL bindings, Add-NetIPHttpsCertBinding only works with IpPort (not HostnamePort) and there's no way to show/get bindings!
    

PARAMETERS
    -DryRun [<SwitchParameter>]
        Only show what would be changed, but don't change it
        
    -ReplaceAllWithNewest [<SwitchParameter>]
        Replace certificates on all bindings that have a newer certificate with same common name
        
    -Binding <HttpsBinding>
        Replace certificate on this binding
        
    -IpPort <String>
        Replace certificate on this binding
        
    -HostnamePort <String>
        Replace certificate on this binding
        
    -OldCertificateHash <String>
        Replace certificates on bindings that has certificates with this thumbprint
        
    -CertificateHash <String>
        Replace binding with certificate with this thumbprint
        
    -ApplicationId <Guid>
        Application ID of binding
        
    -CertificateStoreName <String>
        Certificate store (normally just "My")
        
    -PfxPath <String>
        Path to PFX file to use on binding - will be imported to certificate store
        
    -Exportable [<SwitchParameter>]
        Should the private key for the imported PFX be exportable
        
    -Password <SecureString>
        Password for PFX file
        
    -PasswordClear <String>
        Password for PFX file in clear text
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Set-HttpsBinding -ReplaceAllWithNewest -DryRun
    
    Replace certificates on all bindings where a newer certificate is found (same CN).
    But don't actuall run netsh - only show what would have run
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Set-HttpsBinding -IpPort 0.0.0.0:443 -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'
    
    Update binding on 0.0.0.0:443 with certificate with thumbprint 1234...
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Set-HttpsBinding -OldCertificateHash '4321fbc46bb66309ebd861be4f95062b7c9e5e61' -CertificateHash '12341cb21fc912af764f5fb491da6430c9ea73a8'
    
    Change all binding that use 4321... to 1234...
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS C:\>Get-HttpsBinding -Port 44399 | Set-HttpsBinding -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'
    
    Change all binding on TCP port 443399 to certificate with hash 1234...
    
    
    
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS C:\>Set-HttpsBinding -HostnamePort 'www.foobar.tld:443' -PfxPath 'foobar.pfx' -Exportable -PasswordClear 'Password1!'
    
    Import foobar.pfx to certificate store (and make private key exportable)
    and change binding on www.foobar.tld:443 to use that certificate
    
    
    
    
REMARKS
    To see the examples, type: "get-help Set-HttpsBinding -examples".
    For more information, type: "get-help Set-HttpsBinding -detailed".
    For technical information, type: "get-help Set-HttpsBinding -full".

```



