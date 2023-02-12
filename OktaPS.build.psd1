@{
    Module = "OktaPS"
    Output = "release"
    Dependencies = @{
        PowerHTML = "forevanyeung/PowerHTML#fix-formatdata"
        PSJsonWebToken = "forevanyeung/PSJsonWebToken/PSJsonWebToken#feat-privatekey"
        "powershell-yaml" = "cloudbase/powershell-yaml"
    }
    DevDependencies = @{
        # Pester = ""
        # PsScriptAnalyzer = ""
        # platyPS = "PowerShell/platyPS"
    }
}