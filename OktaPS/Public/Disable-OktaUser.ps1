Function Disable-OktaUser {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # id, login, or login shortname (as long as it is unambiguous) of user
        [Parameter(ValueFromPipeline, Position=0)]
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

    Begin {   
        $headers = @{}
        $query = @{}
            
        If($Async) {
            $headers['Prefer'] = "respond-async"
        }
        
        If($SendEmail) {
            $query['sendEmail'] = $true
        }
    }
    
    Process {
        Foreach($u in $User) {
            if ($PSCmdlet.ShouldProcess($u.login)) {
                Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($u.id)/lifecycle/deactivate" -Headers $headers -Query $query
            }
        }
    }

    End {

    }
}
