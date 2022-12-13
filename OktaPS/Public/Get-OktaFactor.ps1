Function Get-OktaFactor {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="ByIdentity", Position=0, Mandatory)]
        [String[]]
        $Identity,

        [Parameter(ParameterSetName="ByOktaUser", ValueFromPipeline, Mandatory)]
        [PSTypeName("Okta.User")]
        [PSCustomObject[]]
        $OktaUser
    )

    Begin {
        $i = 0
    }

    Process {
        If($PSCmdlet.ParameterSetName -eq "ByIdentity") {
            
            Foreach($IdentityOne in $Identity) {
                Write-Progress -Activity "Getting enrolled factors" -PercentComplete ($i/($Identity.Count)*100)
                $OktaUser = Get-OktaUser -Identity $IdentityOne -ErrorAction Stop
                Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/users/$($OktaUser.Id)/factors"
                $i++
            }
            
        } else {

            Foreach($u in $OktaUser) {
                # count is not available when pipelining so we cannot show a progress bar, alternative to
                # show a count of processed objects
                $ObjectPct = $OktaUser.Count -gt 1 ? $i/($OktaUser.Count)*100 : -1

                Write-Progress -Activity "Getting enrolled factors" -Status $i -PercentComplete $ObjectPct
                Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/users/$($u.Id)/factors"
                $i++
            }
            
        }
    } 

    End {

    }
}
