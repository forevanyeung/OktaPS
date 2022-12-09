Function Test-OktaAuthentication {
    [CmdletBinding()]
    param ()

    If(-not $Script:OktaSSO) {
        Write-Verbose "No Okta SSO session found"
        Return $False
    }

    If($Script:OktaAuthorizationMode -eq "SSWS") {
        Write-Verbose "API key does not expire"
        Return $True
    }

    $NowUTC = (Get-Date).ToUniversalTime()
    If($Script:OktaSSOExpirationUTC -gt $NowUTC) {
        Write-Verbose "Time left until expires: $(($Script:OktaSSOExpirationUTC - $NowUTC).tostring())"

        Return $True
    } else {
        Write-Verbose "Token expired: $Script:OktaSSOExpirationUTC UTC"

        Return $False
    }
}