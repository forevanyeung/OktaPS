Function Get-OktaGroupRule {
    [CmdletBinding(DefaultParameterSetName="BySearch")]
    param (
        # Id of a group rule
        [Parameter(ParameterSetName="ById", Mandatory)]
        [String]
        $Id,

        # Specifies the keyword to search rules for, leave empty to list all rules
        [Parameter(ParameterSetName="BySearch")]
        [String]
        $Search,

        # Expand group ids to names 
        [Parameter(ParameterSetName="BySearch")]
        [Parameter(ParameterSetName="ById")]
        [Switch]
        $Expand, 

        # Specifies the number of rule results in a page
        [Parameter(ParameterSetName="BySearch")]
        [int]
        $Limit = 200
    )

    switch($PSCmdlet.ParameterSetName) {
        "ById" {
            If($Expand -eq $true) {
                $query = @{}
                $query["expand"] = "groupIdToGroupNameMap"
            }

            $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules/$Id" -ErrorAction SilentlyContinue
        }

        "BySearch" {
            $query = @{}
            $query["search"] = $Rule
            $query["limit"] = $Limit
            If($Expand) {
                $query["expand"] = "groupIdToGroupNameMap"
            }

            $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/rules" -Query $query -ErrorAction SilentlyContinue
        }
    }

    Return $response
}
