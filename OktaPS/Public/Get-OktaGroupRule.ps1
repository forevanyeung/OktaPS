Function Get-OktaGroupRule {
    [CmdletBinding()]
    param (
        # Id of the rule to retrieve, or keyword to search rules for
        [Parameter(Mandatory)]
        [String]
        $Rule
    )

    If($Rule -like "0pr*") {
        $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules/$Rule" -ErrorAction SilentlyContinue
    }

    # If the rule is not found, or the rule is a keyword, search for the rule
    If($response.errorCode -or $Rule -notlike "0pr*") {
        $query = @{}
        $query["search"] = $Rule
        $query["limit"] = 200
        $query["expand"] = "groupIdToGroupNameMap"

        $rule = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules" -Query $query -ErrorAction SilentlyContinue
    }

    Return $rule
}
