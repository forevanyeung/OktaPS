Function Enable-OktaUser {
    [CmdletBinding()]
    param (
        # 
        [Parameter(Mandatory=$true)]
        [OktaUser]
        $User,

        # Sends an activation email to the user if True
        [Parameter()]
        [Boolean]
        $SendEmail = $true,

        # Parameter help description
        [Parameter()]
        [Switch]
        $Wait
    )

    Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/users/$($User.Id)/lifecycle/activate" -Query @{ sendEmail = $SendEmail }

    # Pause returning the response while waiting for the user status to finish transitioning
    If($Wait) {
        Wait-OktaUserTransitionStatus -User $User -ExpectedStatus "ACTIVE"
    }
}