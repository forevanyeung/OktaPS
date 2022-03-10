function New-HttpQueryString {
    # https://powershellmagazine.com/2019/06/14/pstip-a-better-way-to-generate-http-query-strings-in-powershell/

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $QueryParameter
    )

    # Add System.Web
    Add-Type -AssemblyName System.Web
    
    # Create a http name value collection from an empty string
    $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    
    foreach ($key in $QueryParameter.Keys) {
        $nvCollection.Add($key, $QueryParameter.$key)
    }
    
    # Build the uri
    return $nvCollection.ToString()
}