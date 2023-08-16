# Building OktaPS

OktaPS uses the [InvokeBuild](https://github.com/nightroman/Invoke-Build) module to build this project.   

To build a production release, run `Invoke-Build` in the root directory, the compiled module will compile in the `release/` directory.

For development builds, run `Invoke-Build Install` in the root directory to install dependencies. Then import the module with `Import-Module ./OktaPS`. The install build script does not compile any code, but public and private functions are exported for easier testing. You will also need to dot source any `*.class.ps1` files, see the [Classes](#classes) section for more details. 

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

## Classes
During development you need to manually dot source each of the classes once at the begining. Otherwise, you may get errors like `Unable to find type [OktaUser]`. For some reason dot sourcing it in the `.psd1` file does not make it available in the module. 

```pwsh
. '/OktaPS/OktaPS/Types/OktaUser.class.ps1'
```

After you dot sources the class once, you do not need to dot source it again for the remainder of the Powershell session, even if you re-import the module. 

Unless you are making changes to classes, in that case, you will need to restart your Powershell session and import the module each time. Powershell only load a class once during a session.

Here is a great write-up of using classes in Powershell, https://stephanevg.github.io/powershell/class/module/DATA-How-To-Write-powershell-Modules-with-classes/