Function ConvertTo-OktaApp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject[]]
        $InputObject
    )

    $InputObject | ForEach-Object {
        Add-Member -InputObject $_ -TypeName "Okta.App"
    }

    Return $InputObject
}