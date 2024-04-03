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

        [OktaGroupRule]@{
            id = $_.id
            type = $_.type
            name = $_.name
            created = $_.created 
            lastUpdated = $_.lastUpdated
            status = $_.status
            actions = $_.actions
            conditions = $_.conditions
        }
    }
}
