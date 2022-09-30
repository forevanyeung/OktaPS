Function Get-OktaAdminDomain {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Domain
    )

    $Uri = [System.Uri]$Domain
    $domainParts = $Uri.Host.Split('.')
    $domainParts[0] = $domainParts[0] + "-admin"
    $OktaAdminDomain = $domainParts -join '.'

    Return "https://$OktaAdminDomain"
}