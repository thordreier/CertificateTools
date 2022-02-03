function Find-NewestCertificate
{
    <#
        .SYNOPSIS
            Find newest "version" of a SSL certificate

        .DESCRIPTION
            Find newest "version" of a SSL certificate
            Find the newest certificate based on common name (CN) - certificates are compared/matched based on the same CN
            Newest is the certificate with the highest NotAfter date
            If a non-wildcard certificate is provided, then a newer wildcard certificate will not be returned (because match is done on CN)

        .PARAMETER Certificate
            Find newest certificate based on (other older) certificate object

        .PARAMETER CertificateHash
            Find newest certificate based on certificate hash

        .PARAMETER CommonName
            Find newest certificate based on CN

        .PARAMETER CertStoreLocation
            Look for certificates in this location
            Defaults to Cert:\LocalMachine\My

        .PARAMETER HasPrivateKey
            Only return certificate if it has a private key

        .EXAMPLE
            Find-NewestCertificate -CertificateHash D5681CB21FC812AF764F5FB491DA6430C9EA73A9
            - Find the certificate with thumbprint D568.. from Cert:\LocalMachine\My
            - Take the common name from that certificate
            - Find the newest certificate, with the same common name, in Cert:\LocalMachine\My.
              (This certificate can be D568.., if that is already the newest)

        .EXAMPLE
            Find-NewestCertificate -CommonName '*.foobar.tld' -Path Cert:\LocalMachine\WebHosting -HasPrivateKey
            - Find the newest certificate with CN=*.foobar.tld that has a private key

        .EXAMPLE
            Get-Item -Path Cert:\LocalMachine\Root\75e0abb6138512271c04f85fddde38e4b7242efe | Find-NewestCertificate
            - 75e0... should be a root certificate with CN=GlobalSign that expire in 2021
            - It should return a certificate with same CN that expire in 2029 with thumbprint D69B...
              (at least on some computers)
    #>

    [OutputType('System.Security.Cryptography.X509Certificates.X509Certificate[]')]
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'certificate',     Mandatory = $true, ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        [Alias('Cert')]
        $Certificate,

        [Parameter(ParameterSetName = 'certificatehash', Mandatory = $true)]
        [System.String]
        [Alias('Hash','Thumbprint')]
        $CertificateHash,

        [Parameter(ParameterSetName = 'commonname',      Mandatory = $true)]
        [System.String]
        [Alias('CN')]
        $CommonName,

        [Parameter(ParameterSetName = 'certificatehash')]
        [Parameter(ParameterSetName = 'commonname'     )]
        [System.String]
        [Alias('Path','CertificateStore','CertificateStoreLocation','CertStore')]
        $CertStoreLocation = 'Cert:\LocalMachine\My',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        [Alias('PK','PrivateKey','Key')]
        $HasPrivateKey
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = ($PSBoundParameters.ContainsKey('Verbose') -and  $PSBoundParameters['Verbose'].IsPresent) -or ($VerbosePreference -ne 'SilentlyContinue')
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

            # Find common name based on certificate object or thumbprint
            if ($Certificate -or $CertificateHash)
            {
                if ($Certificate)
                {
                    $CertStoreLocation = $Certificate.PSParentPath
                }
                else
                {
                    $Certificate = Get-Item @defaultParam -Path (Join-Path -Path $CertStoreLocation -ChildPath $CertificateHash)
                }
                
                if ($Certificate.Subject -match 'CN=([^,]+)')
                {
                    $CommonName = $Matches[1]
                }
                else
                {
                    Write-Error -Message "Common name not found in certificate subject `"$($Certificate.Subject)`""
                }
            }

            # Find certificates with matching common name
            if ($certs = @(Get-ChildItem -Path $CertStoreLocation | Where-Object -FilterScript {($_.Subject -match 'CN=([^,]+)') -and ($Matches[1] -eq $CommonName)} | Sort-Object -Property 'NotAfter' -Descending))
            {
                if (! $HasPrivateKey -or ($certs = @($certs | Where-Object -Property 'HasPrivateKey' -EQ -Value $true)))
                {
                    # Return newest certificate
                    $certs[0]
                }
                else
                {
                    Write-Error -Message "Certificate with common name `"$($CommonName)`" found in $($CertStoreLocation), but not with a private key"
                }
            }
            else
            {
                Write-Error -Message "No certificates found in $($CertStoreLocation) with common name `"$($CommonName)`""
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
