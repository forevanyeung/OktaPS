Function Enable-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id of the group rule
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [OktaGroupRule]
        $Rule
    )

    $activatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/$($rule.id)/lifecycle/activate"

    Return $activatedRule
}
