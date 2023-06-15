Function Send-OktaFactorProviderOkta {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $VerifyUrl,

        [Parameter(Mandatory=$true)]
        [String]
        $StateToken,

        [Parameter()]
        [String]
        $Passcode
    )

    # Verify request body, add the passcode if it's provided
    # create it outside of the loop since it is only set once
    $req_body = @{ "stateToken" = $StateToken }
    If($Passcode) {
        $req_body["passCode"] = $Passcode
    }

    $status = ""
    while($status -ne "SUCCESS") {
        switch($status) {
            "CANCELLED" {
                Write-Warning "Push notification cancelled"
                Return
            }
            "ERROR" {
                Write-Warning "Push notification error"
                Return
            }
            "FAILED" {
                Write-Warning "Push notification failed"
                Return
            }
            "REJECTED" {
                Write-Warning "Push notification rejected"
                Return
            }
            "TIMEOUT" {
                Write-Warning "Push notification timed out"
                Return
            }
            "TIME_WINDOW_EXCEEDED" {
                Write-Warning "Push notification time window exceeded"
                Return
            }
        }
        
        $okta_verify = Invoke-RestMethod -Uri $VerifyUrl -Method "POST" -Body ($req_body | ConvertTo-Json) -ContentType "application/json" -WebSession $OktaSSO

        $status = $okta_verify.status
    }

    $session_token = $okta_verify.sessionToken

    Return $session_token
}
