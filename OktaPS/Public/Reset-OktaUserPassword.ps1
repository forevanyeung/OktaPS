Function Reset-OktaUserPassword {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline, Mandatory)]
        [OktaUser]
        $Identity,

        [Parameter()]
        [Switch]
        $AsPlainText
    )

    $response = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($Identity.id)/lifecycle/expire_password" -Query @{"tempPassword" = "true"}
    $tempPassword = $response.tempPassword

    If($AsPlainText) {
        Return $tempPassword
    } else {
        Return ($tempPassword | ConvertTo-SecureString -AsPlainText)
    }
}
