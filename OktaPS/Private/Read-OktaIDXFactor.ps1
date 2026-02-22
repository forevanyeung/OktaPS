Function Read-OktaIDXFactor {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSCustomObject]
        $Options
    )

    $choices = [System.Collections.Generic.List[System.Management.Automation.Host.ChoiceDescription]]@()
    $authenticators = [System.Collections.ArrayList]@()
    foreach($o in $Options) {
        $id = $o.value.form.value | Where-Object { $_.name -eq 'id' } | Select-Object -ExpandProperty value
        $value = $o.value.form.value | Where-Object { $_.name -eq 'methodType' }
        foreach($v in $value.options) {
            $label = switch($v.value) {
                "totp" { "&Code" }
                "push" { "&Push" }
                "signed_nonce" { "&FastPass" }
                Default { "$($v.label)" }
            }

            $null = $choices.Add(
                [System.Management.Automation.Host.ChoiceDescription]::new("$($o.label) - $label", $v.label)
            )
            $null = $authenticators.Add(
                @{
                    id = $id
                    methodType = $v.value
                }
            )
        }
    }

    $title = "Verify it's you with a security method"
    $question = "Select from the following options"
    $index = $host.ui.PromptForChoice($title, $question, $choices, 0)

    Return $authenticators[$index]
}