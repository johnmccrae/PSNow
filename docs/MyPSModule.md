---
external help file: New-MyPSModule-help.xml
Module Name: New-MyPSModule
online version:
schema: 2.0.0
---

# New-MyPSModule

## SYNOPSIS
A module used to create new PS Modules with.

## SYNTAX

```
New-MyPSModule [-MyNewModuleName] <String> [-BaseManifest] <String> [[-moduleroot] <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module

## EXAMPLES

### Example 1
```powershell
PS C:> New-MyPSModule -MyNewModuleName ContosoExporting -Basemanifest PlasterManifest-extended2.xml -ModuleRoot c:\
```

In the above example you are creating a Module with the name ContosoExporting that is going to be based on a Plaster manifest named PlasterManifest-extended2.xml and it will be created at c:\ContosoExporting\

## PARAMETERS

### -MyNewModuleName
Any string you want to use to describe the name for your new module

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```


### -BaseManifest
We use a Plaster manifest to create your module from. We include 4 examples for you to play with. 3 of them are directly available when you invoke the module. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: PlasterManifest-basic.xml, PlasterManifest-extended.xml, PlasterManifest-extended2.xml

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -moduleroot
The path on the local drive where you want to place the module. This module supports installation on PS Core so you can install it on Linux or Mac OS as well as on Windows. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
