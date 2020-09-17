function Get-LdapGroupMember
{
<#
	.SYNOPSIS
		Retrieve the members of a given group.
	
	.DESCRIPTION
		Retrieve the members of a given group.
	
	.PARAMETER Identity
		Identity of the group to get the members of.
		Accepts samaccountname, DN, Guid or SID.
	
	.PARAMETER MemberType
		Only return members of the specified type.
		Values: User, Group or Computer
	
	.PARAMETER Recurse
		Whether to resolve group memberships recursively.
	
	.PARAMETER Property
		Which properties to retrieve from the member objects.
	
	.PARAMETER Server
		The server to contact for this query.
	
	.PARAMETER Credential
		The credentials to use for authenticating this query.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-LdapGroupMember "administrators"
	
		Return all members of the administrators group.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
		[string[]]
		$Identity,
		
		[ValidateSet('Group','Computer','User')]
		[string[]]
		$MemberType,
		
		[switch]
		$Recurse,
		
		[Alias('Properties')]
		[string[]]
		$Property,
		
		[string]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		#region Prepare AD Operations and filters
		$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		
		$typeCondition = ''
		if ($MemberType)
		{
			$conditions = foreach ($type in $MemberType) { "(objectClass=$type)" }
			$typeCondition = '(|{0})' -f ($conditions -join "")
		}
		
		$recurseModifier = ''
		if ($Recurse) { $recurseModifier = ':1.2.840.113556.1.4.1941:' }
		
		$defaultProperties = 'SamAccountName', 'Name', 'DistinguishedName', 'ObjectClass'
		$actualProperties = @($defaultProperties) + @($Property)
		#endregion Prepare AD Operations and filters
	}
	process
	{
		foreach ($groupIdentifier in $Identity)
		{
			try { $condition = Resolve-Identity -Name $groupIdentifier -GetFilterCondition -AllowSamAccountName }
			catch { Stop-PSFFunction -String 'Get-LdapGroupMember.Identity.BadFormat' -StringValues $groupName -ErrorRecord $_ -EnableException $EnableException -Continue }
			
			try { $groupObject = Get-LdapGroup -LdapFilter "(&(objectClass=group)$condition)" @adParameters -EnableException }
			catch { Stop-PSFFunction -String 'Get-LdapGroupMember.Identity.GroupAccessFailure' -StringValues $groupName -ErrorRecord $_ -EnableException $EnableException -Continue }
			
			if (-not $groupObject) { Stop-PSFFunction -String 'Get-LdapGroupMember.Identity.NotFound' -StringValues $groupName -EnableException $EnableException -Continue }
			
			Get-LdapObject @adParameters -LdapFilter "(&(memberof$($recurseModifier)=$($groupObject.DistinguishedName))$($typeCondition))" -Property $actualProperties -TypeName Ldap.GroupMember -AddProperty @{
				Group = $groupObject.SamAccountName
				GroupDN = $groupObject.DistinguishedName
			}
		}
	}
}