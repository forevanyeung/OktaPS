<#
.SYNOPSIS
    Creates a group rule.
.DESCRIPTION
    Creates a group rule to dynamically add Users to the specified Group if they match the condition.
.OUTPUTS
    OktaGroupRule
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/createGroupRule
.EXAMPLE
    New-OktaGroupRule -Name "Engineering group rule" -Expression "user.role==`"Engineer`""" -Group "Engineering"
    Creates a group rule that adds users to the Engineering group if their role is Engineer.
.EXAMPLE
    New-OktaGroupRule -Name "Engineering group rule" -Expression "user.role==`"Engineer`""" -Group "Engineering" -Activate
    Creates a group rule that adds users to the Engineering group if their role is Engineer. The rule is activated after creation.
#>
Function New-OktaGroupRule {
    [CmdletBinding()]
    param (
        # Name of the Group rule
        [ValidateLength(1,50)]
        [Parameter(Mandatory)]
        [string]
        $Name,

        # Defines Okta specific group-rules expression, single-quotes are replaced with double-quotes
        [Parameter(Mandatory)]
        [string]
        $Expression,

        # List of group Ids or objects to which users are added if they match the condition
        [Parameter(Mandatory)]
        [OktaGroup[]]
        $Group,

        # Excluded users when processing rules
        [Parameter()]
        [OktaUser[]]
        $ExcludeUsers,

        # Activates the group rule after creation
        [Parameter()]
        [Switch]
        $Activate
    )

    $body = @{
        "type" = "group_rule"
        "name" = $Name
        "conditions" = @{
            "expression" = @{
                "value" = $Expression.Replace("'","`"") #expression has to be in double-quotes
                "type" = "urn:okta:expression:1.0"
            }
        }
        "actions" = @{
            "assignUserToGroups" = @{
                "groupIds" = $Group
            }
        }
    }

    If($ExcludeUsers) {
        $body.conditions.people = @{}
        $body.conditions.people.users = @{}
        $body.conditions.people.users.exclude = $ExcludeUsers
    }

    $rule = Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/groups/rules" -Body $Body

    If($Activate) {
        Enable-OktaGroupRule -Rule $rule

        $activatedRule = Get-OktaGroupRule -Id $activatedRule.id

        Return $activatedRule
    }

    Return $rule
}
