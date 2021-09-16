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