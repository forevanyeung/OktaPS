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
        $Script:OktaSetting.SuppressAdminAPIWarning = $False
    }

    If($Disable) {
        $Script:OktaSetting.SuppressAdminAPIWarning = $True
    }
}