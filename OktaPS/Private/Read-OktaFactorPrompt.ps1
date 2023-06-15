# Accepts an array of factors and prompts the user to select one, the default is the first one. Returns a string of the 
# selected factor.
Function Read-OktaFactorPrompt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String[]]
        $AvailableFactors
    )

    $title = "Verify it's you with a security method"
    $question = "Select from the following options"
    $choices = @(Foreach($f in $AvailableFactors) {
        Switch($f) {
            "duo::web" {
                [System.Management.Automation.Host.ChoiceDescription]::new("&Duo Security", "Get a push notification from Duo")
            }
            "okta::push" {
                [System.Management.Automation.Host.ChoiceDescription]::new("&Okta Verify Push", "Get a push notification from Okta Verify")
            }
            "okta::token:software:totp" {
                [System.Management.Automation.Host.ChoiceDescription]::new("Okta Verify &Code", "Enter a code from Okta Verify")
            }
            Default {
                Write-Error "Unknown factor type: $f"
            }
        }
    })

    $index = $host.ui.PromptForChoice($title, $question, $choices, 0)

    Return $index
}
