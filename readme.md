# PSNow

A module for making modules.

Ever looked at modules and wondered how the heck someone figured out how to do all that? What's a build process? How does that build process even work? Where do you go to pull all these bits together? That takes forever and you have problems to solve!

Enter PSNow! We're taking the guesswork out of writing PowerShell modules by creating all the basic plumbing for you.

Simply copy and paste the the code snippet below to get started. The creation process will ask you some basic questions about your new module and will then create everything you need to get going.

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

Now setup your environment. The second command will duplicate your build environment variables but will let you see them outside the rest of the process.

```powershell
./Build/Build.ps1 -tasklist init
Get-Item env:BH*
```



### Write Out Test Cases for Your Code

This module supports the Gherkin DSL as well as Pester for Test Driven Development. When following that pattern, you write your tests first to clarify your thinking around what you expect your module and scripts to do. Then go back and write your first script. Navigate to /Tests/Features and write the test for your first script there. Then run this to test your code.

Just below you'll notice that we 'stage' the project. This creates a directory called /Staging and puts a working copy of your code there. We're following the principle that the default

```powershell
./Build/Build.ps1 -tasklist stage
./Build/Build.ps1 -tasklist test
```



### Analyze your code for defects

You should check your code for defects and linting issues by running PS Script Analyzer

```powershell
./Build/build.ps1 -tasklist analyze
```



### Build your scripts into nuspec modules



### Sign your code with a self-signed certificate

@lbertolotti You're getting UnkownError because your self-signed certificate isn't trusted in the Root certificate store. While New-SelfSignedCertificate won't let you store in the Root store, you can do it with Export/Import-Certificate. Here's some repro code:



### Deploy your module to your nodes using Azure CI CD Pipelines





### Publish your module to PSGallery







## More Information

For more information

* [github.com/johnmccrae/PSNow](https://github.com/johnmccrae/PSNow)
* [johnmccrae.github.io](https://johnmccrae.github.io)


This project was generated using [Kevin Marquette](http://kevinmarquette.github.io)'s [Full Module Plaster Template](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate).




## License

This project is [licensed under the MIT License](LICENSE).



