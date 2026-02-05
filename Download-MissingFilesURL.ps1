New-Item -Path "D:\MissingFilesURL\FailedURL.txt" -Force

$DestFolder = "D:\AGDownloads\"
$URLS = Get-Content -Path "D:\MissingFilesURL\MissingsURLS.txt"
$URLS | ForEach-Object -Process {
    $URI = $_.toString().Trim()
    $Filename = $_.Substring($_.lastindexof("/")+1).Trim()
    $DestinationFile = "$DestFolder$Filename"
    try {
        Invoke-WebRequest -Uri $URI -OutFile $DestinationFile
        $hash = Get-FileHash -Path $DestinationFile
        Rename-Item -Path $DestinationFile -NewName $hash.hash
    } catch {
        Add-Content -Value $URI -Path "D:\MissingFilesURL\FailedURL.txt" -Force
    }
}