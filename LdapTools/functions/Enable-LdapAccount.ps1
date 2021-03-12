function Enable-LdapAccount {
<#
	.SYNOPSIS
		Enable an active directory account.
	
	.DESCRIPTION
		Enable an active directory account.
	
	.PARAMETER Identity
		Identifier specifying the account to enable.
		Must be either SID, ObjectGuid, SamAccountName or DistinguishedName.
	
	.PARAMETER Server
		The server to contact for this query.
	
	.PARAMETER Credential
		The credentials to use for authenticating this query.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Enable-LdapAccount -Identity 'peter'
	
		Enables the account of peter.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Identity,
		
		[string]
		$Server,
		
		[pscredential]
		$Credential
	)
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	
	process {
		foreach ($identityString in $Identity) {
			$filter = Resolve-Identity -Name $identityString -GetFilterCondition -AllowSamAccountName
			if ($identityString -like "*,DC=*") {
				$adAccount = Get-LdapObject @parameters -LdapFilter "(samAccountName=*)" -SearchRoot $identityString -SearchScope Base -Raw -Property UserAccountControl, samAccountName
			}
			else {
				$adAccount = Get-LdapObject @parameters -LdapFilter $filter -Raw -Property UserAccountControl, samAccountName
			}
			
			if (($adAccount.Properties.useraccountcontrol[0] -band 2) -eq 0) {
				Write-PSFMessage -String 'Enable-LdapAccount.AlreadyEnabled' -StringValues $adAccount.Properties.samaccountname[0]
				continue
			}
			
			Invoke-PSFProtectedCommand -ActionString 'Enable-LdapAccount.Enabling' -ActionStringValues $adAccount.Properties.samaccountname[0] -Target $adAccount.Properties.samaccountname[0] -ScriptBlock {
				$accountEntry = $adAccount.GetDirectoryEntry()
				$accountEntry.userAccountControl.value = $accountEntry.userAccountControl.value - ($accountEntry.userAccountControl.value -band 2)
				$accountEntry.SetInfo()
			} -PSCmdlet $PSCmdlet -EnableException $true -Continue
		}
	}
}