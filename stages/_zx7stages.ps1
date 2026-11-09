<#
   ========================================================================================================================
   Name         : _zx7levels.ps1
   Description  : compresses all the levels with zx7
   Created Date : 17.03.2023
   Created By   : MatoSimi
   Dependencies : 1) Windows PowerShell 5.1
                  2) zx7mini.exe

   Revision History
   Date       Release  Change By      Description
   17.3.2023  1.0      MatoSimi       Initial Release
   19.3.2023  1.1      MatoSimi       Fixes
	 26.11.2025 1.2      MatoSimi       Removed data+map (compress only DLI for cart)
   ========================================================================================================================
#>

for ($i = 0; $i -lt 10;$i++)
{
	$twodigit = "{0:d2}" -f $i
	$src = "tenstages0" + $twodigit + ".dat"
	$dst = "tenstages0" + $twodigit + ".dat.zx7"
	Write-Output $dst
	.\zx7mini.exe $src $dst
	
	$src = "tenstages1" + $twodigit + ".dat"
	$dst = "tenstages1" + $twodigit + ".dat.zx7"
	Write-Output $dst
	.\zx7mini.exe $src $dst
	
	$src = "tenstages2" + $twodigit + ".dat"
	$dst = "tenstages2" + $twodigit + ".dat.zx7"
	Write-Output $dst
	.\zx7mini.exe $src $dst

}

