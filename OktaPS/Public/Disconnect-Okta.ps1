Function Disconnect-Okta {
    [CmdletBinding()]
    param ()

    Write-Verbose "Disconnecting Okta session"

    # Ends the session or revokes the token
    switch ($Script:OktaAuth.AuthorizationMode) {
        AuthorizationCode {
            Revoke-OktaOAuthToken -OktaDomain $Script:OktaAuth.Domain -ClientId $Script:OktaAuth.OAuthClientId -Token ($Script:OktaAuth.OAuthToken | ConvertFrom-SecureString -AsPlainText)
        }

        Credential {
            Invoke-RestMethod -Method "DELETE" -Uri "$($Script:OktaAuth.Domain)/api/v1/sessions/me" -WebSession $Script:OktaAuth.SSO -ContentType "application/json" -ErrorAction SilentlyContinue
        }

        Default {}
    }

    # Clear the Okta session variables
    Clear-OktaAuthentication
}
