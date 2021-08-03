
<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Get-FileFromInternet.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to download a file from the internet
#>
Function Get-FileFromInternet {
    Param (
        [String]$URI,
        [String]$Destination
    )

    Write-CMTraceLog -LogText "Function: Get-FileFromInternet was called" -LogSeverity "Information" -LogFile $MainLogFile 

    $File = $URI -replace '.*/'
    $FileDestination = Join-Path -Path $Destination -ChildPath $File
    Try {
        Invoke-WebRequest -UseBasicParsing -Uri $URI -OutFile $FileDestination -ErrorAction Stop
    }
    Catch {
        Write-Host "Warning: Error downloading the Win32 Content Prep Tool" -ForegroundColor Red
        Write-CMTraceLog -LogText "Error downloading the Win32 Content Prep Tool" -LogSeverity "Error" -LogFile $MainLogFile 
        $_
    }
}