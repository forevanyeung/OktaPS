Function New-OktaGroupRule {
    [CmdletBinding()]
    param (
        # Name of the Group rule
        [ValidateLength(1,50)]
        [Parameter(Mandatory)]
        [string]
        $Name,

        # Defines Okta specific group-rules expression
        [Parameter(Mandatory)]
        [string]
        $Expression,

        # Array of groupIds to which Users are added
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
        $body.conditions.people.exclude = $ExcludeUsers
    }

    $rule = Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/groups/rules" -Body $Body

    If($Activate) {
        Enable-OktaGroupRule -Rule $rule

        $activatedRule = Get-OktaGroupRule -Id $activatedRule.id

        Return $activatedRule
    }

    Return $rule
}
