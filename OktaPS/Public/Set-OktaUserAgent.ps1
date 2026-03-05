Function Set-OktaUserAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [String]
        $UserAgent
    )

    Write-Verbose "Setting custom user agent string: $UserAgent"

    If([String]::IsNullOrEmpty($UserAgent)) {
        Remove-Variable -Name "OktaUserAgentString" -Scope Script
    } else {
        Set-Variable -Name "OktaUserAgentString" -Scope Script -Value $UserAgent
    }
}
