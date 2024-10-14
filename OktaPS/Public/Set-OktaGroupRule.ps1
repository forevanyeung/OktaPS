<#
.SYNOPSIS
    Updates a group rule.
.DESCRIPTION
    Updates a group rule to dynamically add Users to the specified Group if they match the condition.
.INPUTS
    OktaGroupRule
.OUTPUTS
    OktaGroupRule
.NOTES
    You currently cannot update the group to which users are assigned to of a group rule. If you need to change the group, 
    you will need to delete the rule and create a new one.
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/replaceGroupRule
.EXAMPLE
    Update-OktaGroupRule -Rule "Engineering group rule" -Name "Engineering Team" -Force
    Updates the "Engineering group rule" group rule with the new name "Engineering Team". If the rule is active, it is 
    deactivated before updating and reactivated after updating.
.EXAMPLE
    Update-OktaGroupRule -Rule "Engineering group rule" -Force
    Updates the "Engineering group rule" a group rule that adds users to the Engineering group if their role is Engineer. The rule is activated after 
    creation.
#>
Function Set-OktaGroupRule {
    [CmdletBinding()]
    param (
        # The id or object of the group rule to update
        [Parameter(Mandatory=$true, ValueFromPipeline, Position=0, ParameterSetName="AtLeastOneName")]
        [Parameter(Mandatory=$true, ValueFromPipeline, Position=0, ParameterSetName="AtLeastOneExpression")]
        [Parameter(Mandatory=$true, ValueFromPipeline, Position=0, ParameterSetName="AtLeastOneExcludeUsers")]
        [OktaGroupRule]
        $Rule,

        # New name of the Group rule
        [ValidateLength(1,50)]
        [Parameter(Mandatory=$true, ParameterSetName="AtLeastOneName")]
        [Parameter(ParameterSetName="AtLeastOneExpression")]
        [Parameter(ParameterSetName="AtLeastOneExcludeUsers")]
        [string]
        $Name,

        # Defines Okta specific group-rules expression, single-quotes are replaced with double-quotes
        [Parameter(ParameterSetName="AtLeastOneName")]
        [Parameter(Mandatory=$true, ParameterSetName="AtLeastOneExpression")]
        [Parameter(ParameterSetName="AtLeastOneExcludeUsers")]
        [string]
        $Expression,

        # Excluded users when processing rules.
        [Parameter(ParameterSetName="AtLeastOneName")]
        [Parameter(ParameterSetName="AtLeastOneExpression")]
        [Parameter(Mandatory=$true, ParameterSetName="AtLeastOneExcludeUsers")]
        [OktaUser[]]
        $ExcludeUsers,

        # Normally, you cannot update a rule that is active. Use -Force to deactivate the rule before updating.
        [Switch]
        [Parameter(ParameterSetName="AtLeastOneName")]
        [Parameter(ParameterSetName="AtLeastOneExpression")]
        [Parameter(ParameterSetName="AtLeastOneExcludeUsers")]
        $Force
    )

    #TODO
    $Rule.

    $body = @{
        "type" = "group_rule"
        "name" = $Rule.name
        "conditions" = @{
            "expression" = @{
                "value" = $Rule.conditions.expression.value
                "type" = "urn:okta:expression:1.0"
            }
            "people" = @{
                "exclude" = $Rule.conditions.people.exclude
            }
        }
        "actions" = @{
            "assignUserToGroups" = @{
                "groupIds" = $Rule.actions.assignUserToGroups.groupIds
            }
        }
    }

    If($Name) {
        $body.name = $Name
    }

    If($Expression) {
        $body.conditions.expression.value = $Expression.Replace("'","`"")
    }

    If($ExcludeUsers) {
        $body.conditions.people.exclude = $ExcludeUsers.id
    }

    If($Rule.status -eq "ACTIVE" -and -not $Force) {
        Write-Warning "The rule is active. Use -Force to deactivate the rule before updating."
        Return
    }

    # Deactivate the rule if it is active and -Force is used
    If($Rule.status -eq "ACTIVE" -and $Force) {
        Disable-OktaGroupRule -Rule $Rule
    }

    $updatedRule = Invoke-OktaRequest -Method "PUT" -Endpoint "api/v1/groups/rules/$($Rule.id)" -Body $Body

    # Re-enable the rule if it was active and -Force was used
    If($Rule.status -eq "ACTIVE" -and $Force) {
        Enable-OktaGroupRule -Rule $updatedRule
    }

    Return $updatedRule
}
