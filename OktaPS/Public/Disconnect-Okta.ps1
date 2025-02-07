Function Disconnect-Okta {
    [CmdletBinding()]
    param ()

    Write-Verbose "Disconnecting Okta session"

    # Ends the session or revokes the token
    switch ($Script:OktaAuthorizationMode) {
        AuthorizationCode { 
            Revoke-OktaOAuthToken -OktaDomain $Script:OktaDomain -ClientId $Script:OktaClientId -Token ($Script:OktaToken | ConvertFrom-SecureString -AsPlainText)
        }

        Credential {
            Invoke-RestMethod -Method "DELETE" -Uri "$Script:OktaDomain/api/v1/sessions/me" -WebSession $Script:OktaSSO -ContentType "application/json" -ErrorAction SilentlyContinue
        }

        Default {}
    }

    # Clear the Okta session variables
    Clear-OktaAuthentication
}
