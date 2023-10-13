@{
    Module = "OktaPS"
    Output = "release"
    Dependencies = @{
        PowerHTML = "forevanyeung/PowerHTML#fix-formatdata"
        "powershell-yaml" = "cloudbase/powershell-yaml"
    }
    DevDependencies = @{
        # Pester = ""
        # PsScriptAnalyzer = ""
        # platyPS = "PowerShell/platyPS"
    }
}