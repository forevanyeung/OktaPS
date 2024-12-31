# $datetime = [datetime]::Now
# $datetime = "2021-01-01"
# $datetime = "2h"

# seconds   s
# minutes   m
# hours     h
# days      D
# months    M
# years     Y

Function Get-Duration {
    [CmdletBinding()]
    param (
        [Parameter()]
        $datetime
    )

    # If time is already a DateTime object, return early
    If($datetime.GetType().Name -eq "DateTime") {
        Return $datetime
    }

    # If time is an integer, assume it is a Unix timestamp
    If($datetime.GetType().Name -eq "Int32" -or $datetime.GetType().Name -eq "Int64") {
        Return [datetime]::new($datetime)
    }

    # If time is a string, try to parse it using the datetime class
    try {
        $parsedDateTime = [datetime]::Parse($datetime)
        Return $parsedDateTime
    } catch { }

    # If the string is not parsable, finally, try to parse it as a duration
    $offset = $datetime[0]
    $amount = $datetime.Substring(1)

    # Error early if offset is invalid
    If($offset -ne "+" -and $offset -ne "-") {
        Write-Host "Failed to parse duration, invalid offset"
        Return
    }

    # Error early if there are invalid units
    $invalidUnits = '[^smhDMY\d\s]'
    If($amount -match $invalidUnits) {
        Write-Host "Failed to parse duration, invalid units"
        Return
    }

    # Regex to extract the amount of each unit
    $units = @{
        "seconds" = [regex]'(\d*)s'
        "minutes" = [regex]'(\d*)m'
        "hours"   = [regex]'(\d*)h'
        "days"    = [regex]'(\d*)D'
        "months"  = [regex]'(\d*)M'
        "years"   = [regex]'(\d*)Y'
    }

    # Initialize values for each unit
    $values = @{
        "seconds" = 0
        "minutes" = 0
        "hours"   = 0
        "days"    = 0
        "months"  = 0
        "years"   = 0
    }

    # Loop each unit and extract the value from the amount
    foreach($unit in $units.keys) {
        $pattern = $units[$unit]

        If($m = $pattern.Matches($amount)) {

            # Error early if there are multiple matches
            If($m.Count -gt 1) {
                Write-Error "Invalid value"
                Return
            }

            $values[$unit] = $m.groups.value[1]
        }
    }

    # Parse the duration
    $parsedDuration = [datetime]::Now
    $parsedDuration = $parsedDuration.AddSeconds($offset + $values["seconds"])
    $parsedDuration = $parsedDuration.AddMinutes($offset + $values["minutes"])
    $parsedDuration = $parsedDuration.AddHours($offset + $values["hours"])
    $parsedDuration = $parsedDuration.AddDays($offset + $values["days"])
    $parsedDuration = $parsedDuration.AddMonths($offset + $values["months"])
    $parsedDuration = $parsedDuration.AddYears($offset + $values["years"])

    Return $parsedDuration
}   
