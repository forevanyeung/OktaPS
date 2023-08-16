# Deactivates a user. Returns an empty response if successful. 
Function Remove-OktaUser {
    [CmdletBinding()]
    param (
        # 
        [Parameter(Mandatory=$true)]
        [OktaUser]
        $User,

        # Sends an deactivation email to the administrator if True
        [Parameter()]
        [Boolean]
        $SendEmail = $true,

        # Wait for the deactivation operation to complete 
        [Parameter()]
        [Switch]
        $Wait
    )

    Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/users/$($User.Id)/lifecycle/deactivate" -Query @{ sendEmail = $SendEmail }

    # Pause returning the response while waiting for the user status to finish transitioning
    If($Wait) {
        Wait-OktaUserTransitionStatus -User $User -ExpectedStatus "DEACTIVATED"
    }
}