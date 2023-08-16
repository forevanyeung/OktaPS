Function Wait-OktaUserTransitionStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [OktaUser]
        $User,

        # The user's expected status after the transitioning process is complete
        [Parameter(Mandatory=$true)]
        [String]
        $ExpectedStatus
    )
    
    While($Wait) {
        $user_status = Get-OktaUser -Identity $User.Id

        # is there a race condition here? 
        If($null -eq $user_status.transitioningToStatus) {
            Write-Verbose "Status transitioning process is complete"

            # Sanity check to make sure the status matches the expected outcome
            If($user_status.status -ne $ExpectedStatus) {
                Write-Error "There was an error transitioning the user status. User is $($user_status.status)"
            }

            Break
        }

        Write-Verbose "User ($($User.Id)) status is transitioning to $($user_status.transitioningToStatus)"
        Start-Sleep -Seconds 1
    }
}