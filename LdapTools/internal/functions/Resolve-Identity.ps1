function Resolve-Identity
{
<#
	.SYNOPSIS
		Returns the type of the identifier string offered.
	
	.DESCRIPTION
		Returns the type of the identifier string offered.
		Can differentiate between distinguished names, objectGuid or SID.
		Will not perform any network calls to validate results.
	
	.PARAMETER Name
		The name to resolve
	
	.PARAMETER GetFilterCondition
		Returns a valid ldap filter condition instead of just the type
	
	.PARAMETER AllowSamAccountName
		By default, only DNs, Guids and SIDs are accepted as identifiers.
		All other inputs cause errors.
		By setting this switch, we also allow SamAccountNames as fourth input option.
		This is inherently less precise and should only be used with object types supporting that property.
	
	.EXAMPLE
		PS C:\> Resolve-Identity -Name '92469e61-8005-4c6d-b17c-478118f66c20'
		
		Validates that the specified string is a GUID.
#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[switch]
		$GetFilterCondition,
		
		[switch]
		$AllowSamAccountName
	)
	
	if ($Name -match '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$') { $type = 'Guid' }
	elseif ($Name -like "*=*") { $type = 'DN' }
	elseif ($Name -match '^S-1-5-21-\d{7}-\d{9}-\d{9}-\d+$') { $type = 'SID' }
	elseif ($AllowSamAccountName) { $type = 'SamAccountName' }
	else { $type = 'Unknown' }
	
	if (-not $GetFilterCondition) { return $type }
	
	switch ($type)
	{
		'SID' { "(objectSID=$($Name))" }
		'Guid'
		{
			$bytes = ([guid]$Name).ToByteArray()
			$segments = foreach ($byte in $bytes)
			{
				"\{0}" -f ([convert]::ToString($byte, 16))
			}
			"(objectGuid=$($segments -join ''))"
		}
		'DN' { "(distinguishedName=$($Name))" }
		default
		{
			if ($AllowSamAccountName) { "(samAccountName=$($Name))" }
			else { throw "Unknown identity type: $Name" }
		}
	}
}