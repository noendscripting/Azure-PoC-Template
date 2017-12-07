configuration ProvisionDcVm
{
   param
   (
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xDisk, xNetworking, cDisk
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        WindowsFeature DNS
            {
                Ensure = "Present"
                Name = "DNS"
            }
        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-Dns-Server"
            DependsOn = "[WindowsFeature]DNS"
        }
        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }
        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }
        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
	        DependsOn="[xWaitForDisk]Disk2"
        }
   }
}