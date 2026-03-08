Function Set-OktaUserAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [AllowEmptyString()]
        [String]
        $UserAgent
    )

    Write-Verbose "Setting custom user agent string: $UserAgent"
    $Script:OktaConfig.UserAgentString = [String]::IsNullOrEmpty($UserAgent) ? $null : $UserAgent
}
