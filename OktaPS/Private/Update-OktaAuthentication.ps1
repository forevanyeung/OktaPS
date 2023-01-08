Function Update-OktaAuthentication {
    Switch($Script:OktaAuthorizationMode) {
        "PrivateKey" {
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
