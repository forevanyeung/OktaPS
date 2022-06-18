function New-HttpQueryString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $QueryParameter
    )

    $join = @(
        foreach($k in $QueryParameter.Keys) {
            # https://stackoverflow.com/questions/46336763/c-sharp-net-how-to-encode-url-space-with-20-instead-of
            $fv_pair = "{0}={1}" -f $k, [System.Uri]::EscapeDataString($QueryParameter[$k])
            $fv_pair
        }
    )
    
    $querystring = $join -join '&'

    return $querystring
}