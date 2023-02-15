Function Add-OktaAppMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [OktaUser[]]
        $Identity,

        [Parameter()]
        [String]
        $App
    )
    
    begin {
        $OktaApp = Get-OktaApp -App $App -ErrorAction Stop
    }

    process {
        foreach($user in $Identity) {
            Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/apps/$($OktaApp.Id)/users" -Body @{
                id = $user.Id
                scope = "USER"
            }
        }
    }
}
