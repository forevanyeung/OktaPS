@{
    Module = "OktaPS"
    Output = "release"
    Dependencies = @{
        "PowerHTML" = "github:forevanyeung/PowerHTML#fix-formatdata"
        "powershell-yaml" = "0.4.11"
    }
    DevDependencies = @{
        # "Invoke-Build" = "5.12.1"
        # "platyPS" = "https://github.com/PowerShell/platyPS/archive/refs/tags/v2.0.0-preview1.zip"
        # Pester = ""
        # PsScriptAnalyzer = ""
    }
}
