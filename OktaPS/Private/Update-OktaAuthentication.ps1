Function Update-OktaAuthentication {
    param (
        [Switch]$RefreshOnly
    )

    Switch($Script:OktaAuth.AuthorizationMode) {
        "AuthorizationCode" {
            If(-not $Script:OktaAuth.OAuthRefreshToken) {
                Write-Host "No refresh token found, cannot refresh token"
                Break
            }

            $refresh = Invoke-RestMethod -Method "POST" -Uri "$($Script:OktaAuth.Domain)/oauth2/v1/token" -Body @{
                "grant_type"    = "refresh_token"
                "client_id"     = $Script:OktaAuth.OAuthClientId
                "refresh_token" = ($Script:OktaAuth.OAuthRefreshToken | ConvertFrom-SecureString -AsPlainText)
            } -ContentType "application/x-www-form-urlencoded" -ErrorAction SilentlyContinue

            Set-OktaAuthentication -AuthorizationMode "AuthorizationCode" -Domain $Script:OktaAuth.Domain -ClientId $Script:OktaAuth.OAuthClientId -Token $refresh.access_token -RefreshToken $refresh.refresh_token -ExpiresIn $refresh.expires_in
        }

        "PrivateKey" {
            # TODO: fix to renew same authorization from client id, since connect-okta might choose a different config file
            Connect-Okta
        }

        "Credential" {
            try {
                $session = Invoke-RestMethod -Method "POST" -Uri "$($Script:OktaAuth.Domain)/api/v1/sessions/me/lifecycle/refresh" -WebSession $Script:OktaAuth.SSO -ContentType "application/json" -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose "cached expiration expired, trying to renew session"
            }

            If($session.status -eq "ACTIVE") {
                $Script:OktaAuth.SSOExpirationUTC = $session.expiresAt
                Write-Verbose "session renewed, updated expiration to $($Script:OktaAuth.SSOExpirationUTC) UTC"
                Break
            }

            If($RefreshOnly) {
                Stop-OktaSessionRefreshTimer
                $Host.UI.WriteWarningLine("Okta session refresh failed ($($Script:OktaAuth.SSOExpirationUTC) UTC). Re-run Connect-Okta to re-authenticate.")
                Break
            }

            Write-Host "Okta session expired ($($Script:OktaAuth.SSOExpirationUTC) UTC)"
            Connect-Okta -OrgUrl $Script:OktaAuth.Domain -Credential $Script:OktaAuth.Username
        }

        "SSWS" {
            Write-Verbose "API key does not expire, no refresh needed"
        }

        Default {
            Connect-Okta
        }
    }
}
