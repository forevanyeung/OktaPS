<#
.SYNOPSIS
    Activates a specific group rule.
.DESCRIPTION
    Activates a specific group rule.
.INPUTS
    OktaGroupRule
.OUTPUTS
    None
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/activateGroupRule
.EXAMPLE
    Enable-OktaGroupRule -Rule "0pr3f7zMZZHPgUoWO0g4"
    Activates a specific group rule by ID.
.EXAMPLE
    Get-OktaGroupRule -Id "0pr3f7zMZZHPgUoWO0g4" | Enable-OktaGroupRule
    Activates a specific group rule with group rule object from pipeline.
#>
Function Enable-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id or object of a group rule
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [OktaGroupRule]
        $Rule
    )

    $activatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/$($rule.id)/lifecycle/activate"

    Return $activatedRule
}
