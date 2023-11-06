Function Disable-OktaUser {
    [CmdletBinding()]
    param (
        # id, login, or login shortname (as long as it is unambiguous) of user
        [Parameter()]
        [OktaUser]
        $User,

        # Sends an activation email to the user
        [Parameter()]
        [switch]
        $SendEmail = $false,

        # Perform an asynchronous user deactivation
        [Parameter()]
        [Switch]
        $Async = $false

        # Prompts you for confirmation before running the cmdlet.
        # [Parameter()]
        # [Switch]
        # $Confirm = $true
    )

    $headers = @{}
    $query = @{}

    If($Async) {
        $headers['Prefer'] = "respond-async"
    }

    If($SendEmail) {
        $query['sendEmail'] = $true
    }

    Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($User.id)/lifecycle/deactivate" -Headers $headers -Query $query
}