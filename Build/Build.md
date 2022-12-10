# Building OktaPS

OktaPS uses the [InvokeBuild](https://github.com/nightroman/Invoke-Build) module to build this project.   

To build a production release, run `Invoke-Build` in the root directory, the compiled module will __ in `release/`.

For development builds, run `Invoke-Build Install` in the root directory to install dependencies. Then import the module with `Import-Module ./OktaPS`. The install build script does not compile any code, but public and private functions are exported for easier testing.   

## Structure
`Build/` - private functions related to build  
`OktaPS.build.ps1` - build script and tasks   
`OktaPS.build.psd1` - build variables and dependencies

## Dependencies
Powershell modules usually expect dependencies to be installed globally on the machine or user scope. OktaPS instead chooses to ship dependencies within its own module using NestedModules. 

This was done to fix bugs or add features that have not been accepted or released by the module author yet. Dependencies can be URLs to Github repositories in the following format:  
```pwsh
Dependencies = @{
    {module_name} = "{user}/{repository}/{subFolder}#{ref}"
}
```
> Support for traditional RequiredModules will be added when the need arises. I like the idea of NPM's dependency style.