Function New-OktaGroupRule {
    [CmdletBinding()]
    param (
        [ValidateLength(1,50)]
        [Parameter(Mandatory)]
        [string]
        $Name,

        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $Expression,

        # Parameter help description
        [Parameter(Mandatory)]
        [String[]]
        $Group,

        # Parameter help description
        [Parameter()]
        [Switch]
        $Activate
    )

    $newRule = Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/groups/rules" -Body @{
        "type" = "group_rule"
        "name" = $Name
        "conditions" = @{
            # "people": {
            #     "users": {
            #         "exclude": [
            #         "00u22w79JPMEeeuLr0g4"
            #         ]
            #     },
            #     "groups": {
            #         "exclude": []
            #     }
            # },
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

    If($Activate) {
        $ruleId = $newRule.Id
        $activatedRule = Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/groups/rules/${ruleId}/lifecycle/activate"

        Return $activatedRule
    } else {
        Return $newRule
    }
}
