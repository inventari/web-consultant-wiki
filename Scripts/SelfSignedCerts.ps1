#Requires -RunAsAdministrator
#Note this is only to be used in Dev Environment and is not suitible for production.

$rootCAName = ('Local Development CA '+(get-date -Format yy))
$signedCertName = ('Localhost Development Certificate '+(get-date -Format yyyy))
$dnsName = "localhost"

$rootCAObject = Get-ChildItem -Path cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN="+$rootCAName}
if ($rootCAObject -eq $null) {
    Write-Host "Create CA"
    $params = @{
      DnsName = $rootCAName
      KeyLength = 4096
      KeyAlgorithm = 'RSA'
      HashAlgorithm = 'SHA256'
      KeyExportPolicy = 'Exportable'
      NotAfter = (Get-Date).AddYears(10)
      CertStoreLocation = 'Cert:\LocalMachine\My'
      KeyUsage = 'CertSign','CRLSign' #fixes invalid cert error
      FriendlyName = $rootCAName
    }
    $rootCA = New-SelfSignedCertificate @params
    
    # Extra step needed since self-signed cannot be directly shipped to trusted root CA store
    # if you want to silence the cert warnings on other systems you'll need to import the rootCA.crt on them too

    #Create certs folder

    if (!(Test-Path "C:\certs" -PathType Container)) {
        New-Item -ItemType Directory -Force -Path "C:\certs"
    }
    Export-Certificate -Cert $rootCA -FilePath ("C:\certs\rootCA" + (get-date -Format yyyyMMdd) + ".crt")
    Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath ("C:\certs\rootCA" + (get-date -Format yyyyMMdd) + ".crt")
} else { 
    Write-Host "CA Exists"
} 


$signedCertObject = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN="+$dnsName -and $_.Issuer -eq  "CN="+$rootCAName -and $_.FriendlyName -eq $signedCertName}
if ($signedCertObject -eq $null) {
    Write-Host "Create Signed Certificate"
    $params = @{
      DnsName = $dnsName
      Signer = (Get-ChildItem -Path cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN="+$rootCAName})
      KeyLength = 4096
      KeyAlgorithm = 'RSA'
      HashAlgorithm = 'SHA256'
      KeyExportPolicy = 'Exportable'
      NotAfter = (Get-date).AddYears(2)
      CertStoreLocation = 'Cert:\LocalMachine\My'
      FriendlyName = $signedCertName
    }
    $devCert = New-SelfSignedCertificate @params
    Export-Certificate -Cert $devCert -FilePath ("C:\certs\localhostCert" + (get-date -Format yyyyMMdd) + ".crt")
} else { 
    Write-Host "Signed Certificate Exists"
} 
