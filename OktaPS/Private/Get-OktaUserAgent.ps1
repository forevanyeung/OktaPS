Function Get-OktaUserAgent {
    <#
    .SYNOPSIS
    Generates a standardized User-Agent string for OktaPS module requests.

    .DESCRIPTION
    Creates a User-Agent header in the format: PowerShell/{version} ({OS}) OktaPS/{version}
    This identifies the module and environment to Okta services and Okta Verify.

    .EXAMPLE
    Get-OktaUserAgent
    Returns: "PowerShell/7.4.0 (Microsoft Windows 10.0.22631) OktaPS/1.0.0"
    #>
    [CmdletBinding()]
    param()

    $psVersion = $PSVersionTable.PSVersion.ToString()

    If($IsLinux) {
        $osVersion = "X11; Linux x86_64"
    } elseif ($IsMacOS) {
        $osVersion = "Macintosh; Intel Mac OS X 10_15_7"
    } elseif ($IsWindows) {
        $osVersion = "Windows NT 11.0; Win64; x64"
    } else {
        Write-Warning "Unknown OS platform, defaulting to generic OS version string, may result in issues."
        $osVersion = [System.Environment]::OSVersion.VersionString
    }

    # Get OktaPS module version
    $module = Get-Module OktaPS
    if ($module) {
        $moduleVersion = $module.Version.ToString()
    } else {
        $moduleVersion = "0.0.0"
    }

    return "PowerShell/$psVersion ($osVersion) OktaPS/$moduleVersion"
}
