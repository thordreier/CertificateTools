function Set-HttpsBinding
{
    <#
        .SYNOPSIS
            Set/replace certificates on HTTPS bindings

        .DESCRIPTION
            Set/replace certificates on HTTPS bindings

            Microsofts own cmdlets:
            Add-NetIPHttpsCertBinding and Remove-NetIPHttpsCertBinding are just crap!!
            Remove-NetIPHttpsCertBinding removes ALL bindings, Add-NetIPHttpsCertBinding only works with IpPort (not HostnamePort) and there's no way to show/get bindings!

        .PARAMETER DryRun
            Only show what would be changed, but don't change it

        .PARAMETER ReplaceAllWithNewest
            Replace certificates on all bindings that have a newer certificate with same common name

        .PARAMETER Binding
            Replace certificate on this binding

        .PARAMETER IpPort
            Replace certificate on this binding

        .PARAMETER HostnamePort
            Replace certificate on this binding

        .PARAMETER OldCertificateHash
            Replace certificates on bindings that has certificates with this thumbprint

        .PARAMETER CertificateHash
            Replace binding with certificate with this thumbprint

        .PARAMETER ApplicationId
            Application ID of binding

        .PARAMETER CertificateStoreName
            Certificate store (normally just "My")

        .PARAMETER PfxPath
            Path to PFX file to use on binding - will be imported to certificate store

        .PARAMETER Exportable
            Should the private key for the imported PFX be exportable

        .PARAMETER Password
            Password for PFX file

        .PARAMETER PasswordClear
            Password for PFX file in clear text

        .EXAMPLE
            Set-HttpsBinding -ReplaceAllWithNewest -DryRun
            Replace certificates on all bindings where a newer certificate is found (same CN).
            But don't actuall run netsh - only show what would have run

        .EXAMPLE
            Set-HttpsBinding -IpPort 0.0.0.0:443 -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'
            Update binding on 0.0.0.0:443 with certificate with thumbprint 1234...

        .EXAMPLE
            Set-HttpsBinding -OldCertificateHash '4321fbc46bb66309ebd861be4f95062b7c9e5e61' -CertificateHash '12341cb21fc912af764f5fb491da6430c9ea73a8'
            Change all binding that use 4321... to 1234...

        .EXAMPLE
            Get-HttpsBinding -Port 44399 | Set-HttpsBinding -CertificateHash '1234fbc46bb66309ebd861be4f95062b7c9e5e61'
            Change all binding on TCP port 443399 to certificate with hash 1234...

        .EXAMPLE
            Set-HttpsBinding -HostnamePort 'www.foobar.tld:443' -PfxPath 'foobar.pfx' -Exportable -PasswordClear 'Password1!'
            Import foobar.pfx to certificate store (and make private key exportable)
            and change binding on www.foobar.tld:443 to use that certificate
    #>

    [CmdletBinding()]
    param
    (
        [Parameter()]
        [switch]
        $DryRun,

        [Parameter(ParameterSetName = 'replaceall',           Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $ReplaceAllWithNewest,

        [Parameter(ParameterSetName = 'binding',              Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'bindingpfx',           Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'bindingpfxclear',      Mandatory = $true, ValueFromPipeline = $true)]
        [HttpsBinding]
        $Binding,

        [Parameter(ParameterSetName = 'ipport',               Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfx',            Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfxclear',       Mandatory = $true)]
        [System.String]
        $IpPort,

        [Parameter(ParameterSetName = 'hostnameport',         Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfx',      Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfxclear', Mandatory = $true)]
        [System.String]
        $HostnamePort,

        [Parameter(ParameterSetName = 'oldhash',              Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfx',           Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfxclear',      Mandatory = $true)]
        [Alias('Old')]
        [System.String]
        $OldCertificateHash,

        [Parameter(ParameterSetName = 'binding',              Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipport',               Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameport',         Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhash',              Mandatory = $true)]
        [Alias('New')]
        [System.String]
        $CertificateHash,

        [Parameter(ParameterSetName = 'ipport'                                 )]
        [Parameter(ParameterSetName = 'ipportpfx'                              )]
        [Parameter(ParameterSetName = 'ipportpfxclear'                         )]
        [Parameter(ParameterSetName = 'hostnameport'                           )]
        [Parameter(ParameterSetName = 'hostnameportpfx'                        )]
        [Parameter(ParameterSetName = 'hostnameportpfxclear'                   )]
        [System.Guid]
        $ApplicationId,

        [Parameter(ParameterSetName = 'ipport'                                 )]
        [Parameter(ParameterSetName = 'ipportpfx'                              )]
        [Parameter(ParameterSetName = 'ipportpfxclear'                         )]
        [Parameter(ParameterSetName = 'hostnameport'                           )]
        [Parameter(ParameterSetName = 'hostnameportpfx'                        )]
        [Parameter(ParameterSetName = 'hostnameportpfxclear'                   )]
        [System.String]
        $CertificateStoreName,

        [Parameter(ParameterSetName = 'bindingpfx',           Mandatory = $true)]
        [Parameter(ParameterSetName = 'bindingpfxclear',      Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfx',            Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfxclear',       Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfx',      Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfxclear', Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfx',           Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfxclear',      Mandatory = $true)]
        [System.String]
        $PfxPath,

        [Parameter(ParameterSetName = 'bindingpfx'                             )]
        [Parameter(ParameterSetName = 'bindingpfxclear'                        )]
        [Parameter(ParameterSetName = 'ipportpfx'                              )]
        [Parameter(ParameterSetName = 'ipportpfxclear'                         )]
        [Parameter(ParameterSetName = 'hostnameportpfx'                        )]
        [Parameter(ParameterSetName = 'hostnameportpfxclear'                   )]
        [Parameter(ParameterSetName = 'oldhashpfx'                             )]
        [Parameter(ParameterSetName = 'oldhashpfxclear'                        )]
        [System.Management.Automation.SwitchParameter]
        $Exportable,

        [Parameter(ParameterSetName = 'bindingpfx',           Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfx',            Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfx',      Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfx',           Mandatory = $true)]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName = 'bindingpfxclear',      Mandatory = $true)]
        [Parameter(ParameterSetName = 'ipportpfxclear',       Mandatory = $true)]
        [Parameter(ParameterSetName = 'hostnameportpfxclear', Mandatory = $true)]
        [Parameter(ParameterSetName = 'oldhashpfxclear',      Mandatory = $true)]
        [System.String]
        $PasswordClear
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = ($PSBoundParameters.ContainsKey('Verbose') -and  $PSBoundParameters['Verbose'].IsPresent) -or ($VerbosePreference -ne 'SilentlyContinue')

        $certRootPath = 'Cert:\LocalMachine'
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

            if (! $Binding)
            {
                # Default to "Personal" if no store name was provided, or no store name was defined in existing binding
                if (! $CertificateStoreName)
                {
                    $CertificateStoreName = 'My'
                }
            }

            # Import certificate from PFX
            if ($PfxPath)
            {
                # Convert clear text password
                if ($PasswordClear)
                {
                    $Password = ConvertTo-SecureString -String $PasswordClear -Force -AsPlainText
                }

                $cert = Import-PfxCertificate @defaultParam -FilePath $PfxPath -Exportable:$Exportable -Password $Password -CertStoreLocation (Join-Path -Path $certRootPath -ChildPath $CertificateStoreName)

                # CertificateHash to use later in the function is this newly imported one
                $CertificateHash = $cert.Thumbprint
            }

            if ($ReplaceAllWithNewest)
            {
                # Loop through the different unique certificates used in bindings
                foreach ($oldCert in ((Get-HttpsBinding @defaultParam).Certificate | Sort-Object -Property 'PSPath' -Unique))
                {
                    try
                    {
                        $newCert = $oldCert | Find-NewestCertificate @defaultParam -HasPrivateKey
                        if ($oldCert.Thumbprint -eq $newCert.Thumbprint)
                        {
                            Write-Verbose -Message "No new certificate for `"$($oldCert.Subject)`""
                        }
                        else
                        {
                            # Replace all occurrences of one certificate with another - run recursive
                            # This has a flaw if the same certificate is found and used from different certificate stores - should not be a "real" problem!
                            Set-HttpsBinding @defaultParam -OldCertificateHash $oldCert.Thumbprint -CertificateHash $newCert.Thumbprint -DryRun:$DryRun
                        }
                    }
                    catch
                    {
                        Write-Warning -Message $_
                    }
                }
            }
            elseif ($OldCertificateHash)
            {
                # Replace all occurrences of one certificate with another - run recursive with Binding coming from pipeline
                Get-HttpsBinding @defaultParam -CertificateHash $OldCertificateHash | Set-HttpsBinding @defaultParam -CertificateHash $CertificateHash -DryRun:$DryRun
            }
            else
            {
                # Something else than ReplaceAllWithNewest or OldCertificateHash

                # Initialize som variables
                $cmds    = @()
                $cmdsrun = 0
                $id      = ''

                if ($Binding)
                {
                    # Binding provided as parameter (or from pipeline)
                    if ($Binding.IpPort)
                    {
                        # Binding is of type IpPort
                        $id = "ipport=$($Binding.IpPort)"
                    }
                    elseif ($Binding.HostnamePort)
                    {
                        # Binding is of type HostnamePort
                        $id = "hostnameport=$($Binding.HostnamePort)"
                    }
                }
                elseif ($IpPort)
                {
                    # IpPort provided as parameter
                    $Binding = Get-HttpsBinding @defaultParam -IpPort $IpPort
                    $id = "ipport=$($IpPort)"
                }
                elseif ($HostnamePort)
                {
                    # HostnamePort provided as parameter
                    $Binding = Get-HttpsBinding @defaultParam -HostnamePort $HostnamePort
                    $id = "hostnameport=$($HostnamePort)"
                }

                if ($Binding)
                {
                    # Existing binding found
                    Write-Verbose -Message "Existing binding for $($id) will be removed before new binding is added"

                    # Test/set application id
                    if ($ApplicationId -and ($ApplicationId -ne $Binding.ApplicationId))
                    {
                        Write-Warning -Message "ApplicationId for $($id) will be changed from $($Binding.ApplicationId) to $($ApplicationId)"
                    }
                    elseif (! $ApplicationId)
                    {
                        $ApplicationId = $Binding.ApplicationId
                    }

                    # Test/set certificate store
                    if ($CertificateStoreName -and ($CertificateStoreName -ne $Binding.CertificateStoreName))
                    {
                        Write-Warning -Message "CertificateStoreName for $($id) will be changed from $($Binding.CertificateStoreName) to $($CertificateStoreName)"
                    }
                    elseif (! $CertificateStoreName -and $Binding.CertificateStoreName)
                    {
                        $CertificateStoreName = $Binding.CertificateStoreName
                    }
                    else
                    {
                        # Default to "Personal" if no store name was provided, or no store name was defined in existing binding
                        $CertificateStoreName = 'My'
                    }

                    # Add command to remove existing binding to command queue
                    $cmds += "netsh http delete sslcert $($id)"
                }
                elseif (! $ApplicationId)
                {
                    Write-Error -Message "ApplicationId for $($id) not provided and no existing binding found"
                }

                # Validate if certificate can be found in certificate store
                if (! (Get-ChildItem -Path (Join-Path -Path $certRootPath -ChildPath $CertificateStoreName) | Where-Object -FilterScript {$_.Thumbprint -eq $CertificateHash}))
                {
                    Write-Error -Message "No certificate with hash $($CertificateHash) found in store $($CertificateStoreName)"
                }

                # Add command to add new binding to command queue
                $cmd = "netsh http add sslcert $($id) certhash=$($CertificateHash) appid='{$($ApplicationId)}' certstorename=$($CertificateStoreName)"
                if (! ($cmd -match "^[a-z0-9 '=\.:_{}-]+$"))
                {
                    # The check could be better! But linebreaks and semicolon isn't allowed, so command injection should'nt be possible
                    Write-Error -Message "What are you trying to do here!? Why are you trying to execute this stuff: $cmd"
                }
                $cmds += $cmd

                # Running the commands
                foreach ($cmd in $cmds)
                {
                    "Running: $cmd"
                    if (! $DryRun)
                    {
                        # Run command
                        Invoke-Expression -Command $cmd
                        if ($LASTEXITCODE)
                        {
                            Write-Error ("Encountered exit code $LASTEXITCODE running: $cmd`r`nAll commands that would have been executed:`r`n" + ($cmds -join "`r`n"))
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

        Write-Verbose -Message 'Process end'
    }

    end
    {
        $ErrorActionPreference = $origErrorActionPreference
        Write-Verbose -Message 'End'
    }
}
