Function Set-OktaUserAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [AllowEmptyString()]
        [String]
        $UserAgent
    )

    Write-Verbose "Setting custom user agent string: $UserAgent"
    $Script:OktaSetting.UserAgentString = [String]::IsNullOrEmpty($UserAgent) ? $null : $UserAgent
}
