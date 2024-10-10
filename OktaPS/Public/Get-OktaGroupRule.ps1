<#
.SYNOPSIS
    Retrieves a group rule.
.DESCRIPTION
    Lists all group rules for your organization, or group rules that match by keyword or id.
.OUTPUTS
    OktaGroupRule
.LINK
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/listGroupRules
.LINK 
    https://developer.okta.com/docs/api/openapi/okta-management/management/tag/GroupRule/#tag/GroupRule/operation/getGroupRule
.EXAMPLE
    Get-OktaGroupRule
    Lists all group rules.
.EXAMPLE
    Get-OktaGroupRule -Id "0pr3f7zMZZHPgUoWO0g4"
    Retrieves a specific group rule by id.
.EXAMPLE
    Get-OktaGroupRule -Search "Engineering"
    Lists group rules that match the search keyword.
#>
Function Get-OktaGroupRule {
    [CmdletBinding(DefaultParameterSetName='AllGroupRules')]
    param (
        # Specifies the number of rule results in a page
        [Parameter(ParameterSetName="AllGroupRules")]
        [Int]
        $Limit = 200,

        # Specifies the keyword to search rules for
        [Parameter(ParameterSetName="AllGroupRules")]
        [String]
        $Search,

        # The id of the group rule
        [Parameter(ParameterSetName="GetGroupRuleById", Mandatory=$true, Position=0)]
        [String]
        $Id, 

        # If specified then displays group names
        [Parameter(ParameterSetName="AllGroupRules")]
        [Parameter(ParameterSetName="GetGroupRuleById")]
        [Switch]
        $ExpandIdGroupNames
    )

    $query = @{}
    $query["limit"] = $Limit

    If($ExpandIdGroupNames) {
        $query["expand"] = "groupIdToGroupNameMap"
    }


    switch($PSCmdlet.ParameterSetName) {
        "AllGroupRules" {
            If($Search) {
                $query["search"] = $Search
            }

            $groupRules = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules" -Query $query
            If(-not $groupRules) {
                Throw "Group rule not found: $Search"
            }
        }

        "GetGroupRuleById" {
            $groupRules = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules/$Id" -Query $query
            If(-not $groupRules) {
                Throw "Group rule not found: $Id"
            }
        }
    }

    $groupRulesObject = Foreach($gr in $groupRules) {
        ConvertTo-OktaGroupRule -GroupRule $gr
    }

    return $groupRulesObject
}
