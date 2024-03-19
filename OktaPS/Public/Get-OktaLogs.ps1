# bounded requests
Function Get-OktaLogs {
    [CmdletBinding(DefaultParameterSetName="ByFilter")]
    param (
        # Filters the lower time bound of the log events published property for bounded queries or persistence time for polling queries
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [datetime]
        $Since = (Get-Date).AddDays(-7),

        # Filters the upper time bound of the log events published property for bounded queries or persistence time for polling queries
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [datetime]
        $Until = (Get-Date),

        # Filter Expression that filters the results
        [Parameter(ParameterSetName="ByFilter")]
        [String]
        $Filter,

        # Filters the log events results by one or more exact keywords
        [Parameter(ParameterSetName="ByFilter")]
        [String]
        $Keyword,

        # The order of the returned events that are sorted by published
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [ValidateSet("ASCENDING", "DESCENDING")]
        [String]
        $Sort = "ASCENDING",

        # Sets the number of results that are returned in the response
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [int]
        $Limit = 1000,

        # Return all pages of results without any prompts
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [switch]
        $NoPrompt,

        # Not supported, Disable color output for consoles without ANSI support
        # [Parameter()]
        # [switch]
        # $NoColor,

        # Get logs for a specific user, cannot be combined with the Filter parameter
        [Parameter(ParameterSetName="ByUser", ValueFromPipeline)]
        [PSTypeName("OktaUser")]
        $OktaUser
    )

    Switch($PSCmdlet.ParameterSetName) {
        "ByUser" {
            $Filter = "actor.id eq ""$($OktaUser.id)"" or target.id eq ""$($OktaUser.id)"""
        }
    }
    
    $query = @{
        since = $Since.ToString("o")
        until = $Until.ToString("o")
        filter = $Filter
        q = $Keyword
        sortOrder = $Sort
        limit = $Limit
    }

    If($NoPrompt) {
        $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/logs" -Query $query
        Return ConvertTo-OktaLogEvent -LogEvent $response
    }

    $next = $true
    $allnext = $false

    While($next -eq $true -or $allnext -eq $true) {
        $next = $false

        $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/logs" -Query $query -PassThru -NoPagination

        # split the output to console and to variable
        ConvertTo-OktaLogEvent -LogEvent $($response.Content | ConvertFrom-JSON) | Tee-Object -variable logEvent | Out-Default
        $logEvent

        # ConvertTo-OktaLogEvent -LogEvent $($response.Content | ConvertFrom-JSON)

        # don't prompt if there are no more pages
        If(-not $response.RelationLink.ContainsKey('next')) {
            $next = $false
            Continue
        }

        # don't prompt if all pages are requested
        If($allnext -eq $true) {
            $uri = [uri]$response.RelationLink["next"]
            $resQuery = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
            $query["after"] = $resQuery["after"]

            Continue
        }

        # ask the user if they want to continue
        $nextPageInput = Read-Host "[Y] Next page [A] All pages [N] No more pages"
        
        switch($nextPageInput) {
            "Y" {
                $uri = [uri]$response.RelationLink["next"]
                $resQuery = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                $query["after"] = $resQuery["after"]

                $next = $true
            }

            "A" {
                $uri = [uri]$response.RelationLink["next"]
                $resQuery = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                $query["after"] = $resQuery["after"]

                $allnext = $true
            }

            "N" {
                $next = $false
            }

            default {
                $next = $false
            }
        }
    }
}
