Function Invoke-OktaRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Method,

        [Parameter()]
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
    If($Script:OktaAPI) {

        $built_headers = @{
            Accept = "application/json"
            "Content-Type" = "application/json"
            Authorization = "SSWS $OKTA_API"
        }

    } elseif ($Script:OktaSSO) {

        If($Script:OktaSSOExpirationUTC -lt (Get-Date).ToUniversalTime()) {
            # if expired, check for new expiration
            $session = Invoke-RestMethod -Method "GET" -Uri "https://$OktaDomain/api/v1/sessions/me" -WebSession $Script:OktaSSO -ContentType "application/json" -ErrorAction SilentlyContinue
            Write-Host "cached expiration expired, trying to renew session"
            
            If($session.status -eq "ACTIVE") {
                $Script:OktaSSOExpirationUTC = $session.expiresAt
                Break
            } else {
                Write-Host "Okta session expired ($Script:OktaSSOExpirationUTC)"
                Remove-Variable OktaSSO,OktaSSOExpirationUTC -Scope Script
                Connect-Okta -OktaOrg $Script:OktaOrg
            }
        }

        If($Script:OktaXSRF) {
            $built_headers['X-Okta-XsrfToken'] = $Script:OktaXSRF
        }

        $webrequest_parameters['WebSession'] = $Script:OktaSSO

    } else {
        Connect-Okta
        $OktaDomain = $Script:OktaAdminDomain

        $webrequest_parameters['WebSession'] = $Script:OktaSSO
    }

    # Build request headers
    Foreach($k in $Headers.Keys) {
        $built_headers[$k] = $Headers[$k]
    }

    # Body
    If($Body) {
        $webrequest_parameters['Body'] = $Body
    }

    # Request
    $response = Invoke-WebRequest -Method $Method -Uri "https://$OktaDomain/$Endpoint" -Headers $built_headers -SkipHeaderValidation @webrequest_parameters
    
    # supports pagination
    $return = [System.Collections.ArrayList]@()
    $run_once = $True
    while($run_once -or ($response.RelationLink.ContainsKey('next'))) {
        $run_once = $False

        # Response
        If($PassThru) {
            $return += $response

            # supports pagination
            If($response.RelationLink.ContainsKey('next')) {
                $response = Invoke-WebRequest -Method $Method -Uri $response.RelationLink['next'] -Headers $built_headers -SkipHeaderValidation @webrequest_parameters
            }

        } elseif(($response.StatusCode -ge 200) -and ($response.StatusCode -le 299)) {
            $return += ($response.Content | ConvertFrom-Json)
            
            # supports pagination
            If($response.RelationLink.ContainsKey('next')) {
                $response = Invoke-WebRequest -Method $Method -Uri $response.RelationLink['next'] -Headers $built_headers -SkipHeaderValidation @webrequest_parameters
            }
        
        } elseif ($response.StatusCode -eq 429) {
            $limit_reset = (([System.DateTimeOffset]::FromUnixTimeSeconds($response.Headers['x-rate-limit-reset'])).DateTime).ToString()
            Write-Host "Okta Rate Limit Exceeded. $limit_reset"
            # wait until time elapses and continue
        
        } else {
            Return $response
        }
    }

    Return $return 
}