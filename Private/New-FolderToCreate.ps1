<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     New-FolderToCreate.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to create a folder
#>
Function New-FolderToCreate {
    Param(
        [String]$Root,
        [String[]]$Folders
    )
    
    Write-CMTraceLog -LogText "Function: New-FolderToCreate was called" -LogSeverity "Information" -LogFile $MainLogFile 
    
    If (!($Root)) {
        Write-CMTraceLog -LogText "Error: No Root Folder passed to Function" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "Error: No Root Folder passed to Function" -ForegroundColor Red
    }
    If (!($Folders)) {
        Write-CMTraceLog -LogText "Error: No Folder(s) passed to Function" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "Error: No Folder(s) passed to Function" -ForegroundColor Red
    }

    ForEach ($Folder in $Folders) {
        #Create Folders
        Write-CMTraceLog -LogText "`$FolderToCreate = Join-Path -Path $($Root) -ChildPath $($Folder)" -LogSeverity "Information" -LogFile $MainLogFile
        $FolderToCreate = Join-Path -Path $Root -ChildPath $Folder
        If (!(Test-Path $FolderToCreate)) {
            Write-Host "Creating Folder ""$($FolderToCreate)""..." -ForegroundColor Cyan
            Try {
                New-Item -Path $FolderToCreate -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-CMTraceLog -LogText "Folder ""$($FolderToCreate)"" created succesfully" -LogSeverity "Information" -LogFile $MainLogFile
                Write-Host "Folder ""$($FolderToCreate)"" created succesfully"
            }
            Catch {
                Write-CMTraceLog -LogText "Warning: Couldn't create ""$($FolderToCreate)"" folder" -LogSeverity "Warning" -LogFile $MainLogFile
                Write-Host "Warning: Couldn't create ""$($FolderToCreate)"" folder" -ForegroundColor Red
            }
        }
        else {
            Write-CMTraceLog -LogText "Information: Folder ""$($FolderToCreate)"" already exsts. Skipping folder creation" -LogSeverity "Information" -LogFile $MainLogFile
            Write-Host "Information: Folder ""$($FolderToCreate)"" already exsts. Skipping folder creation" -ForegroundColor Magenta
        }
    }
} 