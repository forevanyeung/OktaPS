Function Disable-OktaUser {
    <#
    .SYNOPSIS
        Deactivates a user.
    .DESCRIPTION
        Deactivates a user.

        Perform this operation only on users that do not have a DEPROVISIONED status.

        The user's transitioningToStatus property is DEPROVISIONED during deactivation to indicate that the user hasn't completed the asynchronous operation.
        The user's status is DEPROVISIONED when the deactivation process is complete.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/deactivateuser
    .EXAMPLE
        Get-OktaUser anna.unstoppable | Disable-OktaUser
        Deactivates user anna.unstoppable.
    #>

    [CmdletBinding()]
    param(
        # An ID, login, or login shortname (as long as the shortname is unambiguous) of an existing Okta user
        [Parameter(Mandatory = $True)]
        [OktaUser]
        $User,

        # Sends a deactivation email to the admin
        [Parameter()]
        [Switch]
        $SendEmail,

        # Performs user deactivation asynchronously
        [Parameter()]
        [Switch]
        $NoWait
    )

    $header = @{}
    If ($NoWait) {
        $header['Prefer'] = "respond-async"
    }

    $query = @{}
    If ($SendEmail) {
        $query['sendEmail'] = $True
    }

    Return Invoke-OktaRequest -Method POST -Endpoint "api/v1/users/$($User.Id)/lifecycle/deactivate" -Headers $header -Query $query
}
