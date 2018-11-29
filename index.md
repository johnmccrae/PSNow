## New-MyPSModule
A PowerShell module that uses Plaster to create a new module for you! In essence, a module-building module that builds modules!

This module is based on some really fine work by Mike Robbins,Markus Kraus and Kevin Marquette.

When you run the module with all options accepted it will create every single thing you need to fully create, test, and deploy your module from the various VSCode settings file, the nuspec file needed to create a package, help file stubs and everything in between. 

## Compatibility
This module is designed to run under PowerShell Core or PowerShell Desktop so it will run correctly on Windows, OSX and Linux

## Installation
Pull the files down and install them where you wish.

## Usage
```PowerShell
import-module new-mypsmodule
New-MyPSModule -MyNewModuleName mynewmodule -BaseManifest PlasterManifest-extended2.xml -Modulepath "C:\modules"
```

## Where to start
Read about the dependencies in the header of the new-mypsmodule file and install them as need be
