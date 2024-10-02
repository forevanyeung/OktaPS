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
