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
        $Script:SuppressAdminAPIWarning = $False
    }

    If($Disable) {
        $Script:SuppressAdminAPIWarning = $True
    }
}