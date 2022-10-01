Function Invoke-OktaRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Method = "GET",

        [Parameter(Mandatory)]
        [String]
        $Endpoint,

        [Parameter()]
        [Hashtable]
        $Headers,

        [Parameter()]
        [Hashtable]
        $Body,

        [Parameter()]
        [String]
        $OktaDomain = $Script:OktaAdminDomain,

        [Parameter()]
        [Switch]
        $PassThru
    )

    $webrequest_parameters = @{}
    $built_headers = @{}

    # Check cache for valid session cookies and expiration
    If($Script:OktaSSO) {
        If(-not (Test-OktaAuthentication)) {
            Update-OktaAuthentication
        }
    } else {
        Connect-Okta
    }

    $webrequest_parameters['WebSession'] = $Script:OktaSSO

    If($Script:OktaXSRF) {
        $built_headers['X-Okta-XsrfToken'] = $Script:OktaXSRF
    }

    # Body
    If($Body) {
        $built_headers['Accept'] = "application/json"
        $built_headers['Content-Type'] = "application/json"

        $webrequest_parameters['Body'] = $Body | ConvertTo-Json
    }

    # Build request headers
    Foreach($k in $Headers.Keys) {
        $built_headers[$k] = $Headers[$k]
        Write-Debug "Adding header to request ${k}: $Headers[$k]"
    }

    # Request
    $request_uri = "$OktaDomain/$Endpoint"

    # supports pagination
    $next = $True
    $return = while($next) {
        $Script:OktaDebugLastRequestUri = $request_uri
        $response = Invoke-WebRequest -Method $Method -Uri $request_uri -Headers $built_headers -SkipHeaderValidation @webrequest_parameters

        # Response
        If($PassThru) {
            $response

        } elseif(($response.StatusCode -ge 200) -and ($response.StatusCode -le 299)) {
            $response.Content | ConvertFrom-Json
            
        
        } elseif ($response.StatusCode -eq 429) {
            $limit_reset = (([System.DateTimeOffset]::FromUnixTimeSeconds($response.Headers['x-rate-limit-reset'])).DateTime).ToString()
            Write-Host "Okta Rate Limit Exceeded. $limit_reset"
            # wait until time elapses and continue
        
        } else {
            # uncaught status code, return the raw and exit
            Return $response
        }

        # pagination
        If($response.RelationLink.ContainsKey('next')) {
            $request_uri = $response.RelationLink['next']
        } else {
            $next = $False
        }
    }

    Return $return 
}