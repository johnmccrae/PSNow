---
external help file: PSNow-help.xml
Module Name: psnow
online version:
schema: 2.0.0
---

# New-PSNowModule

## SYNOPSIS
A module used to create new PS Modules with.

## SYNTAX

```
New-PSNowModule [-NewModuleName] <String> [-BaseManifest] <String> [[-ModuleRoot] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module.
It runs on PSCore and all supported platforms.

## EXAMPLES

### EXAMPLE 1
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest basic
```

Creates the new PS Module using the "basic" plaster mainfest which creates a minimal module for you

### EXAMPLE 2
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Extended -ModuleRoot ~/modules/myfabmodule
```

This choice uses the Extended manifest and create the module in /modules.
Note that the module and pathing work for all versions of PS Core and PS Windows - Linux and OSX are supported platforms

### EXAMPLE 3
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Advanced -ModuleRoot c:\myfabmodule
```

This choice creates a fully fleshed out PowerShell module with full support for Pester, Git, PlatyPS and more.
See the Advanced.xml file located in /PlasterTemplate

## PARAMETERS

### -NewModuleName
The name you wish to give your new module

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseManifest
You are selecting from 3 Plaster manifests located in the /PlasterTemplate directory - Advanced is the best choice

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleRoot
Where do you want your new module to live?
The default is to put it in a /Modules folder off your drive root

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General Notes

## RELATED LINKS
