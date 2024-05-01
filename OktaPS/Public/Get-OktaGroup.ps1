Function Get-OktaGroup {
    [CmdletBinding(DefaultParameterSetName='AllGroups')]
    param (
        # Specifies an ID or name of an Okta group to retrieve. If searching by ID, it must be an exact match and only 
        # one result will be returned. If searching by name, it will conduct a starts with query, and if multiple matches
        # all groups will be returned.
        [Parameter(ParameterSetName="GetGroup", Mandatory=$true, Position=0)]
        [String]
        $Name,

        # Specifies a specific type of group to search for. If no Type is specified, the default is to search for all 
        # types. Does not apply when searching by ID.
        [Parameter()]
        [ValidateSet("OKTA_GROUP","APP_GROUP")]
        [String]
        $Type
    )

    $query = @{}
    If($Type) {
        $query["filter"] = "type eq `"$Type`""
    } 
    
    switch ($PsCmdlet.ParameterSetName) {
        "AllGroups" {
            $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups" -Query $query -ErrorAction SilentlyContinue
        }
        
        "GetGroup" {
            # try matching group id
            $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/$Name" -ErrorAction SilentlyContinue
            If(-not $group) {
                # try matching group name
                $query["q"] = $Name
                $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups" -Query $query -ErrorAction SilentlyContinue
            }
        }
    }

    If(-not $group) {
        Throw "Group not found: $Name"
    }

    $GroupObject = Foreach($g in $group) {
        ConvertTo-OktaGroup -InputObject $g
    }

    Return $GroupObject
}
