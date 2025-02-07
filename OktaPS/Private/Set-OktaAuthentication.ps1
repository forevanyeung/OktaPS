Function Set-OktaAuthentication {
    [CmdletBinding(DefaultParameterSetName = "SSWS")]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [ValidateSet("SSWS", "PrivateKey", "Credential", "AuthorizationCode")]
        [String]
        $AuthorizationMode,

        [Parameter(ParameterSetName="SSWS", Mandatory)]
        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $Domain,

        # Parameter help description
        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [String]
        $ClientId,

        # Parameter help description
        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [String]
        $Token,

        # Parameter help description
        [Parameter(ParameterSetName="OAuth")]
        [String]
        $RefreshToken,

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

    $Script:OktaDomain = $Domain
    Write-Verbose "Setting OktaDomain to $Script:OktaDomain"
    
    $Uri = [System.Uri]$Domain
    $domainParts = $Uri.Host.Split('.')
    $Script:OktaOrg = $domainParts[0]
    Write-Verbose "Setting OktaOrg to $Script:OktaOrg"

    $Script:OktaAdminDomain = Get-OktaAdminDomain -Domain $Domain
    Write-Verbose "Setting OktaAdminDomain to $Script:OktaAdminDomain"

    If($PSCmdlet.ParameterSetName -eq "OAuth") {
        # use IWR to create a web session variable
        $null = Invoke-WebRequest -Uri $OktaDomain -SessionVariable OktaSSO
        $OktaSSO.Headers.Add("Authorization", "Bearer $Token")
        $Script:OktaSSO = $OktaSSO
        Write-Verbose "Creating OktaSSO web session and adding Bearer authentication header"

        $Script:OktaOAuthClientId = $ClientId
        Write-Verbose "Setting OktaOAuthClientId to $Script:OktaOAuthClientId"

        $Script:OktaOAuthToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
        Write-Verbose "Setting OktaOAuthToken"

        $Script:OktaOAuthRefreshToken = $RefreshToken ? (ConvertTo-SecureString -String $RefreshToken -AsPlainText -Force) : ""
        Write-Verbose "Setting OktaOAuthRefreshToken"

        $expiration = (Get-Date).AddSeconds($ExpiresIn).ToUniversalTime()
        $Script:OktaSSOExpirationUTC = $expiration
        Write-Verbose "Setting OktaSSOExpirationUTC to $Script:OktaSSOExpirationUTC"
    }

    If($PSCmdlet.ParameterSetName -eq "Credentials") {
        $Script:OktaSSO = $Session
        Write-Verbose "Setting OktaSSO web session"

        $Script:OktaSSOExpirationUTC = $ExpiresAt
        Write-Verbose "Setting OktaSSOExpirationUTC to $Script:OktaSSOExpirationUTC"

        $Script:OktaUsername = $Username
        Write-Verbose "Setting OktaUsername to $Script:OktaUsername"
    }
}
