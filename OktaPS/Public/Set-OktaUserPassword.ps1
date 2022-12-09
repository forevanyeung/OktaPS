Function Set-OktaUserPassword {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="PasswordChangeByIdentity", Position=0, Mandatory)]
        [Parameter(ParameterSetName="PasswordResetByIdentity", Position=0, Mandatory)]
        [String]
        $Identity,

        [Parameter(ParameterSetName="PasswordChangeByOktaUser", ValueFromPipeline, Mandatory)]
        [Parameter(ParameterSetName="PasswordResetByOktaUser", ValueFromPipeline, Mandatory)]
        [PSTypeName("Okta.User")]
        $OktaUser,

        [Parameter(ParameterSetName="PasswordChangeByIdentity", Mandatory)]
        [Parameter(ParameterSetName="PasswordChangeByOktaUser", Mandatory)]
        [SecureString]
        $OldPassword,

        [Parameter(ParameterSetName="PasswordChangeByIdentity", Mandatory)]
        [Parameter(ParameterSetName="PasswordChangeByOktaUser", Mandatory)]
        [SecureString]
        $NewPassword,

        [Parameter(ParameterSetName="PasswordResetByIdentity", Mandatory)]
        [Parameter(ParameterSetName="PasswordResetByOktaUser", Mandatory)]
        [Switch]
        $Reset,

        [Parameter(ParameterSetName="PasswordResetByIdentity")]
        [Parameter(ParameterSetName="PasswordResetByOktaUser")]
        [Switch]
        $AsPlainText
    )

    If($PSCmdlet.ParameterSetName -contains "ByIdentity") {
        $OktaUser = Get-OktaUser -Identity $Identity -ErrorAction Stop
    }

    If($PSCmdlet.ParameterSetName -contains "PasswordChange") {
        $null = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/users/$($OktaUser.id)/credentials/change_password" -Body @{
            "oldPassword" = @{ "value" = (ConvertFrom-SecureString $OldPassword -AsPlainText) }
            "newPassword" = @{ "value" = (ConvertFrom-SecureString $NewPassword -AsPlainText) }
        }

        Return 

    } else {
        If($AsPlainText) {
            $tempPassword = Reset-OktaUserPassword -OktaUser $OktaUser -AsPlainText
        } else {
            $tempPassword = Reset-OktaUserPassword -OktaUser $OktaUser
        }

        Return $tempPassword
    }
    
}