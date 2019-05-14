# New-MyPSModule 

A module used as scaffolding to create an entire PowerShell module framework. This module builds everything you need to create, test, build, and deploy and publish your module

## GitHub ReadMe

* [github.com/johnmccrae/New-MyPSModule](https://github.com/johnmccrae/New-MyPSModule)

## Getting Started

### Install from the PSGallery and Import the module

    Install-Module New-MyPSModule 
    Import-Module New-MyPSModule 

### Create your scripts - New-MyPSModule
```powershell
    New-MyPSModule -MyNewModuleName ReallyGreatModule -BaseManifest Advanced.xml -ModuleRoot c:\
```

- use readme.ps1 to create a readme.md for your module

## Write out your test cases for your scripts
This module supports the Gherkin DSL for specification creation and Test Driven Development. When following that pattern, you write your tests first to clarify your thinking around what you expect your module and scripts to do. 

### Spec out features using the Gherkin DSL

### Test your scripts by calling Gherkin which in turn calls feature tests using Pester

### Build your scripts into nuspec module

### Deploy your module to your nodes using Azure CI CD Pipelines

### Publish your module to PSGallery

## More Information

For more information

* [github.com/johnmccrae/New-MyPSModule](https://github.com/johnmccrae/New-MyPSModule)
* [johnmccrae.github.io](https://johnmccrae.github.io)


This project was generated using [Kevin Marquette](http://kevinmarquette.github.io)'s [Full Module Plaster Template](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate).
