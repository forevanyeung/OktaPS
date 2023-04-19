Function Enable-OktaGroupRule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Rule
    )

    $activatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/${ruleId}/lifecycle/activate"

    Return $activatedRule
}