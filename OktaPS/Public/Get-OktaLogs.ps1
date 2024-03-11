Function Get-OktaLogs {
    [CmdletBinding()]
    param (
        # Filters the lower time bound of the log events published property for bounded queries or persistence time for polling queries
        [Parameter()]
        [datetime]
        $Since = (Get-Date).AddDays(-7),

        # Filters the upper time bound of the log events published property for bounded queries or persistence time for polling queries
        [Parameter()]
        [datetime]
        $Until = (Get-Date),

        # Filter Expression that filters the results
        [Parameter()]
        [String]
        $Filter,

        # The order of the returned events that are sorted by published
        [Parameter()]
        [ValidateSet("ASCENDING", "DESCENDING")]
        [String]
        $Sort = "ASCENDING",

        # Sets the number of results that are returned in the response
        [Parameter()]
        [int]
        $Limit = 1000,

        # Return all pages of results without any prompts
        [Parameter()]
        [switch]
        $NoPrompt
    )
    
    $query = @{
        since = $Since.ToString("o")
        until = $Until.ToString("o")
        filter = $Filter
        q = ""
        sortOrder = ""
        limit = $Limit
    }

    If($NoPrompt) {
        $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/logs" -Query $query
        Return ConvertTo-OktaLogEvent -LogEvent $response
    }

    $next = $true

    While($next -eq $true) {
        $next = $false

        $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/logs" -Query $query -PassThru -NoPagination

        ConvertTo-OktaLogEvent -LogEvent $($response.Content | ConvertFrom-JSON)

        
        # $nextPageInput = Read-Host "[Y] Next page [A] All pages [N] No more pages"
        
        # switch($nextPageInput) {
        #     "Y" {
        #         $response.Headers["Link"] -match '<(.*?)>; rel="next"' | Out-Null
        #         $next = $true
        #         $query["after"] = $response.Data[-1].published
        #     }

        #     "A" {
        #         $next = $true
        #         $query["after"] = $response.Data[-1].published
        #     }

        #     "N" {
        #         $next = $false
        #     }

        #     default {
        #         $next = $false
        #     }
        # }
    }
}
