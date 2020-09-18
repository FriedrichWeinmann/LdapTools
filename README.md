# LdapTools

## Synopsis

The LdapTools PowerShell module offers the ability to run ldap queries against Active Directory without the need for the Active Directory module or ADWS.
It should offer a significantly improved performance at the loss of some comfort features.

And it is portable.

## Installing

To install the module, run this command:

```powershell
Install-Module LdapTools -Scope CurrentUser
```

It should install the module and the prerequisite `PSFramework` module.

## Using

Get a list of all groups:

```powershell
Get-LdapGroup
```

Execute a custom query:

```powershell
Get-LdapObject -LdapFilter '(samAccountName=fred)'
```
