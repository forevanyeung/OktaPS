Function Save-Github {
    param (
        [Parameter()]
        [String]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter()]
        [String]
        $Destination = $(Get-Location)
    )

    $githubUser, $githubRepoRef = $Repository.Split("/", 2)
    $githubRepoData, $githubRef = $githubRepoRef.Split("#", 2)
    $githubRepo, $githubSubFolder = $githubRepoData.Split("/", 2)

    $githubUrl = "https://api.github.com/repos/${githubUser}/${githubRepo}/zipball/${githubRef}"
    Write-Host "     Downloading dependency: $githubUrl"
    $depDownload = Save-File -Uri $githubUrl
    Write-Host "          Extracting archive"
    Expand-Archive -Path $depDownload -DestinationPath $Destination
    Remove-Item -Path $depDownload -Force

    $depArchive = (Join-Path $Destination (Split-Path -Path $depDownload -LeafBase))
    $module = $Name
    Rename-Item -Path $depArchive -NewName $module
}
