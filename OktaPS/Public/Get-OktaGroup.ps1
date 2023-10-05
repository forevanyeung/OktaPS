Function Get-OktaGroup {
    [CmdletBinding(DefaultParameterSetName='AllGroups')]
    param (
        # Specifies an ID or name of an Okta group to retrieve. If searching by ID, it must be an exact match and only 
        # one result will be returned. If searching by name, it will conduct a starts with query, and if multiple matches
        # all groups will be returned.
        [Parameter(ParameterSetName = 'GetGroup', Mandatory, Position=0)]
        [String]
        $Name,

        # Specifies a specific type of group to search for. If no Type is specified, the default is to search for all 
        # types. Does not apply when searching by ID.
        [Parameter(ParameterSetName = 'AllGroups')]
        [Parameter(ParameterSetName = 'GetGroup')]
        [ValidateSet("OKTA_GROUP","APP_GROUP", "BUILT_IN")]
        [String]
        $Type,

        [Parameter(ParameterSetName = 'AllGroups')]
        [Parameter(ParameterSetName = 'GetGroup')]
        [String]
        $Properties,

        # Parameter help description
        [Parameter(ParameterSetName = 'GetGroup')]
        [Int]
        $Limit = 10
    )

    switch ($PSCmdlet.ParameterSetName) {
        "GetGroup" {
            # try matching group id
            $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/$Name" -ErrorAction SilentlyContinue
            If(-not $group) {
                $query = @{}
                $query["q"] = $Name

                If($Type) {
                    $query["filter"] = "type eq `"$Type`""
                } 

                # try matching group name
                $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups" -Query $query -ErrorAction SilentlyContinue
            }

            If(-not $group) {
                Throw "Group not found: $Name"
            }
        }

        "AllGroups" {
            $query = @{}
            $query['limit'] = 200

            If($Type) {
                $query["filter"] = "type eq `"$Type`""
            } 

            $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups" -Query $query -ErrorAction Stop
        }
    }

    $GroupObject = Foreach($g in $group) {
        ConvertTo-OktaGroup -InputObject $g
    }

    Return $GroupObject
}
