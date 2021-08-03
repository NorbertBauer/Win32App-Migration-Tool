<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Connect-SiteServer.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to conect to a Site Server
#>
Function Connect-SiteServer {
    Param (
        [String]$SiteCode,
        [String]$ProviderMachineName
    )

    Write-CMTraceLog -LogText "Function: Connect-SiteServer was called" -LogSeverity "Information" -LogFile $MainLogFile 
    Write-CMTraceLog -LogText "Import-Module $($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -LogSeverity "Information" -LogFile $MainLogFile
    Write-Host "Importing Module: ConfigurationManager.psd1 and connecting to Provider $($ProviderMachineName)..." -ForegroundColor Cyan
            
    # Import the ConfigurationManager.psd1 module 
    Try {
        If ($Null -eq (Get-Module ConfigurationManager)) {
            Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -Verbose:$False
        }
    }
    Catch {
        Write-CMTraceLog -LogText "Error: Could not import the ConfigurationManager.psd1 Module" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host 'Warning: Could not import the ConfigurationManager.psd1 Module' -ForegroundColor Red
        break
    }

    # Check Provider is valid
    if (!($ProviderMachineName -eq (Get-PSDrive -ErrorAction SilentlyContinue | Where-Object { $_.Provider -like "*CMSite*" }).Root)) {
        Write-CMTraceLog -LogText "Could not connect to the Provider $($ProviderMachineName). Did you specify the correct Site Server?" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "Could not connect to the Provider $($ProviderMachineName). Did you specify the correct Site Server?" -ForegroundColor Red
        Get-ScriptEnd
        break
    }
    else {
        Write-CMTraceLog -LogText "Connected to provider $($ProviderMachineName) at site $($SiteCode)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Connected to provider ""$($ProviderMachineName)""" -ForegroundColor Green
    }

    # Connect to the site's drive if it is not already present
    Try {
        if (!($SiteCode -eq (Get-PSDrive -ErrorAction SilentlyContinue | Where-Object { $_.Provider -like "*CMSite*" }).Name)) {
            Write-CMTraceLog -LogText "No PSDrive found for $($SiteCode) in PSProvider CMSite for Root $($ProviderMachineName)" -LogSeverity "Error" -LogFile $MainLogFile
            Write-Host "No PSDrive found for $($SiteCode) in PSProvider CMSite for Root $($ProviderMachineName). Did you specify the correct Site Code?" -ForegroundColor Red
            Get-ScriptEnd
            break
        }
        else {
            Write-CMTraceLog -LogText "Connected to PSDrive $($SiteCode)" -LogSeverity "Information" -LogFile $MainLogFile 
            Write-Host "Connected to PSDrive $($SiteCode)" -ForegroundColor Green
            Set-Location "$($SiteCode):\"
        }
    }
    Catch {
        Write-CMTraceLog -LogText "Error: Could not connect to the specified provider $($ProviderMachineName) at site $($SiteCode)" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "Warning: Could not connect to the specified provider ""$($ProviderMachineName)"" at site ""$($SiteCode)""" -ForegroundColor Red
        break
    }
    
}