Function Connect-OktaPrivateKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $OktaDomain,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $ClientId,

        # Parameter help description
        [Parameter(Mandatory)]
        [String[]]
        $Scopes,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $PrivateKey
    )

    $OAuthUrl = "$OktaDomain/oauth2/v1/token"
    $payload = @{
        "aud" = $OAuthUrl
        "iss" = $ClientId
        "sub" = $ClientId
    }

    $jwt = New-JsonWebToken -Claims $payload -HashAlgorithm SHA256 -PrivateKey $PrivateKey

    # Get an limited lifetime access token
    $auth = Invoke-RestMethod -Method "POST" -Uri $OAuthUrl -Body @{
        "grant_type" = "client_credentials"
        "scope" = $Scopes -join " "
        "client_assertion_type" = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        "client_assertion" = $jwt
    }

    Set-OktaAuthentication -AuthorizationMode "PrivateKey" -Domain $OktaDomain -ClientId $ClientId -Token $auth.access_token -RefreshToken $auth.refresh_token -ExpiresIn $auth.expires_in

    Return
}
