Function Suspend-OktaUser {
    <#
    .SYNOPSIS
        Suspends a user. The user has a SUSPENDED status when the process completes.
    .DESCRIPTION
        Suspends a user. Perform this operation only on users with an ACTIVE status. The user has a SUSPENDED status when the process completes.
        
        Suspended users can't sign in to Okta. They can only be unsuspended or deactivated. Their group and app assignments are retained.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/suspenduser
    .EXAMPLE
        Get-OktaUser anna.unstoppable | Suspend-OktaUser
        Suspends user anna.unstoppable
    #>

    [CmdletBinding()]
    param(
        # An ID, login, or login shortname (as long as the shortname is unambiguous) of an existing Okta user
        [Parameter(Mandatory = $True)]
        [OktaUser]
        $User
    )

    Return Invoke-OktaRequest -Method POST -Endpoint "api/v1/users/$($User.Id)/lifecycle/suspend"
}
