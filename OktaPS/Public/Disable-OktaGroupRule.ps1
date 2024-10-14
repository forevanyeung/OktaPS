<#
.SYNOPSIS
    Deactivates a specific group rule.
.DESCRIPTION
    Deactivates a specific group rule.
.INPUTS
    OktaGroupRule
.OUTPUTS
    None
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/deactivateGroupRule
.EXAMPLE
    Disable-OktaGroupRule -Rule "0pr3f7zMZZHPgUoWO0g4"
    Deactivates a specific group rule by ID.
.EXAMPLE
    Get-OktaGroupRule -Id "0pr3f7zMZZHPgUoWO0g4" | Disable-OktaGroupRule
    Deactivates a specific group rule with group rule object from pipeline.
#>
Function Disable-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id of the group rule
        [Parameter(Mandatory=$true, ValueFromPipeline, Position=0)]
        [OktaGroupRule]
        $Rule
    )

    $deactivatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/$($Rule.id)/lifecycle/deactivate"

    Return $deactivatedRule
}
