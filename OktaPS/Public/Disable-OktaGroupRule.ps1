Function Disable-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id of the group rule
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [OktaGroupRule]
        $Rule
    )

    $deactivatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/$($Rule.id)/lifecycle/deactivate"

    Return $deactivatedRule
}
