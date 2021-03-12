# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Disable-LdapAccount.AlreadyDisabled'			  = 'Account already disabled: {0} - Skipping' # $adAccount.Properties.samaccountname[0]
	'Disable-LdapAccount.Disabling'				      = 'Disabling account {0}' # $adAccount.Properties.samaccountname[0]
	
	'Enable-LdapAccount.AlreadyEnabled'			      = 'Account already enabled: {0} - Skipping' # $adAccount.Properties.samaccountname[0]
	'Enable-LdapAccount.Enabling'					  = 'Enabling account {0}' # $adAccount.Properties.samaccountname[0]
	
	'Get-LdapGroup.Identity.BadFormat'			      = 'Unable to identify group identifier format: {0} - make sure it''s a legal SamAccountName, DN, SID or ObjectGUID' # $groupName
	
	'Get-LdapGroupMember.Identity.BadFormat'		  = 'Unable to identify group identifier format: { 0 } - make sure it''s a legal SamAccountName, DN, SID or ObjectGUID' # $groupName
	'Get-LdapGroupMember.Identity.GroupAccessFailure' = 'Failed to execute ldap query to resolve group: {0}!' # $groupName
	'Get-LdapGroupMember.Identity.NotFound'		      = 'Group not found: {0}!' # $groupName
	
	'Get-LdapObject.SearchError'					  = 'Failed to execute ldap request.' # 
	'Get-LdapObject.Searchfilter'					  = 'Searching with filter: {0}' # $LdapFilter
	'Get-LdapObject.SearchRoot'					      = 'Searching {0} in {1}' # $SearchScope, $searcher.SearchRoot.Path
	
	'Set-LdapAccountPassword.Resetting'			      = 'Resetting the password of account {0}' # $adAccount.Properties.samaccountname[0]
	
	'Sync-LdapObject.DestinationAccessError'		  = 'Failed to connect to destination server {0} | {1}' # $Target, $_
	'Sync-LdapObject.FailedReplication'			      = 'Failed to synchronize {0} from {1} to {2} | {3}' # $Object, $Server, $Target, $_
	'Sync-LdapObject.ObjectAccessError'			      = 'Error trying to resolve {0} | {1}' # $Object, $_
	'Sync-LdapObject.ObjectNotFound'				  = 'Failed to resolve {0} to an object' # $Object
	'Sync-LdapObject.PerformingReplication'		      = 'Performing replication from {0} to {1}' # $Server, $Target
	'Sync-LdapObject.SourceAccessError'			      = 'Failed to connect to source server {0} | {1}' # $Server, $_
	'Sync-LdapObject.SyncObjectFilter'			      = 'Resolved object input to LDAP filter: {0}' # $ldapFilter
}