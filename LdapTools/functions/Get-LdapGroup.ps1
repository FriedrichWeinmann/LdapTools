function Get-LdapGroup
{
<#
	.SYNOPSIS
		Search active directory for groups.
	
	.DESCRIPTION
		Search active directory for groups.
	
	.PARAMETER Identity
		Unique identity of the group to search.
		Must be either SID, ObjectGuid or DistinguishedName.
	
	.PARAMETER LdapFilter
		The search filter to use when searching for objects.
		Must be a valid LDAP filter.
	
	.PARAMETER Property
		The properties to retrieve.
		Keep bandwidth in mind and only request what is needed.
	
	.PARAMETER SearchRoot
		The root path to search in.
		This generally expects either the distinguished name of the Organizational unit or the DNS name of the domain.
		Alternatively, any legal LDAP protocol address can be specified.
	
	.PARAMETER SearchScope
		Whether to search all OUs beneath the target root, only directly beneath it or only the root itself.
	
	.PARAMETER Server
		The server to contact for this query.
	
	.PARAMETER Credential
		The credentials to use for authenticating this query.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-LdapGroup
		
		List all groups in the current domain.
#>
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
		[string[]]
		$Identity,
		
		[Parameter(ParameterSetName = 'Filter')]
		[string]
		$LdapFilter = '(samAccountName=*)',
		
		[Alias('Properties')]
		[string[]]
		$Property,
		
		[string]
		$SearchRoot,
		
		[System.DirectoryServices.SearchScope]
		$SearchScope = 'Subtree',
		
		[string]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		# Prepare filter anyway, ignored if using Identity Parameter
		$filter = "(&(objectClass=group)($LdapFilter))"
		
		$defaultProperties = 'DistinguishedName', 'GroupCategory', 'GroupScope', 'Name', 'ObjectClass', 'ObjectGUID', 'SamAccountName', 'ObjectSID'
		$actualProperties = @($defaultProperties) + @($Property | Where-Object { $_ -notin $defaultProperties})
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include SearchRoot, Server, Credential
		$parameters.SearchScope = $SearchScope
		$parameters.Property = $actualProperties
	}
	process
	{
		foreach ($groupName in $Identity)
		{
			try { $condition = Resolve-Identity -Name $groupName -GetFilterCondition -AllowSamAccountName }
			catch { Stop-PSFFunction -String 'Get-LdapGroup.Identity.BadFormat' -StringValues $groupName -ErrorRecord $_ -EnableException $EnableException -Continue }
			
			Get-LdapObject @parameters -LdapFilter "(&(objectClass=group)$condition)" -TypeName 'Ldap.Group'
		}
		if (-not $Identity)
		{
			Get-LdapObject @parameters -LdapFilter $filter -TypeName 'Ldap.Group'
		}
	}
}