Function Read-OktaIDXForm {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Form,

        [Parameter()]
        [PSCredential]$Credential
    )

    $res = @{}
    foreach ($field in $Form) {
        if($field.visible -eq $false) {
            continue
        }

        if($field.form) {
            $value = Read-OktaIDXForm -Form $field.form.value -Credential $Credential
        } else {
            Write-Verbose "Processing field '$($field.name)' of type '$($field.type)'"

            if($field.type -eq "boolean") {
                continue 
            }

            Function Read-OktaIDXFieldDefault {
                param($field)

                If($field.secret) {
                    $value = Read-Host -Prompt $field.label -AsSecureString
                } else {
                    $value = Read-Host -Prompt $field.label
                }

                Return $value
            }

            $value = switch($field.name) {
                "identifier" { 
                    If($Credential) {
                        $Credential.GetNetworkCredential().username 
                    } else {
                        write-verbose "no credential provided, prompting for username"
                        Read-OktaIDXFieldDefault -field $field
                    }
                }

                "passcode" { 
                    If($Credential) {
                        $Credential.GetNetworkCredential().password
                    } else {
                        write-verbose "no credential provided, prompting for password"
                        Wait-Debugger
                        Read-OktaIDXFieldDefault -field $field
                    }
                }
                
                default { Read-OktaIDXFieldDefault -field $field }
            }
        }

        $res.$($field.name) = $value
    }

    Return $res
}
