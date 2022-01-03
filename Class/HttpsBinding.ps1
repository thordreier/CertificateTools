class HttpsBinding
{
    [System.String]
    $Binding

    [System.String]
    $IpPort

    [System.String]
    $HostnamePort

    [System.String]
    $CertificateHash

    [System.Guid]
    $ApplicationId

    [System.String]
    $CertificateStoreName

    [System.String] # Maybe better type should be found
    $VerifyClientCertificateRevocation

    [System.String] # Maybe better type should be found
    $VerifyRevocationUsingCachedClientCertificateOnly

    [System.String] # Maybe better type should be found
    $UsageCheck

    [System.String] # Maybe better type should be found
    $RevocationFreshnessTime

    [System.String] # Maybe better type should be found
    $URLRetrievalTimeout

    [System.String] # Maybe better type should be found
    $CtlIdentifier

    [System.String] # Maybe better type should be found
    $CtlStoreName

    [System.String] # Maybe better type should be found
    $DSMapperUsage

    [System.String] # Maybe better type should be found
    $NegotiateClientCertificate

    [System.String] # Maybe better type should be found
    $RejectConnections

    [System.String] # Maybe better type should be found
    $DisableHTTP2

    [System.Security.Cryptography.X509Certificates.X509Certificate]
    $Certificate

    [System.String]
    $Application

    # Used when piping object to Get-WebBinding
    [System.String]
    $Protocol = 'https'

    # Used when piping object to Get-WebBinding
    [System.UInt16]
    $Port

    # Used when piping object to Get-WebBinding
    [System.String]
    $IPAddress

    # Used when piping object to Get-WebBinding
    [System.String]
    $HostHeader
}
