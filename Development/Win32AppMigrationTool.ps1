Import-Module -Name Win32AppMigrationTool
New-Item -Path "S:\Temp" -Name "MEM_Mig" -ItemType Directory

New-Win32App -SiteCode 001 -ProviderMachineName "pviessccm101.konzern.dir" -AppName "BauBit*" -ExportLogo -WorkingFolder "S:\temp\MEM_Mig" -PackageApps -CreateApps

New-Win32App -SiteCode 001 -ProviderMachineName "pviessccm101.konzern.dir" -AppName "Check Point*" -ExportLogo -WorkingFolder "S:\temp\MEM_Mig" -PackageApps -CreateApps
