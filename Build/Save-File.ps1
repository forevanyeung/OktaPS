Function Save-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Uri]
        $Uri,

        [Parameter()]
        [String]
        $Destination = $(Get-Location),

        [Parameter()]
        [Switch]
        $SkipContentTypeCheck
    )

    # using HttpClient since IWR does not return LocalPath
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $http = [System.Net.Http.HttpClient]::new($handler)
    [void]$http.DefaultRequestHeaders.UserAgent.TryParseAdd("oktaps")

    # download file
    $dataMsg = $http.GetAsync($Uri)
    $dataMsg.Wait()

    if (!$dataMsg.IsCanceled) {
        $response = $dataMsg.Result

        if ($response.IsSuccessStatusCode) {
            # check content-type to make sure we're downloading the right file
            If($SkipContentTypeCheck -eq $false) {
                If($response.Content.Headers.ContentType.MediaType -notlike "application/*") {
                    Write-Host "Did not detect an application in Content-Type, skipping download"
                    Throw
                }
            }

            # get filename from Content-Disposition header
            If($response.Content.Headers.Key -contains "Content-Disposition") {
                $filename = $response.Content.Headers.ContentDisposition.FileName
            } else {
                $fUri = $response.RequestMessage.RequestUri
                $filename = [System.IO.Path]::GetFileName($fUri.LocalPath)
            }

            # Make absolute local path
            if (![System.IO.Path]::IsPathRooted($filename)) {
                $filepath = Join-Path $Destination $filename
            }

            $downloadedFileStream = [System.IO.FileStream]::new($filepath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            
            $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)

            Write-Verbose "Downloading ..."
            $copyStreamOp.Wait()

            $downloadedFileStream.Close()
            if ($null -ne $copyStreamOp.Exception) {
                throw $copyStreamOp.Exception
            }
        }
    } else {
        Write-Error "Download failed"
    }

    $http.Dispose()

    $item = Get-Item $filepath
    Return $item
}
