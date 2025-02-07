Function Update-OktaAuthentication {
    Switch($Script:OktaAuthorizationMode) {
        "AuthorizationCode" {
            If(-not $Script:OktaOAuthRefreshToken) {
                Write-Host "No refresh token found, cannot refresh token"
                Break
            }

            $refresh = Invoke-RestMethod -Method "POST" -Uri "$Script:OktaDomain/oauth2/v1/token" -Body @{
                "grant_type" = "refresh_token"
                "client_id" = $Script:OktaOAuthClientId
                "refresh_token" = ($Script:OktaOAuthRefreshToken | ConvertFrom-SecureString -AsPlainText)
            } -ContentType "application/x-www-form-urlencoded" -ErrorAction SilentlyContinue

            Set-OktaAuthentication -AuthorizationMode "AuthorizationCode" -Domain $Script:OktaDomain -ClientId $Script:OktaOAuthClientId -Token $refresh.access_token -RefreshToken $refresh.refresh_token -ExpiresIn $refresh.expires_in
        }

        "PrivateKey" {
            # TODO: fix to renew same authorization from client id, since connect-okta might choose a different config file
            Connect-Okta
        }

        "Credential" {
            try {
                $session = Invoke-RestMethod -Method "POST" -Uri "$OktaDomain/api/v1/sessions/me/lifecycle/refresh" -WebSession $Script:OktaSSO -ContentType "application/json" -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose "cached expiration expired, trying to renew session"
            }
            
            If($session.status -eq "ACTIVE") {
                $Script:OktaSSOExpirationUTC = $session.expiresAt
                Write-Verbose "session renewed, updated expiration to $Script:OktaSSOExpirationUTC UTC"
                Break
            }

            Write-Host "Okta session expired ($Script:OktaSSOExpirationUTC UTC)"
            # Remove-Variable OktaSSO,OktaSSOExpirationUTC -Scope Script
            Connect-Okta -OrgUrl $Script:OktaDomain -Credential $Script:OktaUsername
        }

        "SSWS" {
            Write-Verbose "API key does not expire, no refresh needed"
        }

        Default {
            Connect-Okta
        }
    }
}
