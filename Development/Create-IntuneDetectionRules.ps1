Function Get-DetectionMethodElements
{
<# 

FILE: 
    Is64Bit         : true
    LogicalName     : File_a95e61fa-363e-4600-afaf-10339909adb5
    Annotation      : Annotation
    Path            : %Windir%\CCM
    Filter          : CMTrace.exe
    Name            : File

FOLDER:
    Is64Bit         : true
    LogicalName     : Folder_2cff287a-30d5-403f-9e4b-95bda2ad69f0
    Annotation      : Annotation
    Path            : C:\install
    Filter          : Cert
    Name            : Folder

REGISTRY:
    LogicalName             : RegSetting_96915972-65d6-42fd-a97e-dbc8e746b05e
    DataType                : Version
    Annotation              : Annotation
    RegistryDiscoverySource : RegistryDiscoverySource
    Name                    : SimpleSetting
        Hive              : HKEY_LOCAL_MACHINE
        Depth             : Base
        Is64Bit           : true
        CreateMissingPath : true
        Key               : SOFTWARE\Dell\CommandIntelvProOutOfBand
        ValueName         : ProductVersion
        Name              : RegistryDiscoverySource

MSI:
    LogicalName     : MSI_5822a60b-68e0-434a-a52f-a07b2f1fb4f1
    IsPerUser       : false
    Annotation      : Annotation
    ProductCode     : {010C06FC-749F-41C3-9D7D-28C17D673A7A}
    Name            : MSI

#>

param ( $EnhancedDetectionSettings )

$ElementTypes = 'File','Folder','SimpleSetting','MSI'
$ReturnElements = @()

    foreach ( $ElementType in $ElementTypes ) {
        $EnhancedDetectionElements = $EnhancedDetectionSettings.$ElementType
        foreach ( $EnhancedDetectionElement in $EnhancedDetectionElements ) {
            Switch ( $EnhancedDetectionElement.Name ) {
                'File' { $ReturnElement = [PSCustomObject]$(@{
                            LogicalName = $EnhancedDetectionElement.LogicalName
                            Type = 'File'
                            Path = $EnhancedDetectionElement.Path
                            Name = $EnhancedDetectionElement.Filter
                            DataType = $null
                            Is64Bit = If ( $EnhancedDetectionElement.Is64Bit -eq 'true' ) { $true } Else { $false }
                            IsPerUser = $null
                            })
                }
                'Folder' { $ReturnElement = [PSCustomObject]$(@{
                            LogicalName = $EnhancedDetectionElement.LogicalName
                            Type = 'Folder'
                            Path = $EnhancedDetectionElement.Path
                            Name = $EnhancedDetectionElement.Filter
                            DataType = $null
                            Is64Bit = If ( $EnhancedDetectionElement.Is64Bit -eq 'true' ) { $true } Else { $false }
                            IsPerUser = $null
                            })
                }
                'SimpleSetting' { $ReturnElement = [PSCustomObject]$(@{
                            LogicalName = $EnhancedDetectionElement.LogicalName
                            Type = 'Registry'
                            Path = $EnhancedDetectionElement.RegistryDiscoverySource.Hive + '\' + $EnhancedDetectionElement.RegistryDiscoverySource.Key
                            Name = $EnhancedDetectionElement.RegistryDiscoverySource.ValueName
                            DataType = $EnhancedDetectionElement.DataType
                            Is64Bit = If ( $EnhancedDetectionElement.RegistryDiscoverySource.Is64Bit -eq 'true' ) { $true } Else { $false }
                            IsPerUser = $null
                            })
                }
                'MSI' { $ReturnElement = [PSCustomObject]$(@{
                            LogicalName = $EnhancedDetectionElement.LogicalName
                            Type = 'MSI'
                            Path = $null
                            Name = $EnhancedDetectionElement.ProductCode
                            DataType = $null
                            Is64Bit = $null
                            IsPerUser = If ( $EnhancedDetectionElement.IsPerUser -eq 'true' ) { $true } Else { $false }
                            })
                }
            }
            $ReturnElements += $ReturnElement
        }
    }
Return $ReturnElements
}

Function ConvertTo-IntuneOperator
{
param ( $ExpressionOperator )

    #Write-Host "ExpressionOperator = $ExpressionOperator" -ForegroundColor Magenta
    [String]$IntuneOperator = $null
    Switch ( $ExpressionOperator ) {
        "NotEquals" { $IntuneOperator = "notEqual" }
        "LessEquals" { $IntuneOperator = "lessThanOrEqual" }
        "LessThan" { $IntuneOperator = "lessThan" }
        "GreaterEquals" { $IntuneOperator = "greaterThanOrEqual" }
        "GreaterThan" { $IntuneOperator = "greaterThan" }
        "Equals" { $IntuneOperator = "equal" }
    }
    Return $IntuneOperator
}

<# Function Get-EnhancedDetectionRule
{
param ( $DetectionRules,
        $DetectionElements,
        $DetectionRuleFolder )
#>

# Start of Development Code #######################################################################################################################
Import-Module -Name "IntuneWin32App"

# Site configuration
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
Set-Location "$($SiteCode):\" @initParams

# Set the current location to be the site code.
#[String[]]$ApplicationName = "7-Zip 19.00 (x64)"
#[String[]]$ApplicationName = "Check Point Endpoint Security 84.30 (Initial Client)"
#[String[]]$ApplicationName = "Test MEM Export"
#[String[]]$ApplicationName = "iTunes 12.11.0.26 RZ203231260"
[String[]]$ApplicationName = "Test MEM Export (EnhDetection)"

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
    
$Object = $XMLContent.AppMgmtDigest.DeploymentType
$EnhDetMethod = $([xml]$($Object.Installer.CustomData.EnhancedDetectionMethod | Select-Object -ExpandProperty OuterXML)).EnhancedDetectionMethod
#$DTDetectionElements = Get-DetectionMethodElements $EnhDet.EnhancedDetectionMethod.Settings

$EnhancedDetectionMethod = $EnhDetMethod


$DetectionRules = $EnhancedDetectionMethod.Rule.Expression
$DetectionElements = $EnhancedDetectionMethod.Settings

# End of Development Code #######################################################################################################################


# Code for Function #######################################################################################################################

    $DetectionOperator = $DetectionRules.Operator
    $DetectionExpressions = @()
    If ( $DetectionRules.Operands.Expression ) {
        $DetectionExpressions = $DetectionRules.Operands.Expression
    }
    Else {
        $DetectionExpressions += $DetectionRules
    }

    If ( $DetectionRuleFolder -eq $null -or $DetectionRuleFolder -eq "" ) {
        $DetectionRuleFolder = Join-Path $env:ProgramData "IntuneAppMigration"
    }
    If ( -not $(Test-Path $DetectionRuleFolder -ErrorAction SilentlyContinue) ) {
        New-Item -Path $(Split-Path $DetectionRuleFolder -Parent) -Name $(Split-Path $DetectionRuleFolder -Leaf) -ItemType Directory -Force
    }
    $ExportDetectionFile = $DetectionRuleFolder + "\Detection_Enh.json"
    If ( $(Test-Path -Path $ExportDetectionFile -ErrorAction SilentlyContinue) ) {
        Remove-Item -Path $ExportDetectionFile -Force -ErrorAction SilentlyContinue
    }


    $DetectionRules = New-Object -TypeName "System.Collections.ArrayList"
    foreach ( $DetectionExpression in $DetectionExpressions ) {
        $DetectionRuleArgs = $null
        $DetectionElement = $null
        $DetectionRule = $null
        
        switch ($DetectionExpression.Operands.SettingReference.SettingSourceType) {
            "MSI" {
                $DetectionElement = $DetectionElements.$($DetectionExpression.Operands.SettingReference.SettingSourceType) | Where { $_.LogicalName -eq $DetectionExpression.Operands.SettingReference.SettingLogicalName }
                $DetectionRuleArgs = @{
                    "ProductCode" = $DetectionElement.ProductCode
                }
                if (-not([string]::IsNullOrEmpty($DetectionRuleItem.ProductVersion))) {
                    $DetectionRuleArgs.Add("ProductVersion", [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType))
                    $DetectionRuleArgs.Add("ProductVersionOperator", $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator))
                }
                Else {
                    $DetectionRuleArgs.Add("ProductVersionOperator", "notConfigured")
                }
            # Create MSIDetectionRule
            # $DetectionRuleArgs | FT
            $DetectionRule = New-IntuneWin32AppDetectionRuleMSI @DetectionRuleArgs
            }
            "Registry" {
                $DetectionElement = $($DetectionElements.SimpleSetting | Where { $_.LogicalName -eq $DetectionExpression.Operands.SettingReference.SettingLogicalName }).RegistryDiscoverySource
                Switch ($DetectionExpression.Operands.SettingReference.DataType) {
                    "Int64" {
                        $DetectionRuleArgs = [ordered]@{
                            "IntegerComparison" = $true
                            "KeyPath" = $DetectionElement.Hive + '\' + $DetectionElement.Key
                            "IntegerComparisonOperator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "IntegerComparisonValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                        if (-not([string]::IsNullOrEmpty($DetectionElement.ValueName))) {
                            $DetectionRuleArgs.Add("ValueName", $DetectionElement.ValueName)
                        }
                    }
                    "Version" {
                        $DetectionRuleArgs = [ordered]@{
                            "VersionComparison" = $true
                            "KeyPath" = $DetectionElement.Hive + '\' + $DetectionElement.Key
                            "VersionComparisonOperator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "VersionComparisonValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                        if (-not([string]::IsNullOrEmpty($DetectionElement.ValueName))) {
                            $DetectionRuleArgs.Add("ValueName", $DetectionElement.ValueName)
                        }
                    }
                    "String" {
                        $DetectionRuleArgs = [ordered]@{
                            "StringComparison" = $true
                            "KeyPath" = $DetectionElement.Hive + '\' + $DetectionElement.Key
                            "StringComparisonOperator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "StringComparisonValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                        if (-not([string]::IsNullOrEmpty($DetectionElement.ValueName))) {
                            $DetectionRuleArgs.Add("ValueName", $DetectionElement.ValueName)
                        }
                    }
                    #Existence
                    "Boolean" {
                        $DetectionRuleArgs = [ordered]@{
                            "Existence" = $true
                            "KeyPath" = $DetectionElement.Hive + '\' + $DetectionElement.Key
                            "DetectionType" = "exists"
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                        if (-not([string]::IsNullOrEmpty($DetectionElement.ValueName))) {
                            $DetectionRuleArgs.Add("ValueName", $DetectionElement.ValueName)
                        }
                    }
                }
            # Create RegistryDetectionRule
            # $DetectionRuleArgs | FT
            $DetectionRule = New-IntuneWin32AppDetectionRuleRegistry @DetectionRuleArgs
            }
            ({$PSItem -eq "File" -or $PSItem -eq "Folder"}) {
                $DetectionElement = $DetectionElements.$($DetectionExpression.Operands.SettingReference.SettingSourceType) | Where { $_.LogicalName -eq $DetectionExpression.Operands.SettingReference.SettingLogicalName }
                Switch ($DetectionExpression.Operands.SettingReference.PropertyPath) {
                    "DateCreated" {
                        $DetectionRuleArgs = [ordered]@{
                            "DateCreated" = $true
                            "Path" = $DetectionElement.Path
                            "FileOrFolder" = $DetectionElement.Filter
                            "Operator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "DateTimeValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                    }
                    "DateModified" {
                        $DetectionRuleArgs = [ordered]@{
                            "DateModified" = $true
                            "Path" = $DetectionElement.Path
                            "FileOrFolder" = $DetectionElement.Filter
                            "Operator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "DateTimeValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                    }
                    "Version" {
                        $DetectionRuleArgs = [ordered]@{
                            "Version" = $true
                            "Path" = $DetectionElement.Path
                            "FileOrFolder" = $DetectionElement.Filter
                            "Operator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            "VersionValue" = [System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType)
                            "Check32BitOn64System" = $(-not [System.Convert]::ToBoolean($DetectionElement.Is64Bit))
                        }
                    }
                    "Size" {
                        $DetectionRuleArgs = [ordered]@{
                            "Size" = $true
                            "Path" = $DetectionElement.Path
                            "FileOrFolder" = $DetectionElement.Filter
                            "Operator" = $(ConvertTo-IntuneOperator -ExpressionOperator $DetectionExpression.Operator)
                            #"SizeInMBValue" = $([String]$(([System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType))/1MB)).Split(".")[0]
                            "SizeInMBValue" = $([String]$([math]::Round($(([System.Management.Automation.LanguagePrimitives]::ConvertTo($DetectionExpression.Operands.ConstantValue.Value, $DetectionExpression.Operands.ConstantValue.DataType))/1MB))))
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }
                    }
                    #Existence
                    $null {
                        $DetectionRuleArgs = [ordered]@{
                            "Existence" = $true
                            "Path" = $DetectionElement.Path
                            "FileOrFolder" = $DetectionElement.Filter
                            "DetectionType" = "exists"
                            "Check32BitOn64System" = -not [System.Convert]::ToBoolean($DetectionElement.Is64Bit)
                        }

                    }
                }
            # Create FileDetectionRule
            # $DetectionRuleArgs | FT
            $DetectionRule = New-IntuneWin32AppDetectionRuleFile @DetectionRuleArgs
            }
        }
        
        # Add detection rule to list
        If ( $DetectionRule -ne $null ) {
            $DetectionRules.Add($DetectionRule) | Out-Null
        }
    }
Return $DetectionRules
#}