﻿#
# Module manifest for module 'DSCPullServerAdmin'
#
# Generated by: Ben Gelens
#
# Generated on: 7-2-2017
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'DSCPullServerAdmin.psm1'

# Version number of this module.
ModuleVersion = '0.0.1.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'eb129ddc-06f0-4394-aee7-6ccd9392263c'

# Author of this module
Author = 'Ben Gelens'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2018 Ben Gelens. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Get, manipulate and migrate data from your DSC Pull Server database (EDB and SQL)'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('Microsoft.Isam.Esent.Interop')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = '*'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-DSCPullServerAdminConnection',
    'Get-DSCPullServerAdminDevice',
    'Get-DSCPullServerAdminRegistration',
    'Get-DSCPullServerAdminStatusReport',
    'New-DSCPullServerAdminConnection',
    'New-DSCPullServerAdminDevice',
    'New-DSCPullServerAdminRegistration',
    'New-DSCPullServerAdminStatusReport',
    'Remove-DSCPullServerAdminConnection',
    'Remove-DSCPullServerAdminDevice',
    'Remove-DSCPullServerAdminRegistration',
    'Remove-DSCPullServerAdminStatusReport',
    'Set-DSCPullServerAdminConnectionActive',
    'Set-DSCPullServerAdminDevice',
    'Set-DSCPullServerAdminRegistration',
    'Set-DSCPullServerAdminStatusReport',
    'Copy-DSCPullServerAdminDataESEToSQL',
    'New-DSCPullServerAdminSQLDatabase'
)

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PSDSC', 'DesiredStateConfiguration', 'PullServer'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/bgelens/DSCPullServerAdmin/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/bgelens/DSCPullServerAdmin'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'No changes, build pipeline update to create GitHub releases togheter with PSGallery Publishing'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

