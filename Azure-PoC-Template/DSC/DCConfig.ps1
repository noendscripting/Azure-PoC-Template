Configuration DcConfig
{
	Param
	(
		[string]$domainName = 'contosoad.com',
		[int]$dataDiskNumber=2,
		[string]$dataDiskDriveLetter,
		[System.Management.Automation.PSCredential]$DomainAdminCredentials
	)

	Import-DscResource -ModuleName xActiveDirectory, xStorage, xComputerManagement 

	[string]$netbiosDomainName = $domainName.Split(".")[0]
	[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${netbiosDomainName}\$($DomainAdminCredentials.UserName)", $DomainAdminCredentials.Password)
	
	Node localhost
	{     
	      
  		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		WindowsFeature DNS_RSAT
		{ 
			Ensure = "Present" 
			Name = "RSAT-DNS-Server"
		}

		WindowsFeature ADDS_Install 
		{ 
			Ensure = 'Present' 
			Name = 'AD-Domain-Services' 
		} 

		WindowsFeature RSAT_AD_AdminCenter 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-AdminCenter'
		}

		WindowsFeature RSAT_ADDS 
		{
			Ensure = 'Present'
			Name   = 'RSAT-ADDS'
		}

		WindowsFeature RSAT_AD_PowerShell 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-PowerShell'
		}

		WindowsFeature RSAT_AD_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-Tools'
		}

		WindowsFeature RSAT_Role_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-Role-Tools'
		}      

		xWaitForDisk Wait_Data_Disk
		{
			DiskNumber = $dataDiskNumber
			RetryCount = $Node.RetryCount
			RetryIntervalSec = $Node.RetryIntervalSec
			DependsOn = '[WindowsFeature]RSAT_Role_Tools'
		}

		xDisk Data_Disk
		{
			DiskNumber = $dataDiskNumber
			DriveLetter = $dataDiskDriveLetter
			AllocationUnitSize = 4096
			DependsOn = '[xWaitforDisk]Wait_Data_Disk'
		}

		xADDomain CreateForest 
		{ 
			DomainName = $domainName            
			DomainAdministratorCredential = [System.Management.Automation.PSCredential]$DomainCreds
			SafemodeAdministratorPassword = [System.Management.Automation.PSCredential]$DomainCreds
			DomainNetbiosName = $netbiosDomainName
			DatabasePath = $dataDiskDriveLetter + ":\NTDS"
			LogPath = $dataDiskDriveLetter + ":\NTDS"
			SysvolPath = $dataDiskDriveLetter + ":\SYSVOL"
			DependsOn = '[xDisk]Data_Disk', '[WindowsFeature]ADDS_Install'
		}
	}
}