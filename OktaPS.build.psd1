@{
    Module = "OktaPS"
    Output = "release"
    Dependencies = @{
        PowerHTML = "forevanyeung/PowerHTML#fix-formatdata"
        PSJsonWebToken = "forevanyeung/PSJsonWebToken/PSJsonWebToken#feat-privatekey"
    }
    DevDependencies = @{
        Pester = ""
        PsScriptAnalyzer = ""
        platyPS = ""
    }
}