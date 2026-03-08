Function Test-OktaAuthentication {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]
        $Full
    )

    If(-not $Script:OktaAuth.SSO) {
        Write-Verbose "No Okta SSO session found"
        Return $False
    }

    If($Script:OktaAuth.AuthorizationMode -eq "SSWS") {
        Write-Verbose "API key does not expire"
        Return $True
    }

    If($Script:OktaAuth.AuthorizationMode -eq "AuthorizationCode") {
        Try {
            $introspect = Invoke-RestMethod -Method "POST" -Uri "$($Script:OktaAuth.Domain)/oauth2/v1/introspect" -Body @{
                client_id = $Script:OktaAuth.OAuthClientId
                token     = ($Script:OktaAuth.OAuthToken | ConvertFrom-SecureString -AsPlainText)
            } -ContentType "application/x-www-form-urlencoded"

            If($Full) {
                Write-Host $introspect
            }

            If($introspect.active -eq $True) {
                $timeleft = ((Get-Date -UnixTimeSeconds $introspect.exp) - (Get-Date)).ToString()
                Write-Verbose "Time left until expires: $timeleft"
                Return $True
            } else {
                Write-Verbose "Token is not active"
                Write-Verbose "Token expired: $($Script:OktaAuth.SSOExpirationUTC) UTC"
                Return $False
            }

        } Catch {
            Write-Verbose "Failed to introspect token"
            Return $False
        }
    }

    # TODO: check introspect for PrivateKey
    # TODO: check session for Credential

    $NowUTC = (Get-Date).ToUniversalTime()
    If($Script:OktaAuth.SSOExpirationUTC -gt $NowUTC) {
        Write-Verbose "Time left until expires: $(($Script:OktaAuth.SSOExpirationUTC - $NowUTC).tostring())"
        Return $True
    } else {
        Write-Verbose "Token expired: $($Script:OktaAuth.SSOExpirationUTC) UTC"
        Return $False
    }
}
