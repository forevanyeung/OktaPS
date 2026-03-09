Function Set-OktaAuthentication {
    [CmdletBinding(DefaultParameterSetName = "SSWS")]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("SSWS", "PrivateKey", "Credential", "AuthorizationCode")]
        [String]
        $AuthorizationMode,

        [Parameter(ParameterSetName="SSWS", Mandatory)]
        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        [Parameter(Mandatory)]
        [String]
        $Domain,

        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [String]
        $ClientId,

        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [String]
        $Token,

        [Parameter(ParameterSetName="OAuth")]
        [String]
        $RefreshToken,

        [Parameter(ParameterSetName="OAuth", Mandatory)]
        [Int32]
        $ExpiresIn,

        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [System.DateTime]
        $ExpiresAt,

        [Parameter(ParameterSetName="Credentials", Mandatory)]
        [String]
        $Username
    )

    $Script:OktaAuth.AuthorizationMode = $AuthorizationMode
    Write-Verbose "Setting AuthorizationMode to $($Script:OktaAuth.AuthorizationMode)"

    $Script:OktaAuth.Domain = $Domain
    Write-Verbose "Setting Domain to $($Script:OktaAuth.Domain)"

    $Uri = [System.Uri]$Domain
    $Script:OktaAuth.Org = $Uri.Host.Split('.')[0]
    Write-Verbose "Setting Org to $($Script:OktaAuth.Org)"

    $Script:OktaAuth.AdminDomain = Get-OktaAdminDomain -Domain $Domain
    Write-Verbose "Setting AdminDomain to $($Script:OktaAuth.AdminDomain)"

    If($PSCmdlet.ParameterSetName -eq "OAuth") {
        $null = Invoke-WebRequest -Uri $Domain -SessionVariable OktaSSO
        $OktaSSO.Headers.Add("Authorization", "Bearer $Token")
        $Script:OktaAuth.SSO = $OktaSSO
        Write-Verbose "Creating SSO web session and adding Bearer authentication header"

        $Script:OktaAuth.OAuthClientId = $ClientId
        Write-Verbose "Setting OAuthClientId to $($Script:OktaAuth.OAuthClientId)"

        $Script:OktaAuth.OAuthToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
        Write-Verbose "Setting OAuthToken"

        $Script:OktaAuth.OAuthRefreshToken = $RefreshToken ? (ConvertTo-SecureString -String $RefreshToken -AsPlainText -Force) : ""
        Write-Verbose "Setting OAuthRefreshToken"

        $Script:OktaAuth.SSOExpirationUTC = (Get-Date).AddSeconds($ExpiresIn).ToUniversalTime()
        Write-Verbose "Setting SSOExpirationUTC to $($Script:OktaAuth.SSOExpirationUTC)"
    }

    If($PSCmdlet.ParameterSetName -eq "SSWS") {
        $Script:OktaAuth.SSO = $Session
        Write-Verbose "Setting SSO web session"

        $Script:OktaAuth.SSOExpirationUTC = [datetime]::MaxValue
        Write-Verbose "Setting SSOExpirationUTC to max"
    }

    If($PSCmdlet.ParameterSetName -eq "Credentials") {
        $Script:OktaAuth.SSO = $Session
        Write-Verbose "Setting SSO web session"

        $Script:OktaAuth.SSOExpirationUTC = $ExpiresAt
        Write-Verbose "Setting SSOExpirationUTC to $($Script:OktaAuth.SSOExpirationUTC)"

        $Script:OktaAuth.Username = $Username
        Write-Verbose "Setting Username to $($Script:OktaAuth.Username)"
    }
}
