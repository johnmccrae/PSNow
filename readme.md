# PSNow

![Made With Powershell](https://img.shields.io/badge/Made%20With-PowerShell-green "Powered by PowerShell")
[![Build Status](https://dev.azure.com/chefcorp-chefIT/PSNow/_apis/build/status/johnmccrae.PSNow?branchName=master)](https://dev.azure.com/chefcorp-chefIT/PSNow/_build/latest?definitionId=21&branchName=master)

A PowerShell module for making modules. PSNow creates the entire framework you need to create, analyze, test, sign, build, deploy and publish your code with one module. All you need to do after you run the module is to write your functions.

Follow the directions below to get started. The process will ask you some basic questions about your new module and will then create everything you need to get going with.

Using this tool, there are 3 stages to module development:
1 - Install PSNow and run New-PSNowModule
2 - Write your functions
3 - Use the built in tools to build, anaylize, test, sign and publish your work.

There are 2 basic components for this module - the New-PSNowModule function uses Plaster to create a robust, fully built out, but empty, module structure. You'll then create your functions and use build.ps1 for everything else. Open build.ps1 and read the comments in the header. The comments will give you an idea of everything you can do with it. Individual build tasks are defined in build.psake.ps1. You can interrogate that file to add your own tweaks.

## Getting Started

### Install from the PSGallery and Import the module

```powershell
    Install-Module PSNow
    Import-Module PSNow
```

### You will need to create the following environmental variables before you start:

This tool makes extensive use of PSake for build automation. That module sets a number of environment variables. We are adding more here to make your workflow smoother. Please set these into your PowerShell Profile. Of course you should change these to match your build and deployment environment.

```powershell
set-item -Path Env:BHChefITAzureBuildUser  -Value "<name of Azure build user>"
set-item -Path Env:BHChefITAzureBuildPassword  -Value "<password for that user>"
set-item -Path Env:BHAzureRepoUrl -Value "https://pkgs.dev.azure.com/<your org>/_packaging/<your repo>/nuget/v2/"
set-item -Path Env:BHAzurePublishRepo -Value '<your repository name>'
set-item -path Env:BHPSGalleryKey -Value '<your PS Gallery publishing key>'
set-item -path Env:BHGitHubUser -Value '<your Github username>'
```

### Create your module - New-PSNowModule

```powershell
New-PSNowModule -NewModuleName <String> -BaseManifest Advanced
```

For your first module, execute that statement, adding in only your module name. You'll be asked some questions about your github username, some details about the module and some things about support details for your module. Accept the defaults and hit enter. When the tool is done, navigate to ~/modules/<your module> and explore.

### Your First Script

A basic function-based script template is ready for you in ~/modules/<your module>/public/<your module>.ps1. Once you are done writing your code, don't forget to update the comments in the Header - you'll need them later when you make your help files.

Now setup your environment.

```powershell
./Build/Build.ps1 -tasklist init
Get-Item env:BH*
```

### Check for And Install Depdencies

PSNow has dependencies on several outside modules. You can view them in /Build/build.depend.psd1. To install them execute the following command:

```powershell
./Build/Build.ps1 -ResolveDependency
```

### Write Out Test Cases for Your Code

This module supports the Gherkin DSL as well as Pester for Test Driven Development. When following that pattern, you write your tests first to clarify your thinking around what you expect your module and scripts to do. Then go back and write your first script. Navigate to /Tests/Features and write the test for your first script there. Then run this to test your code.

```powershell
./Build/Build.ps1 -tasklist test
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

You can sign your code on a Windows device right now but not Linux or OSX. The PKI module support isn't there yet for PS Core on non-windows platforms. If you get an Unknown error it might be because your self-signed certificate isn't trusted in the Root Certificate store. While New-SelfSignedCertificate won't let you store in the Root store, you can do it with Export/Import-Certificate

```powershell
./Build/Build.ps1 -tasklist sign
```

### Build your scripts into nuspec modules

The tool fully supports current package management tools like nuget. You get a pre-built nuspec file with your new module so all you have to is execute these commands to update your build number and then create the package.

```powershell
./Build/build.ps1 -tasklist UpdateBuildVersion, BuildNuget -parameters ` @{BuildRev='Revision'}
```

### Build coment-based Help files from your scripts

Making help files for your scripts is really easy. Start by decorating the top of every script file or function with the appropriate comments. See the template script we made for you in /public/<your new module>.ps1 to get an idea of what you can do. Go here for more details: [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6)

```powershell
./Build/build.ps1 -tasklist Help
```

### Push your Changes to your Git Repo

```powershell
./Build/Build.ps1 -tasklist UpdateRepo -parameters @{CommitMessage="I fixed a thing and rev'd the build number"}
```

### Using nuget on OSX/Linux

You'll need to add a couple of tools to get Nuget to work on OSX/Linux. Don't forget to set the 'nuget' alias in your PowerShell profile.
[Here for details](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools)

### Deploy your module to your Azure Repo

```powershell
./Build/Build.ps1 -tasklist PublishAzure
```


### Publish your module to PSGallery

```powershell
./Build/Build.ps1 -tasklist PublishPSGallery
```


## More Information

For more information

* [github.com/johnmccrae/PSNow](https://github.com/johnmccrae/PSNow)

## Tested On

* OSX
* Windows 10
* Ubuntu 18.04

### Credits

This project was generated using [Kevin Marquette's](http://kevinmarquette.github.io) [Full Module Plaster Template](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate).

Special Shout Out to Adam Rush for his tutorial on using [PSake.](https://adamrushuk.github.io/example-azure-devops-build-pipeline-for-powershell-modules/)

Inspiration from Adam Bertram aka [Adam the Automator](https://adamtheautomator.com/)

Inspiration also came from [Warren Frame the Rambling Cookie Monster](http://ramblingcookiemonster.github.io/)

Shout out to [Mike Robbins](https://mikefrobbins.com)

## License

This project is [licensed under the MIT License](LICENSE.md).
