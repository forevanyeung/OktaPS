Function Get-OktaFactor {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="ByIdentity", Position=0, ValueFromPipeline, Mandatory)]
        [OktaUser[]]
        $Identity
    )

    Begin {
        $i = 0
    }

    Process {
        Foreach($u in $Identity) {
            Write-Verbose "Looking up factor for $($u.login)"

            # count is not available when pipelining so we cannot show a progress bar, alternative to
            # show a count of processed objects
            $ObjectPct = $Identity.Count -gt 1 ? $i/($Identity.Count)*100 : -1

            Write-Progress -Activity "Getting enrolled factors" -Status $i -PercentComplete $ObjectPct
            Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/users/$($u.Id)/factors"
            $i++
        }
    } 

    End {

    }
}
