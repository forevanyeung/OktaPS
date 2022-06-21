Function Test-CredentialAuth {
    [CmdletBinding()]
    param ()

    $NowUTC = (Get-Date).ToUniversalTime()

    If($Script:OktaSSOExpirationUTC -gt $NowUTC) {
        Write-Verbose "Time left until expires: $(($Script:OktaSSOExpirationUTC - $NowUTC).tostring())"

        Return $True
    } else {
        Return $False
    }
}