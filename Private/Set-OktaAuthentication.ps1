Function Set-OktaAuthentication {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [ValidateSet("SSWS", "PrivateKey", "Credential")]
        [String]
        $AuthorizationMode,

        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $Domain,

        # Parameter help description
        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [Int32]
        $ExpiresIn,

        # Parameter help description
        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [System.DateTime]
        $ExpiresAt,

        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [String]
        $Username
    )

    $Script:OktaAuthorizationMode = $AuthorizationMode
    Write-Verbose "Setting OktaAuthorizationMode to $Script:OktaAuthorizationMode"
    $Script:OktaSSO = $Session
    Write-Verbose "Setting OktaSSO web session"
    $Script:OktaDomain = $Domain
    Write-Verbose "Setting OktaDomain to $Script:OktaDomain"
    
    $Uri = [System.Uri]$Domain
    $domainParts = $Uri.Host.Split('.')
    $Script:OktaOrg = $domainParts[0]
    Write-Verbose "Setting OktaOrg to $Script:OktaOrg"

    $Script:OktaAdminDomain = Get-OktaAdminDomain -Domain $Domain
    Write-Verbose "Setting OktaAdminDomain to $Script:OktaAdminDomain"

    If($PSCmdlet.ParameterSetName -eq "Credentials") {
        $Script:OktaSSOExpirationUTC = $ExpiresAt
        Write-Verbose "Setting OktaSSOExpirationUTC to $Script:OktaSSOExpirationUTC"

        $Script:OktaUsername = $Username
        Write-Verbose "Setting OktaUsername to $Script:OktaUsername"
    }

    If($PSCmdlet.ParameterSetName -eq "OAuth") {
        $now = (Get-Date).AddSeconds($ExpiresIn).ToUniversalTime()
        $Script:OktaSSOExpirationUTC = $now
        Write-Verbose "Setting OktaSSOExpirationUTC to $Script:OktaSSOExpirationUTC"
    }
}
