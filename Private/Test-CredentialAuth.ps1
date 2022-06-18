Function Test-CredentialAuth {
    [CmdletBinding()]
    param ()

    If($Script:OktaSSOExpirationUTC) {
        Write-Verbose "Time left until expires: $(($Script:OktaSSOExpirationUTC - (get-date).ToUniversalTime()).tostring())"

        Return $True
    } else {
        Return $False
    }
}