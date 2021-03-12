function Get-LdapObject {
    <#
        .SYNOPSIS
            Use LDAP to search in Active Directory

        .DESCRIPTION
            Utilizes LDAP to perform swift and efficient LDAP Queries.

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

        .PARAMETER Configuration
            Rather than searching in a specified path, switch to the configuration naming context.

        .PARAMETER Raw
            Return the raw AD object without processing it for PowerShell convenience.

        .PARAMETER PageSize
            Rather than searching in a specified path, switch to the schema naming context.

        .PARAMETER MaxSize
            The maximum number of items to return.

        .PARAMETER SearchScope
            Whether to search all OUs beneath the target root, only directly beneath it or only the root itself.
	
		.PARAMETER AddProperty
			Add additional properties to the output object.
			Use to optimize performance, avoiding needing to use Add-Member.

        .PARAMETER Server
            The server to contact for this query.

        .PARAMETER Credential
            The credentials to use for authenticating this query.
	
		.PARAMETER TypeName
			The name to give the output object

        .EXAMPLE
            PS C:\> Get-LdapObject -LdapFilter '(PrimaryGroupID=516)'
            
            Searches for all objects with primary group ID 516 (hint: Domain Controllers).
    #>
	[Alias('ldap')]
	[CmdletBinding(DefaultParameterSetName = 'SearchRoot')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$LdapFilter,
		
		[Alias('Properties')]
		[string[]]
		$Property = "*",
		
		[Parameter(ParameterSetName = 'SearchRoot')]
		[Alias('SearchBase')]
		[string]
		$SearchRoot,
		
		[Parameter(ParameterSetName = 'Configuration')]
		[switch]
		$Configuration,
		
		[switch]
		$Raw,
		
		[ValidateRange(1, 1000)]
		[int]
		$PageSize = 1000,
		
		[Alias('SizeLimit')]
		[int]
		$MaxSize,
		
		[System.DirectoryServices.SearchScope]
		$SearchScope = 'Subtree',
		
		[System.Collections.Hashtable]
		$AddProperty,
		
		[string]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[Parameter(DontShow = $true)]
		[string]
		$TypeName
	)
	
	begin {
		#region Utility Functions
		function Get-PropertyName {
			[CmdletBinding()]
			param (
				[string]
				$Key,
				
				[string[]]
				$Property
			)
			
			if ($hit = @($Property).Where{ $_ -eq $Key }) { return $hit[0] }
			if ($Key -eq 'ObjectClass') { return 'ObjectClass' }
			if ($Key -eq 'ObjectGuid') { return 'ObjectGuid' }
			if ($Key -eq 'ObjectSID') { return 'ObjectSID' }
			if ($Key -eq 'DistinguishedName') { return 'DistinguishedName' }
			if ($Key -eq 'SamAccountName') { return 'SamAccountName' }
			$script:culture.TextInfo.ToTitleCase($Key)
		}
		#endregion Utility Functions
		
		#region Prepare Searcher
		$searcher = New-Object system.directoryservices.directorysearcher
		$searcher.PageSize = $PageSize
		$searcher.SearchScope = $SearchScope
		
		if ($MaxSize -gt 0) {
			$Searcher.SizeLimit = $MaxSize
		}
		
		if ($SearchRoot) {
			$searcher.SearchRoot = New-DirectoryEntry -Path $SearchRoot -Server $Server -Credential $Credential
		}
		else {
			$searcher.SearchRoot = New-DirectoryEntry -Server $Server -Credential $Credential
		}
		if ($Configuration) {
			$searcher.SearchRoot = New-DirectoryEntry -Path ("LDAP://CN=Configuration,{0}" -f $searcher.SearchRoot.distinguishedName[0]) -Server $Server -Credential $Credential
		}
		
		Write-PSFMessage -String Get-LdapObject.SearchRoot -StringValues $SearchScope, $searcher.SearchRoot.Path -Level Debug
		
		if (Test-PSFParameterBinding -ParameterName Credential) {
			$searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry($searcher.SearchRoot.Path, $Credential.UserName, $Credential.GetNetworkCredential().Password)
		}
		
		$searcher.Filter = $LdapFilter
		
		foreach ($propertyName in $Property) {
			$null = $searcher.PropertiesToLoad.Add($propertyName)
		}
		
		Write-PSFMessage -String Get-LdapObject.Searchfilter -StringValues $LdapFilter -Level Debug
		#endregion Prepare Searcher
	}
	process {
		try {
			foreach ($ldapobject in $searcher.FindAll()) {
				if ($Raw) {
					$ldapobject
					continue
				}
				#region Process/Refine Output Object
				$resultHash = @{ }
				foreach ($key in $ldapobject.Properties.Keys) {
					$resultHash[(Get-PropertyName -Key $key -Property $Property)] = switch ($key) {
						'ObjectClass' { $ldapobject.Properties[$key][-1] }
						'ObjectGuid' { [guid]::new(([byte[]]($ldapobject.Properties[$key] | Write-Output))) }
						'ObjectSID' { [System.Security.Principal.SecurityIdentifier]::new(([byte[]]($ldapobject.Properties[$key] | Write-Output)), 0) }
						
						default { $ldapobject.Properties[$key] | Write-Output }
					}
				}
				if ($resultHash.ContainsKey("ObjectClass")) { $resultHash["PSTypeName"] = $resultHash["ObjectClass"] }
				if ($TypeName) { $resultHash["PSTypeName"] = $TypeName }
				if ($AddProperty) { $resultHash += $AddProperty }
				$item = [pscustomobject]$resultHash
				Add-Member -InputObject $item -MemberType ScriptMethod -Name ToString -Value {
					if ($this.DistinguishedName) { $this.DistinguishedName }
					else { $this.AdsPath }
				} -Force -PassThru
				#endregion Process/Refine Output Object
			}
		}
		catch {
			Stop-PSFFunction -String 'Get-LdapObject.SearchError' -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $true
		}
	}
}