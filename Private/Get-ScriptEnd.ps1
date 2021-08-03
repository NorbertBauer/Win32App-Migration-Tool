<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     Get-ScriptEnd.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to exit script
#>
Function Get-ScriptEnd {

    Set-Location $ScriptRoot
    Write-Host ''
    Write-CMTraceLog -LogText "## The Win32AppMigrationTool Script has Finished ##" -LogSeverity "Information" -LogFile $MainLogFile 
    Write-Host '## The Win32AppMigrationTool Script has Finished ##'
}