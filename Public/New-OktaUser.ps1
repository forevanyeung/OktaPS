Function New-OktaUser {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $FirstName,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $LastName,

        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $Email,

        # Parameter help description
        [Parameter()]
        [Switch]
        $Activate
    )

    If($Activate) {
        $url_builder = @{}
        $url_builder['activate'] = $true
        $querystring = New-HttpQueryString -QueryParameter $url_builder
    }

    Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/users?$querystring" -Body @{
        "profile" = @{
            "firstName" = $FirstName
            "lastName"  = $LastName
            "email"     = $Email
            "login"     = $Email
        }
    } -Verbose -Debug
}