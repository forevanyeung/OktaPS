Function Invoke-OktaRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [String]
        $Method = "GET",

        [Parameter(Mandatory, Position = 0)]
        [String]
        $Endpoint,

        [Parameter()]
        [Hashtable]
        $Headers,

        [Parameter()]
        [Hashtable]
        $Query,

        [Parameter()]
        [Hashtable]
        $Body,

        [Parameter()]
        [Switch]
        $PassThru,

        [Parameter()]
        [Switch]
        $NoPagination
    )

    $webrequest_parameters = @{}
    $built_headers = @{}

    # Check cache for valid session cookies and expiration
    If($Script:OktaAuth.SSO) {
        If(-not (Test-OktaAuthentication)) {
            Update-OktaAuthentication
        }
    } else {
        Connect-Okta
    }

    $webrequest_parameters['Method'] = $Method
    $webrequest_parameters['WebSession'] = $Script:OktaAuth.SSO
    $webrequest_parameters['SkipHeaderValidation'] = $True
    #TODO: can decrease request duration, need more testing, will need to bump mininum
    #pwsh version to 7.4
    #$webrequest_parameters['ProgressAction'] = "SilentlyContinue"

    If($Script:OktaAuth.XSRF) {
        $built_headers['X-Okta-XsrfToken'] = $Script:OktaAuth.XSRF
    }

    # Query parameters
    If($Query) {
        $url_builder = @{}
        Foreach($k in $Query.Keys) {
            $url_builder[$k] = $Query[$k]
        }
        $querystring = New-HttpQueryString -QueryParameter $url_builder

        $Endpoint = $Endpoint + "?" + $querystring
    }

    # Body
    If($Body) {
        $built_headers['Accept'] = "application/json"
        $built_headers['Content-Type'] = "application/json"

        $webrequest_parameters['Body'] = $Body | ConvertTo-Json -Depth 99
    }

    # Add User-Agent header
    if (-not $built_headers.ContainsKey('User-Agent')) {
        $built_headers['User-Agent'] = Get-OktaUserAgent
    }

    # Build request headers
    Foreach($k in $Headers.Keys) {
        $built_headers[$k] = $Headers[$k]
        Write-Debug "Adding header to request ${k}: $Headers[$k]"
    }

    $webrequest_parameters['Headers'] = $built_headers

    # Request
    # TODO: Add ability to send request to OktaDomain or OktaAdminDomain (default)
    $request_uri = "$($Script:OktaAuth.AdminDomain)/$Endpoint"
    $webrequest_parameters['Uri'] = $request_uri

    if ($PSCmdlet.ShouldProcess($request_uri)) {
        # supports pagination
        $next = $True
        $stepUpAttempted = $false
        $return = while($next) {
            $Script:OktaAuth.DebugLastRequestUri = $webrequest_parameters['Uri']
            try {
                Write-Debug ($webrequest_parameters | ConvertTo-Json -Depth 10)
                $response = Invoke-WebRequest @webrequest_parameters
            } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                $statusCode = $_.Exception.Response.StatusCode.value__

                # Step-up authentication challenge: Okta returns 401 with
                # WWW-Authenticate: error="insufficient_user_authentication" when
                # an action requires recent MFA. Elevate the existing session
                # via OIDC step-up entry, then retry the original request.
                $wwwAuth = ''
                try { $wwwAuth = ($_.Exception.Response.Headers.GetValues('WWW-Authenticate')) -join ' ' } catch {}
                If($statusCode -eq 401 -and $wwwAuth -match 'insufficient_user_authentication' -and -not $stepUpAttempted) {
                    $stepUpAttempted = $true

                    Write-Host "Okta requires step-up authentication for this action."

                    $stepUpParams = @{}
                    If($wwwAuth -match 'max_age="?(\d+)"?') {
                        $stepUpParams['MaxAge'] = [int]$Matches[1]
                    }
                    If($wwwAuth -match 'acr_values="([^"]+)"') {
                        $stepUpParams['AcrValues'] = $Matches[1]
                    }

                    Invoke-OktaStepUp @stepUpParams -ErrorAction Stop

                    Continue
                }

                Write-Error "Status code: $statusCode"
                If($_.Exception.Response.StatusCode -eq 429) {
                    Write-Debug "X-Rate-Limit-Limit: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Limit'))"
                    Write-Debug "X-Rate-Limit-Remaining: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Remaining'))"
                    Write-Debug "X-Rate-Limit-Reset: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Reset'))"

                    $limit_reset = [System.DateTimeOffset]::FromUnixTimeSeconds($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Reset')[0])
                    $offset = $limit_reset.Offset.TotalSeconds
                    Write-Host "Okta Rate Limit Exceeded. $($limit_reset.LocalDateTime.ToString())"

                    # TODO: wait until time elapses and continue
                    Start-Sleep -Seconds $offset
                } else {
                    Throw $_
                }
            } catch {
                Write-Host "Unknown error occurred."
                Throw $_
            }

            # Response
            If($PassThru) {
                $response

            } elseif(($response.StatusCode -ge 200) -and ($response.StatusCode -le 299)) {
                $response.Content | ConvertFrom-Json
                
            } else {
                # uncaught status code, return the raw and exit
                Return $response
            }

            # pagination
            If($response.RelationLink.ContainsKey('next') -and ($NoPagination -eq $False)) {
                $nextUri = [uri]$response.RelationLink['next']
                $nextPath = $nextUri.PathAndQuery
                $webrequest_parameters['Uri'] = "$($Script:OktaAuth.AdminDomain)/$nextPath"
            } else {
                $next = $False
            }
        }
    }
    
    Return $return 
}