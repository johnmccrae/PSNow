![Made With Powershell](https://img.shields.io/badge/Made%20With-PowerShell-green "Powered by PowerShell")
[![Build Status](https://dev.azure.com/chefcorp-chefIT/PSNow/_apis/build/status/johnmccrae.PSNow?branchName=master)](https://dev.azure.com/chefcorp-chefIT/PSNow/_build/latest?definitionId=21&branchName=master)

# PSNow

A PowerShell module for making modules. Create, analyze, test, sign, build, deploy and publish your code with one module.

Follow the directions below to get started. The creation process will ask you some basic questions about your new module and will then create everything you need to get going.

3 stages to module development:
1 - Install the module and run it
2 - Write your functions
3 - Use the built in tools to build, anaylize, test, sign and publish your work.


There are 2 basic components for this module - the New-PSNowModule function uses Plaster to create a robust, fully built out, but empty, module structure. You'll then create your functions and use build.ps1 for everything else. Open build.ps1 and read the comments in the header. They'll give you an idea of everything you can do with it. Individual build tasks are defined in build.psake.ps1. You can interrogate that file to add your own tweaks.

## Getting Started

### Install from the PSGallery and Import the module

    Install-Module PSNow
    Import-Module PSNow

### Create your module - New-PSNowModule
```powershell
New-PSNowModule -NewModuleName <your module name goes here> -BaseManifest Advanced
```
For your first module, execute that statement verbatim, adding in your module name. You'll be asked some questions about your github username, some details about the module and some things about support details for your module. Accept the defaults and hit enter. When the tool is done, navigate to ~/modules/<your module> and explore.

### Your First Script

A basic function-based script is ready for you in ~/modules/<your module>/public. Feel free to interogate it and modify it as necessary. Don't forget to update the comments in the Header - you'll need them later when you make your help files.

Now setup your environment.

```powershell
./Build/Build.ps1 -tasklist init
Get-Item env:BH*
```

### Write Out Test Cases for Your Code

This module supports the Gherkin DSL as well as Pester for Test Driven Development. When following that pattern, you write your tests first to clarify your thinking around what you expect your module and scripts to do. Then go back and write your first script. Navigate to /Tests/Features and write the test for your first script there. Then run this to test your code.

```powershell
./Build/Build.ps1 -tasklist
```

### Stage your Code for Testing and Eventual Deployment

Now that you have some basic code and the tests for it all done. Let's stage your code and get it ready to publish or deploy.

This step creates verifies that there is a folder called /Staging/<your module>

```powershell
./Build/build.ps1 -tasklist stage
```



### Analyze your code for defects

You should check your code for defects and linting issues by running PS Script Analyzer

```powershell
./Build/build.ps1 -tasklist analyze,test
```



### Sign your code with a self-signed certificate

@lbertolotti You're getting UnkownError because your self-signed certificate isn't trusted in the Root certificate store. While New-SelfSignedCertificate won't let you store in the Root store, you can do it with Export/Import-Certificate. Here's some repro code:



### Build your scripts into nuspec modules

The tool fully supports current package management tools like nuget. You get a pre-built nuspec file with your new module so all you have to is execute these commands to update your build number and then create the package.

```powershell
./Build/build.ps1 -tasklist UpdateBuildVersion, BuildNuget -parameters ` @{BuildRev='Revision'}
```



#### Using nuget on OSX/Linux

You'll need to add a couple of tools to get Nuget to work on OSX/Linux

https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools





### Deploy your module to your nodes using Azure CI CD Pipelines





### Publish your module to PSGallery







## More Information

For more information

* [github.com/johnmccrae/PSNow](https://github.com/johnmccrae/PSNow)

## Tested On
https://atlassianps.org/module/JiraPS/

### Credits

This project was generated using [Kevin Marquette](http://kevinmarquette.github.io)'s [Full Module Plaster Template](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate).

Special Shout Out to Adam Rush for his tutorial on using [PSake.](https://adamrushuk.github.io/example-azure-devops-build-pipeline-for-powershell-modules/)

Inspiration from Adam Bertram aka [Adam the Automator](https://adamtheautomator.com/)

## License

This project is [licensed under the MIT License](LICENSE.md).



