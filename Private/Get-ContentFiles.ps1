<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Get-ContentFiles.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to get content
#>
Function Get-ContentFiles {
    Param (
        [String]$Source,
        [String]$Destination
    )

    Write-CMTraceLog -LogText "Function: Get-ContentFiles was called" -LogSeverity "Information" -LogFile $MainLogFile 
    Write-CMTraceLog -LogText "Padding $($Source) in case content path has spaces. Robocopy demand space at end of Source String" -LogSeverity "Information" -LogFile $MainLogFile 
    $SourcePadded = "`"" + $Source + " `""
    Write-CMTraceLog -LogText "Padding $($Destination) in case content path has spaces. Robocopy demand space at end of Destination String" -LogSeverity "Information" -LogFile $MainLogFile 
    $DestinationPadded = "`"" + $Destination + " `""

    Try {
        Write-CMTraceLog -LogText "`$Log = Join-Path -Path $($WorkingFolder_Logs) -ChildPath ""Main.Log""" -LogSeverity "Information" -LogFile $MainLogFile 
        $Log = Join-Path -Path $WorkingFolder_Logs -ChildPath "Main.Log"
        Write-CMTraceLog -LogText "Robocopy.exe $($SourcePadded) $($DestinationPadded) /MIR /E /Z /R:5 /W:1 /NDL /NJH /NJS /NC /NS /NP /V /TEE  /UNILOG+:$($Log)" -LogSeverity "Information" -LogFile $MainLogFile 
        $Robo = Robocopy.exe $SourcePadded $DestinationPadded /MIR /E /Z /R:5 /W:1 /NDL /NJH /NJS /NC /NS /NP /V /TEE /UNILOG+:$Log
        $Robo

        If ((Get-ChildItem -Path $Destination | Measure-Object).Count -eq 0 ) {
            Write-CMTraceLog -LogText "Error: Could not transfer content from ""$($Source)"" to ""$($Destination)""" -LogSeverity "Error" -LogFile $MainLogFile 
            Write-Host "Error: Could not transfer content from ""$($Source)"" to ""$($Destination)""" -ForegroundColor Red
        }
    }
    Catch {
        Write-CMTraceLog -LogText "Error: Could not transfer content from ""$($Source)"" to ""$($Destination)""" -LogSeverity "Error" -LogFile $MainLogFile 
        Write-Host "Error: Could not transfer content from ""$($Source)"" to ""$($Destination)""" -ForegroundColor Red
    }
}