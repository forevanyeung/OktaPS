Function Revoke-OktaOAuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $OktaDomain,

        [Parameter()]
        [String]
        $ClientId,

        [Parameter()]
        [String]
        $Token
    )

    Invoke-WebRequest -Method "POST" -Uri "$OktaDomain/oauth2/v1/revoke" -Body @{
        client_id = $ClientId
        token = $Token
    }
}
