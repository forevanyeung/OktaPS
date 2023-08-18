Function Set-OktaUser {
    [CmdletBinding(DefaultParameterSetName="SingleProfileAttribute")]
    param(
        [Parameter(Mandatory=$true)]
        [OktaUser]$User,
        
        # Specify a single profile attribute name to set on the Okta user.
        [Parameter(ParameterSetName="SingleProfileAttribute", Mandatory=$true)]
        [String]
        $ProfileAttributeName,

        # Specify a single profile attribute value to set on the Okta user.
        [Parameter(ParameterSetName="SingleProfileAttribute", Mandatory=$true)]
        [String]
        $ProfileAttributeValue,

        # Specify a hashtable of profile attributes name value pairs to set on the Okta user.
        [Parameter(ParameterSetName="HashtableProfileAttribute", Mandatory=$true)]
        [Hashtable]
        $ProfileAttribute,

        # Indicates if unspecified properties should be deleted from the Okta user's profile.
        [Parameter()]
        [Switch]
        $Force
    )

    $Method = "POST"
    If($Force) {
        $Method = "PUT"
    }

    If($PSCmdlet.ParameterSetName -eq "SingleProfileAttribute") {
        $ProfileAttribute = @{
            $ProfileAttributeName = $ProfileAttributeValue
        }
    }

    $Body = @{
        "profile" = $ProfileAttribute
    }

    Invoke-OktaRequest -Method $Method -Endpoint "api/v1/users/$($User.id)" -Body $Body
}