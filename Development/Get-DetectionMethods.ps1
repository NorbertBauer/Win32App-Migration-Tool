﻿# Site configuration
$SiteCode = "001" # Site code 
$ProviderMachineName = "pviessccm101.konzern.dir" # SMS Provider machine name
$initParams = @{}
# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}
# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
$StartLocation = Get-Location

# Set the current location to be the site code.
[String[]]$ApplicationName = "7-Zip 19.00 (x64)"
[String[]]$ApplicationName = "Check Point Endpoint Security 84.30 (Initial Client)"
[String[]]$ApplicationName = "Test MEM Export"
[String[]]$ApplicationName = "iTunes 12.11.0.26 RZ203231260"

Set-Location "$($SiteCode):\" @initParams

#Create Array to display Application and Deployment Type Information
$DeploymentTypes = @()
$ApplicationTypes = @()
$Content = @()
$Application = $ApplicationName[0]
    #Grab the SDMPackgeXML which contains the Application and Deployment Type details
    $XMLPackage = Get-CMApplication -Name $Application | Where-Object { $Null -ne $_.SDMPackageXML } | Select-Object -ExpandProperty SDMPackageXML
    
    #Prepare XML from SDMPackageXML
    $XMLContent = [xml]($XMLPackage)

    #Get total number of Deployment Types for the Application
    $TotalDeploymentTypes = ($XMLContent.AppMgmtDigest.Application.DeploymentTypes.DeploymentType | Measure-Object | Select-Object -ExpandProperty Count)
    
    If (!($Null -eq $TotalDeploymentTypes) -or (!($TotalDeploymentTypes -eq 0))) {
        $ApplicationObject = New-Object PSCustomObject
        #Application Details
        $ApplicationObject | Add-Member NoteProperty -Name Application_LogicalName -Value $XMLContent.AppMgmtDigest.Application.LogicalName
        $ApplicationObject | Add-Member NoteProperty -Name Application_Name -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Title
        $ApplicationObject | Add-Member NoteProperty -Name Application_Description -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Description
        $ApplicationObject | Add-Member NoteProperty -Name Application_Publisher -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Publisher
        $ApplicationObject | Add-Member NoteProperty -Name Application_Version -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Version
        $ApplicationObject | Add-Member NoteProperty -Name Application_IconId -Value $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id
        $ApplicationObject | Add-Member NoteProperty -Name Application_TotalDeploymentTypes -Value $TotalDeploymentTypes
            
        #If we have the logo, add the path
        If (!($Null -eq $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id)) {
            Try {
                If (Test-Path -Path (Join-Path -Path $WorkingFolder_Logos -ChildPath (Join-Path -Path $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id -ChildPath "Logo.jpg"))) {
                    $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value (Join-Path -Path $WorkingFolder_Logos -ChildPath (Join-Path -Path $XMLContent.AppMgmtDigest.Application.DisplayInfo.Info.Icon.Id -ChildPath "Logo.jpg"))
                }
                else {
                    $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null
                }
            }
            Catch {
                $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null
            }
        }
        else {
            $ApplicationObject | Add-Member NoteProperty -Name Application_IconPath -Value $Null  
        }
            
        $ApplicationTypes += $ApplicationObject

        $Object = $XMLContent.AppMgmtDigest.DeploymentType

        $($Object.Installer.DetectAction.Args.Arg | Select-Object -ExpandProperty '#text')
        ($Object.Installer.CustomData | Select-Object -Property *).ChildNodes
        $Object.Installer.CustomData.DetectionMethod | Select-Object -Property *
        
        $EnhDet = [xml]$($Object.Installer.CustomData.EnhancedDetectionMethod | Select-Object -ExpandProperty OuterXML)
        $DTDetectionElements = Get-DetectionMethodElements $EnhDet.EnhancedDetectionMethod.Settings

        $EnhDet.EnhancedDetectionMethod.Rule.Expression.Operator
        $EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression.Operands.SettingReference
        $EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression.Operands.ConstantValue
        


        foreach ( $DetExpression in $EnhDet.EnhancedDetectionMethod.Rule.Expression ) {
            $DetExpressions = $EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands[0]
            $($EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression)[3].Operands.Expression[0].Operands.SettingReference
            $($EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression)[3].Operands.Expression[0].Operands.ConstantValue
            $($EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression)[0].Operands.SettingReference
            $($EnhDet.EnhancedDetectionMethod.Rule.Expression.Operands.Expression)[0].Operands.ConstantValue
        
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

Set-Location $StartLocation