<#
.Synopsis
Created on:   14/03/2021
Created by:   Ben Whitmore
Filename:     New-Win32App.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

The Win32 App Migration Tool is designed to inventory ConfigMgr Applications and Deployment Types, build .intunewin files and create Win3Apps in The MEM Admin Center.

Instead of manually checking Application and Deployment Type information and gathering content to build Win32apps, the Win32APp Migration Tool is designed to do that for you. To date, the Application and Deployment Type information is gathered and a .Intunewin file is created. We are also collecting the logo for the application.

The Win32App Migration Tool is still in BETA so I would welcome any feedback or suggestions for improvement. Reach out on Twitter to DM @byteben (DM's are open)

.Description
**Version 1.03.27.02 - 27/03/2021 - BETA**  
- Fixed a grammar issue when creating the Working Folders

**Version 1.03.25.01 - 25/03/2021 - BETA**  
- Removed duplicate name in message for successful .intunewin creation
- Added a new switch "-NoOGV" which will suppress the Out-Grid view. Thanks @philschwan
- Fixed an issue where the -ResetLog parameter was not working

**Version 1.03.23.01 - 23/03/2021 - BETA**  
- Error handling improved when connecting to the Site Server and passing a Null app name

**Version 1.03.22.01 - 22/03/2021 - BETA**  
- Updates Manifest to only export New-Win32App Function

**Version 1.03.21.03 - 21/03/2021 - BETA**  
- Fixed RootModule issue in psm1

**Version 1.03.21.03 - 21/03/2021 - BETA**  
- Fixed Function error for New-Win32App

**Version 1.03.21.01 - 21/03/2021 - BETA**  
- Added to PSGallery and converted to Module

**Version 1.03.20.01 - 20/03/2021 - BETA**  
- Added support for .vbs script installers  
- Fixed logic error for string matching  
    
**Version 1.03.19.01 - 19/03/2021 - BETA**    
- Added Function Get-ScriptEnd  
  
**Version 1.03.18.03 - 18/03/2021 - BETA**   
- Fixed an issue where Intunewin SetupFile was being detected as an .exe when msiexec was present in the install command  
  
**Version 1.03.18.02 - 18/03/2021 - BETA**   
- Removed the character " from SetupFile command when an install command is wrapped in double quotes  
  
**Version 1.03.18.01 - 18/03/2021  - BETA**  
- Robocopy for content now padding Source and Destination variables if content path has white space  
- Deployment Type Count was failing from the SDMPackageXML. Using the measure tool to check if Deployment Types exist for an Application  
- Removed " from SetupFile command if install commands are in double quotes  
  
**Version 1.03.18 - 18/03/2021  - BETA**
- Release for Testing  
- Logging Added  

**Version 1.0 - 14/03/2021 - DEV**  
- DEV Release  

.Parameter AppName
Pass a string to the toll to search for applications in ConfigMgr

.Parameter SiteCode
Specify the Sitecode you wish to connect to

.Parameter ProviderMachineName
Specify the Site Server to connect to

.Parameter ExportLogo
When passed, the Application logo is decoded from base64 and saved to the Logos folder

.Parameter WorkingFolder
This is the working folder for the Win32AppMigration Tool. Care should be given when specifying the working folder because downloaded content can increase the working folder size considerably. The Following folders are created in this directory:-

-Content
-ContentPrepTool
-Details
-Logos
-Logs
-Win32Apps

.Parameter PackageApps
Pass this parameter to package selected apps in the .intunewin format

.Parameter CreateApps
Pass this parameter to create the Win32apps in Intune

.Parameter ResetLog
Pass this parameter to reset the log file

.Example
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *"

.Example
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo

.Example
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps

.Example
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps

.Example
New-Win32App -SiteCode "BB1" -ProviderMachineName "SCCM1.byteben.com" -AppName "Microsoft Edge Chromium *" -ExportLogo -PackageApps -CreateApps -ResetLog
#>
Function New-Win32App {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String]$AppName,
        [Parameter(Mandatory = $True)]
        [String]$ProviderMachineName,
        [Parameter(Mandatory = $True)]
        [ValidateLength(3, 3)]
        [String]$SiteCode,   
        [Parameter()]
        [Switch]$ExportLogo,
        [String]$WorkingFolder = "C:\Win32AppMigrationTool",
        [Switch]$PackageApps,
        [Switch]$CreateApps,
        [Switch]$ResetLog,
        [Switch]$NoOGV
    )

    #Create Global Variables
    $Global:SiteCode = $SiteCode
    $Global:WorkingFolder_Root = $WorkingFolder
    $Global:WorkingFolder_Logos = Join-Path -Path $WorkingFolder_Root -ChildPath "Logos"
    $Global:WorkingFolder_Content = Join-Path -Path $WorkingFolder_Root -ChildPath "Content"
    $Global:WorkingFolder_ContentPrepTool = Join-Path -Path $WorkingFolder_Root -ChildPath "ContentPrepTool"
    $Global:WorkingFolder_Logs = Join-Path -Path $WorkingFolder_Root -ChildPath "Logs"
    $Global:WorkingFolder_Detail = Join-Path -Path $WorkingFolder_Root -ChildPath "Details"
    $Global:WorkingFolder_Win32Apps = Join-Path -Path $WorkingFolder_Root -ChildPath "Win32Apps"

    #Initialize Woking Folder and Log Folder Folders
    Write-Host "Initializing Required Folders..." -ForegroundColor Cyan
    If (!(Test-Path -Path $WorkingFolder_Root)) {
        New-Item -Path $WorkingFolder_Root -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    If (!(Test-Path -Path $WorkingFolder_Logs)) {
        New-Item -Path $WorkingFolder_Logs -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    
    $Global:MainLogFile = Join-Path -Path $WorkingFolder_Logs -ChildPath "Main.log"

    If ($ResetLog) {
        Write-CMTraceLog -LogText "Starting new Log" -LogSeverity "Information" -LogFile $MainLogFile -ResetLogFile
    }
    
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "Script Start Win32AppMigrationTool" -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host 'Script Start Win32AppMigrationTool' -ForegroundColor DarkGray
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''

    $ScriptRoot = $PSScriptRoot
    Write-CMTraceLog -LogText "ScriptRoot = $($ScriptRoot)" -LogSeverity "Information" -LogFile $MainLogFile 

    #Connect to Site Server
    Connect-SiteServer -SiteCode  $SiteCode -ProviderMachineName $ProviderMachineName

    #Region Check_Folders
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "Checking Win32AppMigrationTool Folder Structure..." -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-Host ''
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host 'Checking Win32AppMigrationTool Folder Structure...' -ForegroundColor DarkGray
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''

    #Create Folders
    Write-Host "Creating Folders..."-ForegroundColor Cyan
    New-FolderToCreate -Root $WorkingFolder_Root -Folders @("", "Logs")
    Write-CMTraceLog -LogText "New-FolderToCreate -Root ""$($WorkingFolder_Root)"" -Folders @(""Logos"", ""Content"", ""ContentPrepTool"",  ""Details"", ""Win32Apps"")" -LogSeverity "Information" -LogFile $MainLogFile 
    New-FolderToCreate -Root $WorkingFolder_Root -Folders @("Logos", "Content", "ContentPrepTool", "Details", "Win32Apps")
    #EndRegion Check_Folders

    #Region Get_Content_Tool
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "Checking Win32AppMigrationTool Content Tool..." -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-Host ''
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host 'Checking Win32AppMigrationTool Content Tool...' -ForegroundColor DarkGray
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''

    #Download Win32 Content Prep Tool
    If ($PackageApps) {
        Write-Host "Downloadling Win32 Content Prep Tool..." -ForegroundColor Cyan
        If (Test-Path (Join-Path -Path $WorkingFolder_ContentPrepTool -ChildPath "IntuneWinAppUtil.exe")) {
            Write-CMTraceLog -LogText "Information: IntuneWinAppUtil.exe already exists at ""$($WorkingFolder_ContentPrepTool)"". Skipping download" -LogSeverity "Information" -LogFile $MainLogFile 
            Write-Host "Information: IntuneWinAppUtil.exe already exists at ""$($WorkingFolder_ContentPrepTool)"". Skipping download" -ForegroundColor Magenta
        }
        else {
            Write-CMTraceLog -LogText "Get-FileFromInternet -URI ""https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"" -Destination $($WorkingFolder_ContentPrepTool)" -LogSeverity "Information" -LogFile $MainLogFile 
            Get-FileFromInternet -URI "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe" -Destination $WorkingFolder_ContentPrepTool
        }
    } 
    else {
        Write-CMTraceLog -LogText "The -PackageApps parameter was not passed. Skipping downloading of the Win32 Content Prep Tool." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "The -PackageApps parameter was not passed. Skipping downloading of the Win32 Content Prep Tool." -ForegroundColor Magenta
    }
    #EndRegion Get_Content_Tool


    #Region Display_Application_Results
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "Checking Applications..." -LogSeverity "Information" -LogFile $MainLogFile
    Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
    Write-Host ''
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host 'Checking Applications...' -ForegroundColor DarkGray
    Write-Host '--------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''

    #Get list of Applications
    If (!$NoOGV) {
        Write-CMTraceLog -LogText "Get-CMApplication -Fast | Where-Object { $($_.LocalizedDisplayName) -like $($AppName) } | Select-Object -ExpandProperty LocalizedDisplayName | Sort-Object | Out-GridView -PassThru -OutVariable $($ApplicationName) -Title ""Select an Application(s) to process the associated Deployment Types""" -LogSeverity "Information" -LogFile $MainLogFile 
        $ApplicationName = Get-CMApplication -Fast | Where-Object { $_.LocalizedDisplayName -like "$AppName" } | Select-Object -ExpandProperty LocalizedDisplayName | Sort-Object | Out-GridView -Passthru -Title "Select an Application(s) to process the associated Deployment Types"
    }
    else {
        Write-CMTraceLog -LogText "Get-CMApplication -Fast | Where-Object { $($_.LocalizedDisplayName) -like $($AppName) } | Select-Object -ExpandProperty LocalizedDisplayName" -LogSeverity "Information" -LogFile $MainLogFile 
        $ApplicationName = Get-CMApplication -Fast | Where-Object { $_.LocalizedDisplayName -like "$AppName" } | Select-Object -ExpandProperty LocalizedDisplayName 
    }
    
    If ($ApplicationName) {
        Write-CMTraceLog -LogText "The Win32App Migration Tool will process the following Applications:" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host "The Win32App Migration Tool will process the following Applications:"
        ForEach ($Application in $ApplicationName) {
            Write-CMTraceLog -LogText "$($Application)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host """$($Application)""" -ForegroundColor Green
        }
    }
    else {
        Write-CMTraceLog -LogText "AppName ""$($AppName)"" could not be found or no selection was made." -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "AppName ""$($AppName)"" could not be found or no selection was made. Please re-run the tool and try again. The AppName parameter does accept wildcards i.e. *" -ForegroundColor Red
        Get-ScriptEnd
        break
    }
    #EndRegion Display_Application_Results

    #Region Export_Details_CSV
    Write-CMTraceLog -LogText "Calling function to grab deployment type detail for application(s)" -LogSeverity "Information" -LogFile $MainLogFile 
    #Calling function to grab deployment type detail for application(s)
    Write-CMTraceLog -LogText "`$App_Array = Get-AppInfo -ApplicationName ""$($ApplicationName)""" -LogSeverity "Information" -LogFile $MainLogFile
    $App_Array = Get-AppInfo -ApplicationName $ApplicationName
    $DeploymentTypes_Array = $App_Array[0]
    $Applications_Array = $App_Array[1]
    $Content_Array = $App_Array[2]

    #Export $DeploymentTypes to CSV for reference
    Try {
        $DeploymentTypes_Array | Export-Csv (Join-Path -Path $WorkingFolder_Detail -ChildPath "DeploymentTypes.csv") -NoTypeInformation -Force
        Write-CMTraceLog -LogText "`$DeploymentTypes_Array is located at $($WorkingFolder_Detail)\DeploymentTypes.csv" -LogSeverity "Information" -LogFile $MainLogFile 
    }
    Catch {
        Write-Host "Error: Could not Export DeploymentTypes.csv. Do you have it open?" -ForegroundColor Red
        Write-CMTraceLog -LogText "Error: Could not Export DeploymentTypes.csv. Do you have it open?" -LogSeverity "Error" -LogFile $MainLogFile 
    }
    Try {
        $Applications_Array | Export-Csv (Join-Path -Path $WorkingFolder_Detail -ChildPath "Applications.csv") -NoTypeInformation -Force
        Write-CMTraceLog -LogText "`$Applications_Array is located at $($WorkingFolder_Detail)\Applications.csv" -LogSeverity "Information" -LogFile $MainLogFile 
    }
    Catch {
        Write-Host "Error: Could not Export Applications.csv. Do you have it open?" -ForegroundColor Red
        Write-CMTraceLog -LogText "Error: Could not Export Applications.csv. Do you have it open?" -LogSeverity "Error" -LogFile $MainLogFile 
    }
    Try {
        $Content_Array | Export-Csv (Join-Path -Path $WorkingFolder_Detail -ChildPath "Content.csv") -NoTypeInformation -Force
        Write-CMTraceLog -LogText "`$Content_Array is located at $($WorkingFolder_Detail)\Content.csv" -LogSeverity "Information" -LogFile $MainLogFile 
    }
    Catch {
        Write-Host "Error: Could not Export Content.csv. Do you have it open?" -ForegroundColor Red
        Write-CMTraceLog -LogText "Error: Could not Export Content.csv. Do you have it open?" -LogSeverity "Error" -LogFile $MainLogFile 
    }
    Write-Host "Details of the selected Applications and Deployment Types can be found at ""$($WorkingFolder_Detail)"""
    #EndRegion Export_Details_CSV

    #Region Exporting_Logos
    If ($ExportLogo) {

        #Call function to export logo for application
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "Exporting Logo(s)..." -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Exporting Logo(s)...' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''

        ForEach ($Application in $Applications_Array) {
            Write-CMTraceLog -LogText "`$IconId = $($Application.Application_IconId)" -LogSeverity "Information" -LogFile $MainLogFile
            $IconId = $Application.Application_IconId
            Write-CMTraceLog -LogText "Export-Logo -IconId $($IconId) -AppName $($Application.Application_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Export-Logo -IconId $IconId -AppName $Application.Application_Name
        }
    }
    #EndRegion Exporting_Logos

    #Region Package_Apps
    #If the $PackageApps parameter was passed. Use the Win32Content Prep Tool to build Intune.win files
    If ($PackageApps) {
        #Region Creating_Application_Folders
        Write-CMTraceLog -LogText "`$PackageApps Parameter passed" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "Creating Application Folder(s)" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Creating Application Folder(s)' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''

        ForEach ($Application in $Applications_Array) {

            #Create Application Parent Folder(s)
            Write-CMTraceLog -LogText "Application: $($Application.Application_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Application: ""$($Application.Application_Name)"""
            Write-CMTraceLog -LogText "Creating Application Folder $($Application.Application_LogicalName) for Application $($Application.Application_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Creating Application Folder ""$($Application.Application_LogicalName)"" for Application ""$($Application.Application_Name)""" -ForegroundColor Cyan
            If (!(Test-Path -Path (Join-Path -Path $WorkingFolder_Win32Apps -ChildPath $Application.Application_LogicalName ))) {
                Write-CMTraceLog -LogText "New-FolderToCreate -Root $($WorkingFolder_Win32Apps) -Folders $($Application.Application_LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                New-FolderToCreate -Root $WorkingFolder_Win32Apps -Folders $Application.Application_LogicalName
            }
            else {
                Write-CMTraceLog -LogText "Information: Application Folder $($Application.Application_LogicalName) already exists" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Information: Application Folder ""$($Application.Application_LogicalName)"" already exists" -ForegroundColor Magenta
            }
            Write-Host ''
        }
        #EndRegion Creating_Application_Folders

        #Region Creating_DeploymentType_Folders
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "Creating DeploymentType Folder(s)" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Creating DeploymentType Folder(s)' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''
        ForEach ($DeploymentType in $DeploymentTypes_Array) {

            #Create DeploymentType Child Folder(s)
            Write-CMTraceLog -LogText "Creating DeploymentType Folder $($DeploymentType.DeploymentType_LogicalName) for DeploymentType $($DeploymentType.DeploymentType_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Creating DeploymentType Folder ""$($DeploymentType.DeploymentType_LogicalName)"" for DeploymentType ""$($DeploymentType.DeploymentType_Name)""" -ForegroundColor Cyan
            If (!(Test-Path -Path (Join-Path -Path (Join-Path -Path $WorkingFolder_Win32Apps -ChildPath $DeploymentType.Application_LogicalName ) -ChildPath $DeploymentType.DeploymentType_LogicalName))) {
                Write-CMTraceLog -LogText "New-FolderToCreate -Root $($WorkingFolder_Win32Apps) -Folders (Join-Path -Path $($DeploymentType.Application_LogicalName) -ChildPath $($DeploymentType.DeploymentType_LogicalName))" -LogSeverity "Information" -LogFile $MainLogFile
                New-FolderToCreate -Root $WorkingFolder_Win32Apps -Folders (Join-Path -Path $DeploymentType.Application_LogicalName -ChildPath $DeploymentType.DeploymentType_LogicalName)
            }
            else {
                Write-CMTraceLog -LogText "Information: Folder ""$($WorkingFolder_Win32Apps)\$($DeploymentType.DeploymentType_LogicalName)\$($DeploymentType.DeploymentType_LogicalName)"" already exists" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Information: Folder ""$($WorkingFolder_Win32Apps)\$($DeploymentType.DeploymentType_LogicalName)\$($DeploymentType.DeploymentType_LogicalName)"" already exists" -ForegroundColor Magenta
            }
            Write-Host ''
        }
        #EndRegion Creating_DeploymentType_Folders

        #Region Creating_Content_Folders
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "Creating Content Folder(s)" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Creating Content Folder(s)' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''
        ForEach ($DeploymentType in $DeploymentTypes_Array) {

            #Create DeploymentType Content Folder(s)
            Write-CMTraceLog -LogText "Creating DeploymentType Content Folder for DeploymentType $($DeploymentType.DeploymentType_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Creating DeploymentType Content Folder for DeploymentType ""$($DeploymentType.DeploymentType_Name)""" -ForegroundColor Cyan
            If (!(Test-Path -Path (Join-Path -Path $WorkingFolder_Content -ChildPath $DeploymentType.Application_LogicalName))) {
                Write-CMTraceLog -LogText "New-FolderToCreate -Root $($WorkingFolder_Content) -Folders $($DeploymentType.DeploymentType_LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                New-FolderToCreate -Root $WorkingFolder_Content -Folders $DeploymentType.DeploymentType_LogicalName
            }
            else {
                Write-CMTraceLog -LogText "Information: Folder ""$($WorkingFolder_Content)\$($DeploymentType.DeploymentType_LogicalName)"" Content already exists" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Information: Folder ""$($WorkingFolder_Content)\$($DeploymentType.DeploymentType_LogicalName)"" Content already exists" -ForegroundColor Magenta
            }
            Write-Host ''
        }
        #EndRegion Creating_Content_Folders

        #Region Downloading_Content
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "Downloading Content" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Downloading Content' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''

        ForEach ($Content in $Content_Array) {
            Write-CMTraceLog -LogText "Downloading Content for Deployment Type $($Content.Content_DeploymentType_LogicalName) from Content Source $($Content.Content_Location)..." -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Downloading Content for Deployment Type ""$($Content.Content_DeploymentType_LogicalName)"" from Content Source ""$($Content.Content_Location)""..." -ForegroundColor Cyan
            Write-CMTraceLog -LogText "Get-ContentFiles -Source $($Content.Content_Location) -Destination (Join-Path -Path $($WorkingFolder_Content) -ChildPath $($Content.Content_DeploymentType_LogicalName))" -LogSeverity "Information" -LogFile $MainLogFile 
            Get-ContentFiles -Source $Content.Content_Location -Destination (Join-Path -Path $WorkingFolder_Content -ChildPath $Content.Content_DeploymentType_LogicalName)
        }
        #EndRegion Downloading_Content

        #Region Create_Intunewin_Files
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-CMTraceLog -LogText "Creating .IntuneWin File(s)" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Creating .IntuneWin File(s)' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray

        #Get Application and Deployment Type Details and Files
        ForEach ($Application in $Applications_Array) {
            Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile 
            Write-CMTraceLog -LogText "$($Application.Application_Name)" -LogSeverity "Information" -LogFile $MainLogFile
            Write-CMTraceLog -LogText "There are a total of $($Application.Application_TotalDeploymentTypes) Deployment Types for this Application:" -LogSeverity "Information" -LogFile $MainLogFile
            Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host ''
            Write-Host '--------------------------------------------' -ForegroundColor DarkGray
            Write-Host """$($Application.Application_Name)""" -ForegroundColor Green
            Write-Host "There are a total of $($Application.Application_TotalDeploymentTypes) Deployment Types for this Application:"
            Write-Host '--------------------------------------------' -ForegroundColor DarkGray
            Write-Host ''

            ForEach ($Deployment in $DeploymentTypes_Array | Where-Object { $_.Application_LogicalName -eq $Application.Application_LogicalName }) {
            
                Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile 
                Write-CMTraceLog -LogText "$($Deployment.DeploymentType_Name)" -LogSeverity "Information" -LogFile $MainLogFile
                Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host '--------------------------------------------' -ForegroundColor DarkGray
                Write-Host """$($Deployment.DeploymentType_Name)""" -ForegroundColor Green
                Write-Host '--------------------------------------------' -ForegroundColor DarkGray
                Write-Host ''

                #Grab install command executable or script
                $SetupFile = $Deployment.DeploymentType_InstallCommandLine
                Write-CMTraceLog -LogText "Install Command: ""$($SetupFile)""" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Install Command: ""$($SetupFile)"""

                ForEach ($Content in $Content_Array | Where-Object { $_.Content_DeploymentType_LogicalName -eq $Deployment.DeploymentType_LogicalName }) {

                    #Create variables to pass to Function
                    Write-CMTraceLog -LogText "`$ContentFolder = Join-Path -Path $($WorkingFolder_Content) -ChildPath $($Deployment.DeploymentType_LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                    $ContentFolder = Join-Path -Path $WorkingFolder_Content -ChildPath $Deployment.DeploymentType_LogicalName
                    Write-CMTraceLog -LogText "`$OutputFolder = Join-Path -Path (Join-Path -Path $($WorkingFolder_Win32Apps) -ChildPath $($Application.Application_LogicalName)) -ChildPath $Deployment.DeploymentType_LogicalName" -LogSeverity "Information" -LogFile $MainLogFile
                    $OutputFolder = Join-Path -Path (Join-Path -Path $WorkingFolder_Win32Apps -ChildPath $Application.Application_LogicalName) -ChildPath $Deployment.DeploymentType_LogicalName
                    Write-CMTraceLog -LogText "Install Command: ""$($SetupFile)""" -LogSeverity "Information" -LogFile $MainLogFile
                    $SetupFile = $Deployment.DeploymentType_InstallCommandLine

                    Write-CMTraceLog -LogText "Content Folder: ""$($ContentFolder)""" -LogSeverity "Information" -LogFile $MainLogFile
                    Write-Host "Content Folder: ""$($ContentFolder)"""
                    Write-CMTraceLog -LogText "Intunewin Output Folder: ""$($OutputFolder)""" -LogSeverity "Information" -LogFile $MainLogFile
                    Write-Host "Intunewin Output Folder: ""$($OutputFolder)"""
                    Write-Host ''
                    Write-CMTraceLog -LogText "Creating .Intunewin for ""$($Deployment.DeploymentType_Name)""..." -LogSeverity "Information" -LogFile $MainLogFile 
                    Write-Host "Creating .Intunewin for ""$($Deployment.DeploymentType_Name)""..." -ForegroundColor Cyan
                    Write-CMTraceLog -LogText "`$IntuneWinFileCommand = New-IntuneWin -ContentFolder $($ContentFolder) -OutputFolder $($OutputFolder) -SetupFile $($SetupFile)" -LogSeverity "Information" -LogFile $MainLogFile
                    New-IntuneWin -ContentFolder $ContentFolder -OutputFolder $OutputFolder -SetupFile $SetupFile
                }
            }
        }
        #EndRegion Create_Intunewin_Files
    }
    else {
        Write-CMTraceLog -LogText "The -PackageApps parameter was not passed. Application and Deployment Type information will be gathered only, content will not be downloaded" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "The -PackageApps parameter was not passed. Application and Deployment Type information will be gathered only, content will not be downloaded" -ForegroundColor Magenta
    }
    #EndRegion Package_Apps

    #Region Create_Apps
    #If the $CreateApps parameter was passed. Use the Win32Content Prep Tool to create Win32 Apps
    If ($CreateApps) {
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-CMTraceLog -LogText "Creating Win32 Apps" -LogSeverity "Information" -LogFile $MainLogFile
        Write-CMTraceLog -LogText "--------------------------------------------" -LogSeverity "Information" -LogFile $MainLogFile
        Write-Host ''
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host 'Creating Win32 Apps' -ForegroundColor DarkGray
        Write-Host '--------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''
        #####----------------------IN DEVELOPMENT----------------------#####
    }
    #EndRegion Create_Apps
    Get-ScriptEnd
}