# Okta sometimes hates a user agent string that doesn't have the OS platform in it. This function will generate a user 
# agent string that includes the PowerShell version, the OS platform, the OS version, and the OktaPS version.
Function New-UserAgentString {
    $pwshVersion = $PSVersionTable.PSVersion.ToString()

    $osPlatform = switch ($PSVersionTable.os.Split(' ')[0]) {
        "Microsoft" { "Windows NT" }
        "Darwin" { "Mac OS X" }
        "Linux" { "Linux" }
        Default { "Unknown" }
    }

    # TODO
    $oktaPSVersion = "0.0.0"

    $userAgentString = "PowerShell/{0} ({1} {2}) OktaPS/{3}" -f $pwshVersion, $osPlatform, $osVersion, $oktaPSVersion

    Return $userAgentString
}
