# TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls,
     [System.Net.SecurityProtocolType]::Tls11,
     [System.Net.SecurityProtocolType]::Tls12


         add-type @"
   using System.Net;
   using System.Security.Cryptography.X509Certificates;
   public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(
      ServicePoint srvPoint, X509Certificate certificate,
      WebRequest request, int certificateProblem) {
      return true;
   }
}
"@
# Ignore Certificate Errors
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Load System.Web Assembly
Add-Type -AssemblyName 'System.Web'

$cred = Get-Credential
$query = "concatenation `"%0d%0a`" of scripts of default actions of unique values of relevant fixlets whose (name of site of it is not contained by set of (`"ActionSite`";`"DMZ`")) of bes computers"
$encQuery = [System.Web.HttpUtility]::UrlEncode($query)
$URLSITE = "https://==BIGFIX==:52311/api/query?relevance=($encQuery)"
[xml]$res = Invoke-WebRequest -Uri $URLSITE -Method Get -Credential $cred

$scripts = $res.BESAPI.Query.Result.Answer.'#text'
$lines = $scripts.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)
$statements = $lines -match "sha256:"


$relevantPrefetchStatements = $statements
$sha1files = Get-ChildItem -Path "D:\Program Files (x86)\BigFix Enterprise\BES Server\wwwrootbes\bfmirror\downloads\sha1" | Select-Object Name
$file = New-Item -Path "D:\Scripts\MissingURLS.txt" -Force
 
$relevantPrefetchStatements | ForEach-Object -Process {
    $array = $_ -split " "
    $filename = $array[1]
    if ($array -match "sha1:") {
        $sha1 = $($array -match "sha1:").Substring(5)
    } else {
        $sha1 = "None"
    }
    if ($array -match "size:") {
        $size = $($array -match "size:").Substring(5)
    } else {
        $size = "None"
    }
    if ($array -match "http:") {
        $url = $array -match "http:"
    } elseif ($array -match "https:") {
        $url = $array -match "https:"
    } else {
        $url = "None"
    }
    if ($array -match "sha256:") {
        $sha256 = $($array -match "sha256:").Substring(7)
    } else {
        $sha256 = "None"
    }
    
    if ($url -notmatch "MANUAL_BES_CACHING_REQUIRED") {
        if ($sha1 -notmatch "None" -and $sha256 -notmatch "None") {
            if (-not ($sha1files -match $sha1 -or $sha1files -match $sha256)) {
                Write-Output $url | Out-File -FilePath $file -Append
            }
        } else {
            if (-not ($sha1files -match $sha256)) {
                Write-Output $url | Out-File -FilePath $file -Append
            }
        }
    }
 
}
