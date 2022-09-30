Function Connect-OktaAPI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $OktaDomain,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $API
    )

    # use IWR to create a web session variable
    $null = Invoke-WebRequest -Uri $OktaDomain -SessionVariable OktaSSO
    $OktaSSO.Headers.Add("Authorization", "SSWS $API")

    # test API key is valid
    Try {
        $null = Invoke-WebRequest -Uri "$OktaDomain/api/v1/users/me" -Method "GET" -WebSession $OktaSSO
    } Catch {
        throw
    }

    Set-OktaAuthentication -AuthorizationMode "SSWS" -Session $OktaSSO -Domain $OktaDomain

    Return
}