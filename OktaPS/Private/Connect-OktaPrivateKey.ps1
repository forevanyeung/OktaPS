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

    $key = $PrivateKey.replace("-----BEGIN PRIVATE KEY-----","").replace("-----END PRIVATE KEY-----","")
    $keyB = [System.Convert]::FromBase64String($key)

    $jwt = New-JsonWebToken -Claims $payload -HashAlgorithm SHA256 -PrivateKey $keyB

    # Get an limited lifetime access token
    $auth = Invoke-RestMethod -Method "POST" -Uri $OAuthUrl -Body @{
        "grant_type" = "client_credentials"
        "scope" = $Scopes -join " "
        "client_assertion_type" = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        "client_assertion" = $jwt
    }

    # use IWR to create a web session variable
    $null = Invoke-WebRequest -Uri $OktaDomain -SessionVariable OktaSSO
    $OktaSSO.Headers.Add("Authorization", "$($auth.token_type) $($auth.access_token)")

    Set-OktaAuthentication -AuthorizationMode "PrivateKey" -Session $OktaSSO -Domain $OktaDomain -ExpiresIn $auth.expires_in

    Return
}