Function Invoke-IDXForm {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]
        $IDXForm,

        [Parameter()]
        [PSCustomObject]
        $Value,

        $WebSession
    )

    $body = @{}
    $IDXForm.value | ForEach-Object {
        # set any default values
        $fieldValue = $_.value

        # override with values
        If($Value.$($_.name)) {
            $fieldValue = $Value.$($_.name)
        }

        If ($_.required -and $null -eq $fieldValue) {
            throw "Missing required field: $($_.name)"
        }

        If($null -ne $fieldValue) {
            $body[$_.name] = $fieldValue
        }
    }

    $res = Invoke-RestMethod -Method $IDXForm.method -Uri $IDXForm.href -Headers @{
        'Accept'                     = $IDXForm.accepts
        'Content-Type'               = $IDXForm.produces
        # 'User-Agent'                 = Get-OktaUserAgent
        'User-Agent'                 = 'PowerShell/7.5.4 (Macintosh; Intel Mac OS X 10_15_7) OktaPS/0.0.0'
    } -Body ($body | ConvertTo-Json) -SkipHttpErrorCheck -StatusCodeVariable status -WebSession $WebSession

    Return @{
        idx = $res
        status = $status
    }
}
