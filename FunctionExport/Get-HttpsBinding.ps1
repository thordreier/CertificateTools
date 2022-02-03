function Get-HttpsBinding
{
    <#
        .SYNOPSIS
            Get certificates on HTTPS bindings

        .DESCRIPTION
            Get certificates on HTTPS bindings

            Microsofts own cmdlets:
            Add-NetIPHttpsCertBinding and Remove-NetIPHttpsCertBinding are just crap!!
            Remove-NetIPHttpsCertBinding removes ALL bindings, Add-NetIPHttpsCertBinding only works with IpPort (not HostnamePort) and there's no way to show/get bindings!

        .PARAMETER Certificate
            Find bindings using this certificate

        .PARAMETER Binding
            Find binding (binding is the same as IpPort or HostnamePort)

        .PARAMETER IpPort
            Find binding with IP:Port

        .PARAMETER HostnamePort
            Find binding with Hostname:Port

        .PARAMETER Port
            Find bindings on this TCP port

        .PARAMETER IPAddress
            Find bindding with this IP address

        .PARAMETER HostHeader
            Find binding with this hostheader/hostname

        .PARAMETER CertificateHash
            Find bindings that uses certificate with this hash/thumbprint
            Also used when piping object from Get-WebBinding

        .PARAMETER ApplicationId
            Find bindings with this application id

        .PARAMETER CertificateStoreName
            Find bindings with certificate in this location
            Also used when piping object from Get-WebBinding

        .PARAMETER Protocol
            Find bindings with this protocol. Everyting but https is ignored
            Also used when piping object from Get-WebBinding

        .PARAMETER BindingInformation
            Find bindings with this "bindinginformation"
            Also used when piping object from Get-WebBinding

        .PARAMETER SslFlags
            Used together with BindingInformation
            Also used when piping object from Get-WebBinding

        .EXAMPLE
            Get-HttpsBinding
            Get all SSL bindings - it's "netsh http show sslcert" wrapped in some PowerShell

        .EXAMPLE
            Get-HttpsBinding -Port 443
            Get all bindings that use TCP port 443

        .EXAMPLE
            dir Cert:\LocalMachine\My\1234FBC46BB66309EBD861BE4F95062B7C9E5E61 | Get-HttpsBinding
            Get all bindings that use a specific SSL certificate

        .EXAMPLE
            Get-HttpsBinding | Get-WebBinding
            Get SSL bindings and find IIS bindings (requires that IIS PowerShell tools are installed)

        .EXAMPLE
            Get-WebBinding | Get-HttpsBinding
            Get IIS bindings and find SSL bindings (requires that IIS PowerShell tools are installed)
    #>

    [OutputType([HttpsBinding[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Binding,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $IpPort,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $HostnamePort,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.UInt16]
        $Port,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $IPAddress,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $HostHeader,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CertificateHash,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Guid]
        $ApplicationId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CertificateStoreName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Protocol,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $BindingInformation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0,1)]
        [System.Int16]
        $SslFlags
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = ($PSBoundParameters.ContainsKey('Verbose') -and  $PSBoundParameters['Verbose'].IsPresent) -or ($VerbosePreference -ne 'SilentlyContinue')

        $certRootPath = 'Cert:\LocalMachine'

        $netshArray = New-Object -TypeName 'System.Collections.ArrayList'

        try
        {
            # Stop execution inside this function, and catch the error
            $ErrorActionPreference = 'Stop'

            # Default parameters used when calling other functions
            $defaultParam = @{
                Verbose     = $verbose
                ErrorAction = $ErrorActionPreference
            }

            # Getting bindings as string
            $netshString = netsh http show sslcert
            $netshString = $netshString[3..($netshString.length-1)]

            $obj = New-Object -TypeName 'HttpsBinding'

            # Loop through all lines
            foreach ($line in $netshString)
            {
                if ($line -match "^\s*$") {
                    # Empty line
                
                    if ($obj.CertificateHash)
                    {
                        if ($obj.IpPort)
                        {
                            $obj.Binding = $obj.IpPort
                            if ($obj.IpPort -match '^(.+):([0-9]+)$')
                            {
                                if ($Matches[1] -eq '0.0.0.0')
                                {
                                    # IIS uses wildcard instead of 0.0.0.0
                                    $obj.IPAddress = '*'
                                }
                                else
                                {
                                    $obj.IPAddress = $Matches[1]
                                }
                                $obj.Port      = $Matches[2]
                            }
                        }
                        elseif ($obj.HostnamePort)
                        {
                            $obj.Binding = $obj.HostnamePort
                            if ($obj.HostnamePort -match '^(.+):([0-9]+)$')
                            {
                                $obj.HostHeader = $Matches[1]
                                $obj.Port       = $Matches[2]
                            }
                        }

                        # Try to find the certificate in certificate store
                        if ($obj.CertificateHash -and $obj.CertificateStoreName)
                        {
                            try
                            {
                                $obj.Certificate = Get-Item -Path (Join-Path -Path (Join-Path -Path $certRootPath -ChildPath $obj.CertificateStoreName) -ChildPath $obj.CertificateHash)
                            }
                            catch
                            {
                                # Nothing
                            }
                        }

                        # Add binding to array of binding-objects
                        $null = $netshArray.Add($obj)
                    }

                    $obj = New-Object -TypeName 'HttpsBinding'
                }
                elseif ($line -match "\s+(.*\S)\s+:\s(.+)")
                {
                    # Line with content
                    $key   = $Matches[1]
                    $value = $Matches[2]

                    # Fill the object with info
                    switch ($key)
                    {
                        'IP:port'                                                { $obj.IpPort                                           = $value }
                        'Hostname:port'                                          { $obj.HostnamePort                                     = $value }
                        'Certificate Hash'                                       { $obj.CertificateHash                                  = $value }
                        'Verify Client Certificate Revocation'                   { $obj.VerifyClientCertificateRevocation                = $value }
                        'Verify Revocation Using Cached Client Certificate Only' { $obj.VerifyRevocationUsingCachedClientCertificateOnly = $value }
                        'Usage Check'                                            { $obj.UsageCheck                                       = $value }
                        'Revocation Freshness Time'                              { $obj.RevocationFreshnessTime                          = $value }
                        'URL Retrieval Timeout'                                  { $obj.URLRetrievalTimeout                              = $value }
                        'Ctl Identifier'                                         { $obj.CtlIdentifier                                    = $value }
                        'Ctl Store Name'                                         { $obj.CtlStoreName                                     = $value }
                        'DS Mapper Usage'                                        { $obj.DSMapperUsage                                    = $value }
                        'Negotiate Client Certificate'                           { $obj.NegotiateClientCertificate                       = $value }
                        'Reject Connections'                                     { $obj.RejectConnections                                = $value }
                        'Disable HTTP2'                                          { $obj.DisableHTTP2                                     = $value }
                        'Certificate Store Name'                                 { if ($value -ne '(null)') {$obj.CertificateStoreName   = $value}}
                        'Application ID'
                        {
                            $obj.ApplicationId = $value
                            if ($script:applicationIdLookupTable.ContainsKey([System.String] $obj.ApplicationId))
                            {
                                $obj.Application = $script:applicationIdLookupTable[[System.String] $obj.ApplicationId]
                            }
                        }
                    }
                }
            }
        }
        catch
        {
            # If error was encountered inside this function then stop doing more
            # But still respect the ErrorAction that comes when calling this function
            # And also return the line number where the original error occured
            $msg = $_.ToString() + "`r`n" + $_.InvocationInfo.PositionMessage.ToString()
            Write-Verbose -Message "Encountered an error: $msg"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception -Message $msg
        }
        finally
        {
            $ErrorActionPreference = $origErrorActionPreference
        }
    }

    process
    {
        Write-Verbose -Message "Process begin (ErrorActionPreference: $ErrorActionPreference)"

        try
        {
            # Stop execution inside this function, and catch the error
            $ErrorActionPreference = 'Stop'

            # Default parameters used when calling other functions
            $defaultParam = @{
                Verbose     = $verbose
                ErrorAction = $ErrorActionPreference
            }

            $return = $netshArray

            # Quick and dirty filtering
            if ($Certificate)          { $return = $return | Where-Object -FilterScript {$_.Certificate.PSPath   -eq $Certificate.PSPath  } }
            if ($Binding)              { $return = $return | Where-Object -FilterScript {$_.Binding              -eq $Binding             } }
            if ($IpPort)               { $return = $return | Where-Object -FilterScript {$_.IpPort               -eq $IpPort              } }
            if ($HostnamePort)         { $return = $return | Where-Object -FilterScript {$_.HostnamePort         -eq $HostnamePort        } }
            if ($Port)                 { $return = $return | Where-Object -FilterScript {$_.Port                 -eq $Port                } }
            if ($IPAddress)            { $return = $return | Where-Object -FilterScript {$_.IPAddress            -eq $IPAddress           } }
            if ($HostHeader)           { $return = $return | Where-Object -FilterScript {$_.HostHeader           -eq $HostHeader          } }
            if ($CertificateHash)      { $return = $return | Where-Object -FilterScript {$_.CertificateHash      -eq $CertificateHash     } }
            if ($ApplicationId)        { $return = $return | Where-Object -FilterScript {$_.ApplicationId        -eq $ApplicationId       } }
            if ($CertificateStoreName) { $return = $return | Where-Object -FilterScript {$_.CertificateStoreName -eq $CertificateStoreName} }
            if ($Protocol)             { $return = $return | Where-Object -FilterScript {$_.Protocol             -eq $Protocol            } }
            if ($BindingInformation)
            {
                # FIXXXME - parameterset so both BindingInformation and SslFlags are set
                <#
                    IIS BindingInformation SslFlags      Net sh binding
                    *:443:                 0             0.0.0.0:443
                    1.2.3.4:443:           0             1.2.3.4:443
                    *:443:host.name        0             0.0.0.0:443
                    1.2.3.4:443:host.name  0             1.2.3.4:443
                    *:443:host.name        1             host.name:443
                    1.2.3.4:443:host.name  1             host.name:443
                #>
                if ($BindingInformation -match '(.*):(.*):(.*)')
                {
                    $return = $return | Where-Object -FilterScript {$_.Port -eq $Matches[2]}
                    if ($SslFlags)
                    {
                        # SNI
                        $return = $return | Where-Object -FilterScript {$_.HostHeader -eq $Matches[3]}
                    }
                    else
                    {
                        # Not SNI
                        $return = $return | Where-Object -FilterScript {$_.IPAddress -eq $Matches[1]}
                    }
                }
                else
                {
                    # Not in correct IIS binding format
                    $return = $null
                }

            }

            # Return
            $return
        }
        catch
        {
            # If error was encountered inside this function then stop doing more
            # But still respect the ErrorAction that comes when calling this function
            # And also return the line number where the original error occured
            $msg = $_.ToString() + "`r`n" + $_.InvocationInfo.PositionMessage.ToString()
            Write-Verbose -Message "Encountered an error: $msg"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception -Message $msg
        }
        finally
        {
            $ErrorActionPreference = $origErrorActionPreference
        }

        Write-Verbose -Message 'Process end'
    }

    end
    {
        $ErrorActionPreference = $origErrorActionPreference
        Write-Verbose -Message 'End'
    }
}
