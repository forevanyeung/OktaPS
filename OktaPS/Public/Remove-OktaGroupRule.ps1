Function Remove-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id of the group rule
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [OktaGroupRule]
        $Rule
    )

    $deletedRule = Invoke-OktaRequest -Method "DELETE" -Endpoint "/api/v1/groups/rules/$($Rule.id)"

    Return $deletedRule
}
