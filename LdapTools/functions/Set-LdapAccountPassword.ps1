function Set-LdapAccountPassword {
<#
	.SYNOPSIS
		Sets the password of an active directory account.
	
	.DESCRIPTION
		Sets the password of an active directory account.
	
	.PARAMETER Identity
		Identifier specifying the account to set the password for.
		Must be either SID, ObjectGuid, SamAccountName or DistinguishedName.
	
	.PARAMETER Password
		The Password to apply to the account specified
	
	.PARAMETER Server
		The server to contact for this query.
	
	.PARAMETER Credential
		The credentials to use for authenticating this query.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Set-LdapAccountPassword -Identity 'peter' -Password (Read-Host -AsSecureString)
	
		Sets the password of peter.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Identity,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[securestring]
		$Password,
		
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
			
			Invoke-PSFProtectedCommand -ActionString 'Set-LdapAccountPassword.Resetting' -ActionStringValues $adAccount.Properties.samaccountname[0] -Target $adAccount.Properties.samaccountname[0] -ScriptBlock {
				$accountEntry = $adAccount.GetDirectoryEntry()
				$cred = [PSCredential]::new("whatever", $Password)
				$accountEntry.SetPassword($cred.GetNetworkCredential().Password)
				$accountEntry.SetInfo()
			} -PSCmdlet $PSCmdlet -EnableException $true -Continue
		}
	}
}