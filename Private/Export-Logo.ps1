<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Export-Logo.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to export logo from selected ConfigMgr Application
#>
Function Export-Logo {

    Param (
        [String]$IconId,
        [String]$AppName
    )

    Write-CMTraceLog -LogText "Function: Export-Logo was called" -LogSeverity "Information" -LogFile $MainLogFile 
    Write-Host "Preparing to export Application Logo for ""$($AppName)"""
    If ($IconId) {

        #Check destination folder exists for logo
        If (!(Test-Path $WorkingFolder_Logos)) {
            Try {
                Write-CMTraceLog -LogText "New-Item -Path $($WorkingFolder_Logos) -ItemType Directory -Force -ErrorAction Stop | Out-Null" -LogSeverity "Information" -LogFile $MainLogFile
                New-Item -Path $WorkingFolder_Logos -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            Catch {
                Write-CMTraceLog -LogText "Warning: Couldn't create ""$($WorkingFolder_Logos)"" folder for Application Logos" -LogSeverity "Warning" -LogFile $MainLogFile
                Write-Host "Warning: Couldn't create ""$($WorkingFolder_Logos)"" folder for Application Logos" -ForegroundColor Red
            }
        }

        #Continue if Logofolder exists
        If (Test-Path $WorkingFolder_Logos) {
            Write-CMTraceLog -LogText "`$LogoFolder_Id = (Join-Path -Path $($WorkingFolder_Logos) -ChildPath $($IconId))" -LogSeverity "Information" -LogFile $MainLogFile
            $LogoFolder_Id = (Join-Path -Path $WorkingFolder_Logos -ChildPath $IconId)
            Write-CMTraceLog -LogText "`$Logo_File = (Join-Path -Path $($LogoFolder_Id) -ChildPath Logo.jpg)" -LogSeverity "Information" -LogFile $MainLogFile
            $Logo_File = (Join-Path -Path $LogoFolder_Id -ChildPath Logo.jpg)

            #Continue if logo does not already exist in destination folder
            If (!(Test-Path $Logo_File)) {

                If (!(Test-Path $LogoFolder_Id)) {
                    Try {
                        Write-CMTraceLog -LogText "New-Item -Path $($LogoFolder_Id) -ItemType Directory -Force -ErrorAction Stop | Out-Null" -LogSeverity "Information" -LogFile $MainLogFile 
                        New-Item -Path $LogoFolder_Id -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    }
                    Catch {
                        Write-CMTraceLog -LogText "Warning: Couldn't create ""$($LogoFolder_Id)"" folder for Application Logo" -LogSeverity "Warning" -LogFile $MainLogFile 
                        Write-Host "Warning: Couldn't create ""$($LogoFolder_Id)"" folder for Application Logo" -ForegroundColor Red
                    }
                }

                #Continue if Logofolder\<IconId> exists
                If (Test-Path $LogoFolder_Id) {
                    Try {
                        #Grab the SDMPackgeXML which contains the Application and Deployment Type details
                        Write-CMTraceLog -LogText "`$XMLPackage = Get-CMApplication -Name ""$($AppName)"" | Where-Object { `$Null -ne `$_.SDMPackageXML } | Select-Object -ExpandProperty SDMPackageXML" -LogSeverity "Information" -LogFile $MainLogFile 
                        $XMLPackage = Get-CMApplication -Name $AppName | Where-Object { $Null -ne $_.SDMPackageXML } | Select-Object -ExpandProperty SDMPackageXML

                        #Deserialize SDMPackageXML
                        $XMLContent = [xml]($XMLPackage)

                        $Raw = $XMLContent.AppMgmtDigest.Resources.icon.Data
                        $Logo = [Convert]::FromBase64String($Raw)
                        [System.IO.File]::WriteAllBytes($Logo_File, $Logo)
                        If (Test-Path $Logo_File) {
                            Write-CMTraceLog -LogText "Success: Application logo for ""$($AppName)"" exported successfully to ""$($Logo_File)""" -LogSeverity "Information" -LogFile $MainLogFile 
                            Write-Host "Success: Application logo for ""$($AppName)"" exported successfully to ""$($Logo_File)""" -ForegroundColor Green
                        }
                    }
                    Catch {
                        Write-CMTraceLog -LogText "Warning: Could not export Logo to folder ""$($LogoFolder_Id)""" -LogSeverity "Warning" -LogFile $MainLogFile 
                        Write-Host "Warning: Could not export Logo to folder ""$($LogoFolder_Id)""" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-CMTraceLog -LogText "Information: Did not export Logo for ""$($AppName)"" to ""$($Logo_File)"" because the file already exists" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Information: Did not export Logo for ""$($AppName)"" to ""$($Logo_File)"" because the file already exists" -ForegroundColor Magenta
            }
        }
    }
    else {
        Write-CMTraceLog -LogText "Warning: Null or invalid IconId passed to function. Could not export Logo" -LogSeverity "Warning" -LogFile $MainLogFile 
        Write-Host "Warning: Null or invalid IconId passed to function. Could not export Logo" -ForegroundColor Red
    }
}