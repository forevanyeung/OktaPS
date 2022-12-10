Function Get-OktaGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Identity,

        [Parameter()]
        [ValidateSet("OKTA_GROUP","APP_GROUP")]
        [String]
        $Type
    )

    # try matching group id
    $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups/$Identity" -ErrorAction SilentlyContinue
    If(-not $group) {
        # try matching group name
        $group = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/groups?q=$Identity" -ErrorAction SilentlyContinue
    }

    If(-not $group) {
        Throw "Group not found: $Identity"
    }

    $GroupObject = Foreach($g in $group) {
        ConvertTo-OktaGroup -InputObject $g
    }
    Return $GroupObject

    # Return $group
}