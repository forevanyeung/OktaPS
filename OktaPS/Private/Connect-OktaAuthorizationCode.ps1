Function Connect-OktaAuthorizationCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $OktaDomain,

        [Parameter(Mandatory)]
        [String]
        $ClientId,

        [Parameter(Mandatory)]
        [String[]]
        $Scopes,

        [Parameter()]
        [String]
        $Port
    )

    $wellknown = Invoke-RestMethod -Method GET -Uri "$OktaDomain/.well-known/oauth-authorization-server"
    $authorization_endpoint = $wellknown.authorization_endpoint
    $token_endpoint = $wellknown.token_endpoint

    $pkce = New-PKCE
    $state = Get-Random

    $authorizeQuery = New-HttpQueryString -QueryParameter @{
        client_id = $ClientId
        response_type = "code"
        code_challenge_method = "S256"
        code_challenge = $pkce.code_challenge
        redirect_uri = "http://localhost:$Port/login/callback"
        scope = $Scopes -join " "
        state = $state
    }
    $authorizeUri = $authorization_endpoint + "?"  +$authorizeQuery

    # Start the HTTP listener in a background job
    $job = Start-Job -ScriptBlock ${Function:Start-OktaOAuthCallback} -ArgumentList $Port

    # Open the authorization URL in the default browser
    Start-Process -FilePath $authorizeUri

    # Wait for the HTTP listener job to complete
    $jobResult = Receive-Job -Job $job -Wait -AutoRemoveJob

    # Verify state
    If( "state" -notin $jobResult.Keys -or $jobResult.state -ne $state ) {
        Write-Error "State mismatch. Expected: $state, Received: $($jobResult.state)"
        Return
    }

    # Exchange an Authorization Code for a token
    $auth = Invoke-RestMethod -Method POST -Uri $token_endpoint -Body @{
        client_id = $ClientId
        grant_type = "authorization_code"
        code = $jobResult.code
        redirect_uri = "http://localhost:$Port/login/callback"
        code_verifier = $pkce.code_verifier
    }

    Set-OktaAuthentication -AuthorizationMode "AuthorizationCode" -Domain $OktaDomain -ClientId $ClientId -Token $auth.access_token -RefreshToken $auth.refresh_token -ExpiresIn $auth.expires_in

    Return
}
