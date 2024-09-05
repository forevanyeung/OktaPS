Function ConvertTo-OktaGroupRule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object[]]
        $GroupRule
    )

    $GroupRule | ForEach-Object {
        If($null -eq $_) {
            return 
        }

        [GroupRule]@{
            actions = $_.actions
            conditions = $_.conditions
            created = $_.created
            id = $_.id
            lastUpdated = $_.lastUpdated
            name = $_.name
            status = $_.status
            type = $_.type
        }
    }
}
