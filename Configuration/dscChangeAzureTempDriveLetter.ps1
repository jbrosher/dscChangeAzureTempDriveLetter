configuration dscChangeAzureTempDriveLetter
{

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $True
        }      

        Script removePageFileConfiguration {
            GetScript  = {  @{ Result = "" } }
            TestScript = { 
                $pageFile = Get-WmiObject -Class Win32_PageFileSetting
                if ($pageFile -eq $null) { return $true }
                if ($pageFile.Name.ToLower().Contains('d:')) { return $false }
                else { return $true }
            }
            SetScript  = {
                $pageFile = Get-WmiObject -Class Win32_PageFileSetting
                $pageFile
                $pageFile.Delete()
                Restart-Computer -Force
            }
        }

        Script setTempDrive {
            GetScript  = { @{ Result = "" } }
            TestScript = {
                $pageFile = Get-WmiObject -Class Win32_PageFileSetting
                if ($pageFile -eq $null) { return $false }
                else { return $true }

            } 
            SetScript = {
                Get-Partition -DriveLetter "D"| Set-Partition -NewDriveLetter "T"
                Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{ Name = "T:\pagefile.sys"; MaximumSize = 0; }
                Restart-Computer -Force
            }
        }
    }
}
