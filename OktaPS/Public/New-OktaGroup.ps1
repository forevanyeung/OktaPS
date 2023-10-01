Function New-OktaGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description = ""
    )

    $reqBody = @{
        "profile" = @{
            "name" = $Name
            "description" = $Description
        }
    }

    $response = Invoke-OktaRequest -Method "POST" -Endpoint "api/v1/groups" -Body $reqBody

    $GroupObject = ConvertTo-OktaGroup -InputObject $response
    Return $GroupObject
}
