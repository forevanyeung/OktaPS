@{
    Module = "OktaPS"
    Output = "release"
    Dependencies = @{
        "PowerHTML" = "github:forevanyeung/PowerHTML#fix-formatdata"
        "powershell-yaml" = "0.4.7"
    }
    DevDependencies = @{
        # Pester = ""
        # PsScriptAnalyzer = ""
        # platyPS = "PowerShell/platyPS"
    }
}
