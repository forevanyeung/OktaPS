Function Set-OktaUserAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [AllowEmptyString()]
        [String]
        $UserAgent
    )

    Write-Verbose "Setting custom user agent string: $UserAgent"

    If([String]::IsNullOrEmpty($UserAgent)) {
        Remove-Variable -Name "OktaUserAgentString" -Scope Script -ErrorAction SilentlyContinue
    } else {
        Set-Variable -Name "OktaUserAgentString" -Scope Script -Value $UserAgent
    }
}
