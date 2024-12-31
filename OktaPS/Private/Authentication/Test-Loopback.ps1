Function Test-Loopback {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $Hostname,

        [Parameter(Mandatory=$true)]
        [Int[]]
        $Port
    )

    $loopbackSuccess = $false

    foreach($p in $Port) {
        $loopbackAddress = "${Hostname}:${p}"
        $loopbackUrl = "$loopbackAddress/probe"

        Try {
            $response = Invoke-WebRequest -Uri $loopbackUrl -Method GET

            If($response.StatusCode -eq 200) {
                $loopbackSuccess = $true
                Break
            }
        } Catch {
            If($_.ErrorDetails.Message -like "*The response ended prematurely.*") {
                $loopbackSuccess = $true
                Break
            }
        }

        $loopbackAddress = ""
    }

    Return [PSCustomObject]@{
        "success" = $loopbackSuccess
        "address" = $loopbackAddress
    }
}
