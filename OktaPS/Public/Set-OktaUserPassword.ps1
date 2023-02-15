Function Set-OktaUserPassword {
    [CmdletBinding(DefaultParameterSetName="PasswordChange")]
    param (
        [Parameter(ParameterSetName="PasswordChange", Position=0, ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName="PasswordReset", Position=0, ValueFromPipeline, Mandatory)]
        [OktaUser]
        $Identity,

        [Parameter(ParameterSetName="PasswordChange", Mandatory)]
        [SecureString]
        $OldPassword,

        [Parameter(ParameterSetName="PasswordChange", Mandatory)]
        [SecureString]
        $NewPassword,

        [Parameter(ParameterSetName="PasswordReset", Mandatory)]
        [Switch]
        $Reset,

        [Parameter(ParameterSetName="PasswordReset")]
        [Switch]
        $AsPlainText
    )

    switch($PSCmdlet.ParameterSetName) {
        "PasswordChange" { 
            $null = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($Identity.id)/credentials/change_password" -Body @{
                "oldPassword" = @{ "value" = (ConvertFrom-SecureString $OldPassword -AsPlainText) }
                "newPassword" = @{ "value" = (ConvertFrom-SecureString $NewPassword -AsPlainText) }
            }
    
            Return 
        }

        "PasswordReset" {
            If($AsPlainText) {
                $tempPassword = Reset-OktaUserPassword -Identity $Identity -AsPlainText
            } else {
                $tempPassword = Reset-OktaUserPassword -Identity $Identity
            }
    
            Return $tempPassword
        }

        Default {
            throw [System.ArgumentOutOfRangeException] "Unknown parameter set: $($PSCmdlet.ParameterSetName)"
        }
    }
}
