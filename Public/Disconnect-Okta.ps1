Function Disconnect-Okta {
    [CmdletBinding()]
    param ()

    Write-Verbose "Disconnecting Okta session"

    # do we need a valid session to delete?
    Invoke-RestMethod -Method "DELETE" -Uri "$Script:OktaDomain/api/v1/sessions/me" -WebSession $Script:OktaSSO -ContentType "application/json"

    Clear-OktaAuthentication
}