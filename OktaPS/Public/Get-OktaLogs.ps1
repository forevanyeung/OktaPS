Function Get-OktaLogs {
    <#
    .SYNOPSIS
        Fetches a list of ordered log events from your Okta organization's system log
    .DESCRIPTION
        The Okta System Log records system events that are related to your organization in order to provide an audit 
        trail that can be used to understand platform activity and to diagnose problems.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        https://developer.okta.com/docs/reference/api/system-log
    .EXAMPLE
        Get-OktaLogs -Limit 15
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    .EXAMPLE
        $logs = Get-OktaLogs -NoPrompt
        Use -NoPrompt when assigning the output of Get-OktaLogs to a variable
    .EXAMPLE
        Get-OktaUser anna.unstoppable | Get-OktaLogs
        Get logs for a specific user
    #>

    [CmdletBinding(DefaultParameterSetName="ByFilter")]
    param (
        # Filters the lower time bound of the log events published property for bounded queries or persistence time for polling queries
        [Parameter(ParameterSetName="ByFilter")]
        [Parameter(ParameterSetName="ByUser")]
        [datetime]
        $Since = (Get-Date).AddMinutes(-15),

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
        [Parameter(ParameterSetName="ByFilter", ValueFromPipeline)]
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

        # Not supported, Disable color output for consoles without ANSI support
        # [Parameter()]
        # [switch]
        # $NoColor,

        # Get logs for a specific user, cannot be combined with the Filter parameter
        [Parameter(ParameterSetName="ByUser", ValueFromPipeline)]
        [OktaUser]
        $User
    )

    Switch($PSCmdlet.ParameterSetName) {
        "ByUser" {
            $Filter = "actor.id eq ""$($User.id)"" or target.id eq ""$($User.id)"""
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

    $response = Invoke-OktaRequest -Method "GET" -Endpoint "/api/v1/logs" -Query $query
    Return ConvertTo-OktaLogEvent -LogEvent $response
}
