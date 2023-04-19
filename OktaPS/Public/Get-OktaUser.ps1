Function Get-OktaUser {
    [CmdletBinding(DefaultParameterSetName='AllUsers')]
    [OutputType([OktaUser])]
    param (
        [Parameter(ParameterSetName = 'GetUser', Mandatory, Position=0, HelpMessage="Okta user ID, login, or short-login")]
        [String[]]
        $Identity,

        [Parameter(ParameterSetName = 'ListUserFilter', Mandatory, HelpMessage="Okta API filter criteria. https://developer.okta.com/docs/reference/api/users/#list-users-with-a-filter")]
        [String]
        $Filter,

        [Parameter(ParameterSetName = 'ListUserSearch', Mandatory, HelpMessage="Okta API search criteria. https://developer.okta.com/docs/reference/api/users/#list-users-with-search")]
        [String]
        $Search,

        [Parameter(ParameterSetName = 'ListUserFind', Mandatory, HelpMessage="Okta API search criteria. https://developer.okta.com/docs/reference/api/users/#find-users")]
        [String]
        $Find,

        [Parameter(ParameterSetName = 'GetUser')]
        [Parameter(ParameterSetName = 'ListUserFilter')]
        [Parameter(ParameterSetName = 'ListUserSearch')]
        [String]
        $Properties,

        [Parameter(ParameterSetName = 'GetUser')]
        [Parameter(ParameterSetName = 'ListUserFilter')]
        [Parameter(ParameterSetName = 'ListUserSearch')]
        [Int]
        $Limit = 10,

        # By default all users return a list of all users that do not have a status of DEPROVISIONED, this switch also returns DEPROVISIONED users
        [Parameter(ParameterSetName = 'AllUsers')]
        [Switch]
        $IncludeDeprovisioned
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
            $user_query = Foreach($i in $Identity) {
                $query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users/$i" @request_args -ErrorAction Stop

                $groups_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users/$i/groups" -ErrorAction SilentlyContinue
                If($groups_query) {
                    $query | Add-Member -MemberType NoteProperty -Name "_groups" -Value $groups_query
                }

                $query
            }
        }

        "ListUserSearch" {
            $url_builder = @{}
            $url_builder['limit'] = $Limit
            $url_builder['search'] = $Search.Replace("'","`"") #okta query has to be in double-quotes
            $querystring = New-HttpQueryString -QueryParameter $url_builder
    
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
        }

        "ListUserFilter" {
            $url_builder = @{}
            $url_builder['limit'] = $Limit
            $url_builder['filter'] = $Filter
            $querystring = New-HttpQueryString -QueryParameter $url_builder
    
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
        }

        "ListUserFind" {
            $url_builder = @{}
            $url_builder['limit'] = $Limit
            $url_builder['q'] = $Find
            $querystring = New-HttpQueryString -QueryParameter $url_builder
    
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
        }

        "AllUsers" {
            $url_builder = @{}
            $url_builder['limit'] = 200
            $querystring = New-HttpQueryString -QueryParameter $url_builder
            
            $user_query = Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop

            If($IncludeDeprovisioned) {
                $url_builder['filter'] = 'status eq "DEPROVISIONED"'
                $querystring = New-HttpQueryString -QueryParameter $url_builder

                $user_query += Invoke-OktaRequest -Method "GET" -Endpoint "api/v1/users?$querystring" @request_args -ErrorAction Stop
            }
        }
    }
    
    # Return $user_query
 
    $OktaUser = ConvertTo-OktaUser -InputObject $user_query
    Return $OktaUser
}
