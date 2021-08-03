<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Get-AppInfo.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to get Application and Deployment Type information from ConfigMgr
#>
Function Get-AppInfo {
    Param (
        [String[]]$ApplicationName
    )
 
    Write-CMTraceLog -LogText "Function: Get-AppInfo was called" -LogSeverity "Information" -LogFile $MainLogFile 

    #Create Array to display Application and Deployment Type Information
    $DeploymentTypes = @()
    $ApplicationTypes = @()
    $Content = @()

    #Iterate through each Application and get details
    ForEach ($Application in $ApplicationName) {

        #Grab the SDMPackgeXML which contains the Application and Deployment Type details
        Write-CMTraceLog -LogText "`$XMLPackage = Get-CMApplication -Name ""$($Application)"" | Where-Object { `$Null -ne `$_.SDMPackageXML } | Select-Object -ExpandProperty SDMPackageXML" -LogSeverity "Information" -LogFile $MainLogFile 
        $XMLPackage = Get-CMApplication -Name $Application | Where-Object { $Null -ne $_.SDMPackageXML } | Select-Object -ExpandProperty SDMPackageXML
        
        #Prepare XML from SDMPackageXML
        $XMLContent = [xml]($XMLPackage)

        #Get total number of Deployment Types for the Application
        Write-CMTraceLog -LogText "`$TotalDeploymentTypes = ($($XMLContent).AppMgmtDigest.Application.DeploymentTypes.DeploymentType | Measure-Object | Select-Object -ExpandProperty Count)" -LogSeverity "Information" -LogFile $MainLogFile
        $TotalDeploymentTypes = ($XMLContent.AppMgmtDigest.Application.DeploymentTypes.DeploymentType | Measure-Object | Select-Object -ExpandProperty Count)
        
        If (!($Null -eq $TotalDeploymentTypes) -or (!($TotalDeploymentTypes -eq 0))) {

            $ApplicationObject = New-Object PSCustomObject
            Write-CMTraceLog -LogText "ApplicationObject():" -LogSeverity "Information" -LogFile $MainLogFile
                
            #Application Details
            Write-CMTraceLog -LogText "Application_LogicalName -Value $XMLContent.AppMgmtDigest.Application.LogicalName" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_LogicalName -Value $XMLContent.AppMgmtDigest.Application.LogicalName
            Write-CMTraceLog -LogText "Application_Name -Value $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Title)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_Name -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Title
            Write-CMTraceLog -LogText "Application_Description -Value $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Description)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_Description -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Description
            Write-CMTraceLog -LogText "Application_Publisher -Value $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Publisher)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_Publisher -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Publisher
            Write-CMTraceLog -LogText "Application_Version -Value $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Version)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_Version -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Version
            Write-CMTraceLog -LogText "Application_IconId -Value $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_IconId -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id
            Write-CMTraceLog -LogText "Application_TotalDeploymentTypes -Value $($TotalDeploymentTypes)" -LogSeverity "Information" -LogFile $MainLogFile
            $ApplicationObject | Add-Member NoteProperty -Name Application_TotalDeploymentTypes -Value $TotalDeploymentTypes
                
            #If we have the logo, add the path
            If (!($Null -eq $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id)) {
                Try {
                    If (Test-Path -Path (Join-Path -Path $WorkingFolder_Logos -ChildPath (Join-Path -Path $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id -ChildPath "Logo.jpg"))) {
                        Write-CMTraceLog -LogText "Application_IconPath -Value (Join-Path -Path $($WorkingFolder_Logos) -ChildPath (Join-Path -Path $($XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id) -ChildPath ""Logo.jpg""))" -LogSeverity "Information" -LogFile $MainLogFile
                        $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value (Join-Path -Path $WorkingFolder_Logos -ChildPath (Join-Path -Path $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id -ChildPath "Logo.jpg"))
                    }
                    else {
                        Write-CMTraceLog -LogText "Application_IconPath -Value `$Null" -LogSeverity "Information" -LogFile $MainLogFile
                        $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null
                    }
                }
                Catch {
                    Write-CMTraceLog -LogText "Application_IconPath -Value `$Null" -LogSeverity "Information" -LogFile $MainLogFile
                    $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null
                }
            }
            else {
                Write-CMTraceLog -LogText "Application_IconPath -Value `$Null" -LogSeverity "Information" -LogFile $MainLogFile
                $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null  
            }
                
            $ApplicationTypes += $ApplicationObject
        
            #If Deployment Types exist, iterate through each DeploymentType and build deployment detail
            ForEach ($Object in $XMLContent.AppMgmtDigest.DeploymentType) {

                #Create new custom PSObjects to build line detail
                $DeploymentObject = New-Object -TypeName PSCustomObject
                $ContentObject = New-Object -TypeName PSCustomObject
                Write-CMTraceLog -LogText "DeploymentObject():" -LogSeverity "Information" -LogFile $MainLogFile

                #DeploymentType Details
                Write-CMTraceLog -LogText "Application_LogicalName -Value $($XMLContent.AppMgmtDigest.Application.LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name Application_LogicalName -Value $XMLContent.AppMgmtDigest.Application.LogicalName
                Write-CMTraceLog -LogText "DeploymentType_LogicalName -Value $($Object.LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_LogicalName -Value $Object.LogicalName
                Write-CMTraceLog -LogText "DeploymentType_Name -Value $($Object.Title.InnerText)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_Name -Value $Object.Title.InnerText
                Write-CMTraceLog -LogText "DeploymentType_Technology -Value $($Object.Installer.Technology)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_Technology -Value $Object.Installer.Technology
                Write-CMTraceLog -LogText "DeploymentType_ExecutionContext -Value $($Object.Installer.ExecutionContext)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_ExecutionContext -Value $Object.Installer.ExecutionContext
                Write-CMTraceLog -LogText "DeploymentType_InstallContent -Value $($Object.Installer.CustomData.InstallContent.ContentId)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_InstallContent -Value $Object.Installer.CustomData.InstallContent.ContentId
                Write-CMTraceLog -LogText "DeploymentType_InstallCommandLine -Value $($Object.Installer.CustomData.InstallCommandLine)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_InstallCommandLine -Value $Object.Installer.CustomData.InstallCommandLine
                Write-CMTraceLog -LogText "DeploymentType_UnInstallSetting -Value $($Object.Installer.CustomData.UnInstallSetting)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_UnInstallSetting -Value $Object.Installer.CustomData.UnInstallSetting
                Write-CMTraceLog -LogText "DeploymentType_UninstallContent -Value $$($Object.Installer.CustomData.UninstallContent.ContentId)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_UninstallContent -Value $Object.Installer.CustomData.UninstallContent.ContentId
                Write-CMTraceLog -LogText "DeploymentType_UninstallCommandLine -Value $($Object.Installer.CustomData.UninstallCommandLine)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_UninstallCommandLine -Value $Object.Installer.CustomData.UninstallCommandLine
                Write-CMTraceLog -LogText "DeploymentType_ExecuteTime -Value $($Object.Installer.CustomData.ExecuteTime)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_ExecuteTime -Value $Object.Installer.CustomData.ExecuteTime
                Write-CMTraceLog -LogText "DeploymentType_MaxExecuteTime -Value $($Object.Installer.CustomData.MaxExecuteTime)" -LogSeverity "Information" -LogFile $MainLogFile
                $DeploymentObject | Add-Member NoteProperty -Name DeploymentType_MaxExecuteTime -Value $Object.Installer.CustomData.MaxExecuteTime

                $DeploymentTypes += $DeploymentObject

                #Content Details
                Write-CMTraceLog -LogText "ContentObject():" -LogSeverity "Information" -LogFile $MainLogFile
                Write-CMTraceLog -LogText "Content_DeploymentType_LogicalName -Value $($Object.LogicalName)" -LogSeverity "Information" -LogFile $MainLogFile
                $ContentObject | Add-Member NoteProperty -Name Content_DeploymentType_LogicalName -Value $Object.LogicalName
                Write-CMTraceLog -LogText "Content_Location -Value $($Object.Installer.Contents.Content.Location)" -LogSeverity "Information" -LogFile $MainLogFile
                $ContentObject | Add-Member NoteProperty -Name Content_Location -Value $Object.Installer.Contents.Content.Location

                $Content += $ContentObject                
            }
        }
        else {
            Write-CMTraceLog -LogText "Warning: No DeploymentTypes found for ""$($XMLContent.AppMgmtDigest.Application.LogicalName)""" -LogSeverity "Warning" -LogFile $MainLogFile
            Write-Host "Warning: No DeploymentTypes found for ""$($XMLContent.AppMgmtDigest.Application.LogicalName)"" " -ForegroundColor Yellow
        }
    } 
    Return $DeploymentTypes, $ApplicationTypes, $Content
}

#Clear Logs if -ResetLog Parameter was passed
If ($ResetLog) {
    Write-CMTraceLog -LogText "The -ResetLog Parameter was passed to the script" -LogSeverity "Information" -LogFile $MainLogFile
    Try {
        Write-CMTraceLog -LogText "Get-ChildItem -Path $($WorkingFolder_Logs) | Remove-Item -Force" -LogSeverity "Information" -LogFile $MainLogFile
        Get-ChildItem -Path $WorkingFolder_Logs | Remove-Item -Force
    }
    Catch {
        Write-CMTraceLog -LogText "Error: Unable to delete log files at $($WorkingFolder_Logs). Do you have it open?" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "Error: Unable to delete log files at $($WorkingFolder_Logs). Do you have it open?" -ForegroundColor Red
    }
}