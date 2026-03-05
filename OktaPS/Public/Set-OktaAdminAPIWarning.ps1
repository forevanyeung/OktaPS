Function Set-OktaAdminAPIWarning {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="Enable", Mandatory)]
        [Switch]
        $Enable,

        [Parameter(ParameterSetName="Disable", Mandatory)]
        [Switch]
        $Disable
    )

    If($Enable) {
        $Script:OktaSuppressAdminAPIWarning = $False
    }

    If($Disable) {
        $Script:OktaSuppressAdminAPIWarning = $True
    }
}