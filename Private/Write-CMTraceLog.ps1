<#
.Synopsis
Created on:   08/07/2021
Created by:   Norbert Bauer
Filename:     Write-CMTraceLog.ps1

.Description
Function to write to a log file in CMTrace-Format

.Parameter Component (optional)
Pass a string that is used as Component Name in Logfile
If not passed it will use the name of the calling PS1 script

.Parameter LogText (mandatory)
Text that is written to Logfile as detail descritpion of the log entry

.Parameter LogSeverity (mandatory)
String with the Severity of the Entry that can be
Information or 1
Warning or 2
Error or 3

.Parameter LogFile (optional)
If it is a Full Path and Filename, the Logfile will be created or used to add the new entry
If this only a Filename, the file will be created in the Folder of the calling Script
If Empty, the Log will be created in the Folder of the calling script and named like the script with ".log" as extension


.Example
Write-CMTraceLog -LogText "1: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity Information

.Example
Write-CMTraceLog -LogText "2: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity Warning

.Example
Write-CMTraceLog -LogText "3: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity Error

.Example
Write-CMTraceLog -LogText "1: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity 1

.Example
Write-CMTraceLog -LogText "2: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity 2

.Example
Write-CMTraceLog -LogText "3: My Test Entry" -LogFile "C:\Temp\Logs\MyScript.Log" -Component "Application Uninstall" -LogSeverity 3

.Example
Write-CMTraceLog -LogText "My Test Entry" -LogSeverity Information


#>
Function Write-CMTraceLog {
    param (
        [String]$Component = $MyInvocation.PSCommandPath,
        [Parameter(Mandatory=$true)]
        [String]$LogText,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Information", "Warning", "Error","1","2","3")]
        [String]$LogSeverity,
        [String]$LogFile,
        [Switch]$ResetLogFile
    )

###    Check and Create path to LogFile
    $CallingScript = $MyInvocation.PSCommandPath
    If ( ! $LogFile ) {
        $LogFile = $($CallingScript.Substring(0,$CallingScript.LastIndexOf('.'))) + ".log"
    }

    $LogFolder = Split-Path $LogFile
    If ( ! $LogFolder ) {
        $LogFolder = Split-Path $CallingScript
        $LogFile = Join-Path -Path $LogFolder -ChildPath $LogFile
    }
    If (!$(Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory
    }

    $ProcessID = $PID
    If ( ! $Component ) {
        $Component = $MyInvocation.MyCommand.Name
        $CurrentFile = $Component 
    }
    Else {
        $CallingFile = Get-Item $Component -ErrorAction SilentlyContinue
        If ( $CallingFile ) {
            $Component = $CallingFile.Name
            $CurrentFile = $CallingFile.BaseName
        }
        Else {
            $FileProperty = Get-Item $($MyInvocation.PSCommandPath) -ErrorAction SilentlyContinue
            If (! $FileProperty ){
                $CurrentFile = $MyInvocation.MyCommand.Name
            }
            Else {
                $CurrentFile = $FileProperty.Name
            }
            
        }
    }

    Switch ($LogSeverity) {
        "Information" {$Type = "1"}
        "Warning" {$Type = "2"}
        "Error" {$Type = "3"}
        "1" {$Type = "1"}
        "2" {$Type = "2"}
        "3" {$Type = "3"}
    }
    

    $Date = Get-Date -Format "MM-dd-yyyy"
    $Time = $(Get-Date -Format "HH:mm:ss.fff") + $((Get-WmiObject -Query "Select Bias from Win32_TimeZone").bias)
    $LogOutput = "<![LOG[$($LogText)]LOG]!><time=`"$($Time)`" date=`"$($Date)`" component=`"$($Component)`" context=`"$($Context)`" type=`"$($Type)`" thread=`"$($ProcessID)`" file=`"$($CurrentFile)`">"

    If ( $ResetLogFile ) {
        $ExistingLog = Get-Item -Path $LogFile
        If ( $ExistingLog ) {
            $ArchiveLog = ($ExistingLog.Name).Replace($ExistingLog.Extension, '-' + $(Get-Date -Format "yyyyMMdd-HHmmss") + $($ExistingLog.Extension))
            $ExistingLog | Rename-Item -NewName $ArchiveLog
        }
    }
    Out-File -InputObject $LogOutput -Append -NoClobber -Encoding utf8 -FilePath "$LogFile"
}