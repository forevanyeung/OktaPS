<#
.SYNOPSIS
    Deletes a specific group rule.
.DESCRIPTION
    Deletes a specific group rule.
.INPUTS
    OktaGroupRule
.OUTPUTS
    None
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/deleteGroupRule
.EXAMPLE
    Remove-OktaGroupRule -Rule "0pr3f7zMZZHPgUoWO0g4"
    Deletes a specific group rule by ID.
.EXAMPLE
    Get-OktaGroupRule -Id "0pr3f7zMZZHPgUoWO0g4" | Remove-OktaGroupRule
    Deletes a specific group rule with group rule object from pipeline.
#>
Function Remove-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id or object of the group rule
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [OktaGroupRule]
        $Rule
    )

    $deletedRule = Invoke-OktaRequest -Method "DELETE" -Endpoint "/api/v1/groups/rules/$($Rule.id)"

    Return $deletedRule
}
