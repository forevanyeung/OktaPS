Function Add-OktaAppMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
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
            $OktaUser = Get-OktaUser -Identity $user     

            Invoke-OktaRequest -Method "POST" -Endpoint "/api/v1/apps/$($OktaApp.Id)/users" -Body @{
                id = $OktaUser.Id
                scope = "USER"
            }
        }
    }
}
