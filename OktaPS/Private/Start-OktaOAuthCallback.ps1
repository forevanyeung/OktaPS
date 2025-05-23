function Start-OktaOAuthCallback {
    param (
        [Parameter(Mandatory, Position = 0)]
        [Int]
        $Port,

        [Parameter()]    
        [Int]
        $Timeout = 30
    )

    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    Write-Verbose "Listening on port for authentication callback $Port..."

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while ($listener.IsListening) {
        if ($stopwatch.Elapsed.TotalSeconds -ge $Timeout) {
            Write-Error "Timeout ($($Timeout)s) exceeded waiting for authentication callback"
            $listener.Stop()
            return $null
        }

        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        if ($request.Url.AbsolutePath -eq "/login/callback") {
            $queryParams = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
            Write-Verbose "Received request to /login/callback"

            If("code" -notin $queryParams.Keys -or [string]::IsNullOrEmpty($queryParams["code"])) {
                $responseString = "There was an error receiving authorization code, please try again. You can close this window."
            } else {
                $responseString = "Authorization code received. You can close this window."
            }

            # Need to convert HttpQSCollection into a Hashtable because of the way it's serialized
            $queryHashtable = @{}
            foreach ($key in $queryParams.AllKeys) {
                $queryHashtable[$key] = $queryParams[$key]
            }

            $html = "<html><head><title>OktaPS Authorization</title></head><body style=`"text-align:center;font-family:sans-serif;margin-top:120px;`">$responseString</body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            $listener.Stop()

            return $queryHashtable
        } else {
            $response.StatusCode = 404
            $response.Close()
            $listener.Stop()

            return $null
        }
    }
}
