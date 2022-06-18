Function Get-OktaUser {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'GetUser', Mandatory, Position=0, HelpMessage="Okta user ID, login, or short-login")]
        [String]
        $Identity,

        [Parameter(ParameterSetName = 'ListUserFilter', Mandatory, HelpMessage="Okta API filter criteria. https://developer.okta.com/docs/reference/api/users/#list-users-with-a-filter")]
        [String]
        $Filter,

        [Parameter(ParameterSetName = 'ListUserSearch', Mandatory, HelpMessage="Okta API search criteria. https://developer.okta.com/docs/reference/api/users/#list-users-with-search")]
        [String]
        $Search,

        [Parameter(ParameterSetName = 'GetUser')]
        [Parameter(ParameterSetName = 'ListUserFilter')]
        [Parameter(ParameterSetName = 'ListUserSearch')]
        [String]
        $Properties,

        [Parameter(ParameterSetName = 'GetUser')]
        [Parameter(ParameterSetName = 'ListUserFilter')]
        [Parameter(ParameterSetName = 'ListUserSearch')]
        [Int]
        $Limit = 10
    )

    $request_args = @{}
    
    # by default Okta sends over all properties, so selecting only a subset of properties does not 
    # have any performance gains of network bandwidth. can implement it in the future for memory 
    # saving
    If($Properties -eq "*") {
        $groups_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users/$Identity/groups"
    } else {
        # less expensive request?
        # https://developer.okta.com/docs/reference/api/users/#content-type-header-fields
        $request_args['Headers'] = @{ "Content-Type" = "application/json; okta-response=omitCredentials,omitCredentialsLinks,omitTransitioningToStatus" }
    }

    switch ($PsCmdlet.ParameterSetName) {
        "GetUser" { 
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users/$Identity" @request_args -ErrorAction Stop

            $groups_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users/$Identity/groups" -ErrorAction SilentlyContinue
            If($groups_query) {
                $user_query | Add-Member -MemberType NoteProperty -Name "_groups" -Value $groups_query
            }
        }

        "ListUserFilter" {
            $url_builder = @{}
            $url_builder['limit'] = $Limit
            $url_builder['filter'] = $Filter
            $querystring = New-HttpQueryString -QueryParameter $url_builder
    
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
        }

        "ListUserSearch" {
            $url_builder = @{}
            $url_builder['limit'] = $Limit
            $url_builder['search'] = $Search
            $querystring = New-HttpQueryString -QueryParameter $url_builder
    
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
        }
    }
    
    $OktaUser = ConvertTo-OktaUser -InputObject $user_query
    Return $OktaUser

    # Return $user_query
}