<#
.Synopsis
Created on:   21/03/2021
Created by:   Ben Whitmore
Filename:     New-IntuneWin.ps1

Changed on:   03/08/2021
Changed by:   Norbert Bauer
Changes:      Changed Logging function to "Write-CMTraceLog"

.Description
Function to create a .intunewin file
#>

Function New-IntuneWin {
    Param (
        [String]$ContentFolder,
        [String]$OutputFolder,
        [String]$SetupFile
    )

    Write-CMTraceLog -LogText "Function: New-IntuneWin was called" -LogSeverity "Information" -LogFile $MainLogFile 

    #Search the Install Command line for other the installer type
    If ($SetupFile -match "powershell" -and $SetupFile -match "\.ps1") {
        Write-CMTraceLog -LogText "Powershell script detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Powershell script detected" -ForegroundColor Yellow
        Write-Host ''
        $Right = ($SetupFile -split ".ps1")[0]
        $Right = ($Right -Split " ")[-1]
        $Filename = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + ".ps1"
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }
    elseif ($SetupFile -match "\.exe" -and $SetupFile -notmatch "msiexec" -and $SetupFile -notmatch "cscript" -and $SetupFile -notmatch "wscript") {
        $Installer = ".exe"
        Write-CMTraceLog -LogText "$($Installer) installer detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "$Installer installer detected"
        $Right = ($SetupFile -split "\.exe")[0]
        $Right = ($Right -Split " ")[-1]
        $FileName = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + $Installer
        $Command -replace '"', ''
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }
    elseif ($SetupFile -match "\.msi") {
        $Installer = ".msi"
        Write-CMTraceLog -LogText "$($Installer) installer detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "$Installer installer detected"
        $Right = ($SetupFile -split "\.msi")[0]
        $Right = ($Right -Split " ")[-1]
        $FileName = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + $Installer
        $Command -replace '"', ''
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }
    elseif ($SetupFile -match "\.vbs") {
        $Installer = ".vbs"
        Write-CMTraceLog -LogText "$($Installer) script detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "$Installer installer detected"
        $Right = ($SetupFile -split "\.vbs")[0]
        $Right = ($Right -Split " ")[-1]
        $FileName = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + $Installer
        $Command -replace '"', ''
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }
    elseif ($SetupFile -match "\.cmd") {
        $Installer = ".cmd"
        Write-CMTraceLog -LogText "$($Installer) installer detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "$Installer installer detected"
        $Right = ($SetupFile -split "\.cmd")[0]
        $Right = ($Right -Split " ")[-1]
        $FileName = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + $Installer
        $Command -replace '"', ''
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }
    elseif ($SetupFile -match "\.bat") {
        $Installer = ".bat"
        Write-CMTraceLog -LogText "$($Installer) installer detected" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "$Installer installer detected"
        $Right = ($SetupFile -split "\.bat")[0]
        $Right = ($Right -Split " ")[-1]
        $FileName = $Right.TrimStart("\", ".", "`"")
        $Command = $Filename + $Installer
        $Command -replace '"', ''
        Write-CMTraceLog -LogText "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Extracting the SetupFile Name for the Microsoft Win32 Content Prep Tool from the Install Command..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText "$($Command)" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host $Command -ForegroundColor Green
    }

    Write-Host ''

    Try {
        #Check IntuneWinAppUtil.exe
        Write-CMTraceLog -LogText "Re-checking presence of Win32 Content Prep Tool..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Re-checking presence of Win32 Content Prep Tool..." -ForegroundColor Cyan
        If (Test-Path (Join-Path -Path $WorkingFolder_ContentPrepTool -ChildPath "IntuneWinAppUtil.exe")) {
            Write-CMTraceLog -LogText "Information: IntuneWinAppUtil.exe already exists at ""$($WorkingFolder_ContentPrepTool)"". Skipping download" -LogSeverity "Information" -LogFile $MainLogFile 
            Write-Host "Information: IntuneWinAppUtil.exe already exists at ""$($WorkingFolder_ContentPrepTool)"". Skipping download" -ForegroundColor Magenta
        }
        else {
            Write-CMTraceLog -LogText "Downloading Win32 Content Prep Tool..." -LogSeverity "Information" -LogFile $MainLogFile 
            Write-Host "Downloading Win32 Content Prep Tool..." -ForegroundColor Cyan
            Write-CMTraceLog -LogText "Get-FileFromInternet -URI ""https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"" -Destination $($WorkingFolder_ContentPrepTool)" -LogSeverity "Information" -LogFile $MainLogFile 
            Get-FileFromInternet -URI "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe" -Destination $WorkingFolder_ContentPrepTool
        }
        Write-Host ''
        Write-CMTraceLog -LogText "Building IntuneWinAppUtil.exe execution string..." -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host "Building IntuneWinAppUtil.exe execution string..." -ForegroundColor Cyan
        Write-CMTraceLog -LogText """$($WorkingFolder_ContentPrepTool)\IntuneWinAppUtil.exe"" -s ""$($Command)"" -c ""$($ContentFolder)"" -o ""$($OutputFolder)""" -LogSeverity "Information" -LogFile $MainLogFile 
        Write-Host """$($WorkingFolder_ContentPrepTool)\IntuneWinAppUtil.exe"" -s ""$($Command)"" -c ""$($ContentFolder)"" -o ""$($OutputFolder)""" -ForegroundColor Green

        #Try running the content prep tool to build the intunewin
        Try {
            $Arguments = @(
                "-s"
                $Command
                "-c"
                $ContentFolder
                "-o"
                $OutputFolder
                "-q"
            )
            Write-CMTraceLog -LogText "Start-Process -FilePath (Join-Path -Path $($WorkingFolder_ContentPrepTool) -ChildPath ""IntuneWinAppUtil.exe"") -ArgumentList $($Arguments) -Wait" -LogSeverity "Information" -LogFile $MainLogFile 
            Start-Process -FilePath (Join-Path -Path $WorkingFolder_ContentPrepTool -ChildPath "IntuneWinAppUtil.exe") -ArgumentList $Arguments -Wait 
            Write-Host ''
                 
            If (Test-Path (Join-Path -Path $OutputFolder -ChildPath "*.intunewin") ) {
                Write-CMTraceLog -LogText "Successfully created ""$($Filename).intunewin"" at ""$($OutputFolder)""" -LogSeverity "Information" -LogFile $MainLogFile 
                Write-Host "Successfully created ""$($Filename).intunewin"" at ""$($OutputFolder)""" -ForegroundColor Cyan
            }
            else {
                Write-CMTraceLog -LogText "Error: We couldn't verify that ""$($Filename).intunewin"" was created at ""$($OutputFolder)""" -LogSeverity "Error" -LogFile $MainLogFile 
                Write-Host "Error: We couldn't verify that ""$($Filename).intunewin"" was created at ""$($OutputFolder)""" -ForegroundColor Red
            }
        }
        Catch {
            Write-CMTraceLog -LogText "Error creating the .intunewin file" -LogSeverity "Error" -LogFile $MainLogFile
            Write-Host "Error creating the .intunewin file" -ForegroundColor Red
            Write-CMTraceLog -LogText "$($_)" -LogSeverity "Error" -LogFile $MainLogFile
            Write-Host $_ -ForegroundColor Red
        }
    }
    Catch {
        Write-CMTraceLog -LogText "The script encounted an error getting the Win32 Content Prep Tool" -LogSeverity "Error" -LogFile $MainLogFile
        Write-Host "The script encounted an error getting the Win32 Content Prep Tool" -ForegroundColor Red
    }
}