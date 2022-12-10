Function Reset-OktaUserPassword {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="ByIdentity", Position=0, Mandatory)]
        [String]
        $Identity,

        [Parameter(ParameterSetName="ByOktaUser", ValueFromPipeline, Mandatory)]
        [PSTypeName("Okta.User")]
        $OktaUser,

        [Parameter()]
        [Switch]
        $AsPlainText
    )

    If($PSCmdlet.ParameterSetName -eq "ByIdentity") {
        $OktaUser = Get-OktaUser -Identity $Identity -ErrorAction Stop
    }

    $response = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($OktaUser.id)/lifecycle/expire_password" -Query @{"tempPassword" = "true"}
    $tempPassword = $response.tempPassword

    If($AsPlainText) {
        Return $tempPassword
    } else {
        Return ($tempPassword | ConvertTo-SecureString -AsPlainText)
    }
}