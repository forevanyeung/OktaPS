Function Invoke-OktaRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [Parameter(Mandatory)]
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
        $NoPagination,

        [Parameter()]
        [Switch]
        $NoAsync
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

    # Build request headers
    Foreach($k in $Headers.Keys) {
        $built_headers[$k] = $Headers[$k]
        Write-Debug "Adding header to request ${k}: $Headers[$k]"
    }

    # Request
    # TODO: Add ability to send request to OktaDomain or OktaAdminDomain (default)
    $request_uri = "$Script:OktaAdminDomain/$Endpoint"

    if ($PSCmdlet.ShouldProcess($request_uri)) {
        # supports pagination
        $next = $True

        if($Method -eq "GET" -and $NoAsync -eq $False) {
            Write-Verbose "Collecting pagination links"

            $paginationCollector = while($next) {
                $response = Invoke-WebRequest -Method "HEAD" -Uri $request_uri -Headers $built_headers -SkipHeaderValidation @webrequest_parameters

                # sent url to collector
                $request_uri
                
                # pagination
                If($response.RelationLink.ContainsKey('next') -and ($NoPagination -eq $False)) {
                    $request_uri = $response.RelationLink['next']
                } else {
                    $next = $False
                }
            }

            Write-Verbose "Collected $($paginationCollector.Count) pages for pagination"

            $return = $paginationCollector | ForEach-Object -ThrottleLimit 5 -Parallel {
                $response = Invoke-WebRequest -Method $using:Method -Uri $_ -Headers $using:built_headers -SkipHeaderValidation @using:webrequest_parameters

                If($using:PassThru) {
                    $response
                } elseif(($response.StatusCode -ge 200) -and ($response.StatusCode -le 299)) {
                    $response.Content | ConvertFrom-Json
                } else {
                    # uncaught status code, return the raw and exit
                    Return $response
                }
            }

            Return $return

        } else {
            $return = while($next) {
                $Script:OktaDebugLastRequestUri = $request_uri
                try {
                    $response = Invoke-WebRequest -Method $Method -Uri $request_uri -Headers $built_headers -SkipHeaderValidation @webrequest_parameters

                    Write-Verbose $request_uri
                } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                    If($_.Exception.Response.StatusCode -eq 429) {
                        Write-Debug "X-Rate-Limit-Limit: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Limit'))"
                        Write-Debug "X-Rate-Limit-Remaining: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Remaining'))"
                        Write-Debug "X-Rate-Limit-Reset: $($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Reset'))"

                        $limit_reset = [System.DateTimeOffset]::FromUnixTimeSeconds($_.Exception.Response.Headers.GetValues('X-Rate-Limit-Reset')[0])
                        $offset = $limit_reset.Offset.TotalSeconds
                        Write-Host "Okta Rate Limit Exceeded. $($limit_reset.LocalDateTime.ToString())"

                        # TODO: wait until time elapses and continue
                        Start-Sleep -Seconds $offset
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
                    $request_uri = $response.RelationLink['next']
                } else {
                    $next = $False
                }
            }
        }
    }
    
    Return $return 
}
