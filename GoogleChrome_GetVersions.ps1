$ChromeVersion = '119.0.6045.106'

$requestId = ([String][Guid]::NewGuid()).ToUpper()
$sessionId = ([String][Guid]::NewGuid()).ToUpper()

$arch = 'x64'
$osplatform = 'win'
$osversion = '10.0'
$channel = 'stable'

$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<request protocol="3.0" updater="Omaha" sessionid="{$sessionId}"
    installsource="update3web-ondemand" requestid="{$requestId}">
    <os platform="$osplatform" version="$osversion" arch="$arch" />
    <app appid="{8A69D345-D564-463C-AFF1-A69D9E530F96}" ap="$arch-$channel-statsdef_0" lang="" brand="GCEB">
        <updatecheck targetversionprefix="$ChromeVersion"/>
    </app>
</request>
"@

$webRequest = @{
    Method    = 'Post'
    Uri       = 'https://tools.google.com/service/update2'
    Headers   = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
        'X-Goog-Update-Interactivity' = 'fg'
    }
    Body      = $xml
}

$result = Invoke-WebRequest @webRequest -UseBasicParsing
$contentXml = [xml]$result.Content
$status = $contentXml.response.app.updatecheck.status
if ($status -eq 'ok') {
    $package = $contentXml.response.app.updatecheck.manifest.packages.package
    $urls = $contentXml.response.app.updatecheck.urls.url | ForEach-Object {
        if ($_.codebase.Contains("https://dl.google.com")) {
            $_.codebase + $package.name
            $InstallCommand_Windows = "Install Command (Windows): $($package.name) --verbose-logging --do-not-launch-chrome --channel=$channel --system-level {8A69D345-D564-463C-AFF1-A69D9E530F96}"
            $InstallCommand_Windows
        }
    }
    Write-Output "--- Chrome Windows $arch found. (Hash=$($package.hash) Hash_sha256=$($package.hash_sha256) Size=$($package.size)). ---"
    Write-Output $urls
}
else {
    Write-Output "Chrome not found (status: $status)"
}