﻿#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory


$global_variables = "\\kiewitplaza\ktg\Active\KSS\KSS_Toolkit\KSS MultiTool\lib\Global.ps1"
. $global_variables


$cmtrace_folder = "\\kiewitplaza\cts\Deployments\Microsoft\CMTrace\"
$cmtrace = $(get-childitem $cmtrace_folder | sort-object -Descending)[0].Name

$theme_settings = "c:\Users\jh2.admin\AppData\Local\KSS\Theme\theme.ps1"
$theme = "\\kiewitplaza\ktg\Active\KSS\KSS_Toolkit\KSS MultiTool\Theme"

if (Test-Path "c:\Users\$env:username\AppData\Local\KSS\Theme\theme.ps1")
{
	New-Item -ItemType Directory "c:\Users\jh2.admin\AppData\Local\KSS\Theme\"
	Copy-Item "$theme\theme.ps1" $theme_settings
}

. $theme_settings


#--------------------------------------------
# Custom Functions
#--------------------------------------------
Function Get-IniContent
{
    <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>	
	
	[CmdletBinding()]
	Param (
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ (Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini") })]
		[Parameter(ValueFromPipeline = $True, Mandatory = $True)]
		[string]$FilePath
	)
	
	Begin
	{ Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started" }
	
	Process
	{
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"
		
		$ini = @{ }
		switch -regex -file $FilePath
		{
			"^\[(.+)\]$" # Section  
			{
				$section = $matches[1]
				$ini[$section] = @{ }
				$CommentCount = 0
			}
			"^(;.*)$" # Comment  
			{
				if (!($section))
				{
					$section = "No-Section"
					$ini[$section] = @{ }
				}
				$value = $matches[1]
				$CommentCount = $CommentCount + 1
				$name = "Comment" + $CommentCount
				$ini[$section][$name] = $value
			}
			"(.+?)\s*=\s*(.*)" # Key  
			{
				if (!($section))
				{
					$section = "No-Section"
					$ini[$section] = @{ }
				}
				$name, $value = $matches[1 .. 2]
				$ini[$section][$name] = $value
			}
		}
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
		Return $ini
	}
	
	End
	{ Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended" }
}


#----------------------------------------------------------------------------------------------------
# importing ticket watch sheet variables
#----------------------------------------------------------------------------------------------------
#Start-Process $bin\TW.exe
$importedvariables = Get-IniContent -FilePath $configini
$importedvariables_FS = Get-IniContent -FilePath $fs_configini
$importedvariables_KSSContacts = Get-IniContent -FilePath $KSSContacts_configini
$importedvariables_lunch = Get-IniContent -FilePath $lunch_configini

#----------------------------------------------------------------------------------------------------
# custom variables
#----------------------------------------------------------------------------------------------------
$kssteamshare = "\\kiewitplaza\ktg\Active\KSS\KSS_Toolkit\KSS MultiTool"
$twdb = "$kssteamshare\Josh Dev stuff\update-TWDB.exe"
$localversion = (Get-Item "$installpath\KSS Tools.exe").versioninfo.fileversion





#----------------------------------------------------------------------------------------------------
# custom functions
#----------------------------------------------------------------------------------------------------
#region Control Helper Functions
function Update-DataGridView
{
	<#
	.SYNOPSIS
		This functions helps you load items into a DataGridView.

	.DESCRIPTION
		Use this function to dynamically load items into the DataGridView control.

	.PARAMETER  DataGridView
		The DataGridView control you want to add items to.

	.PARAMETER  Item
		The object or objects you wish to load into the DataGridView's items collection.
	
	.PARAMETER  DataMember
		Sets the name of the list or table in the data source for which the DataGridView is displaying data.

	.PARAMETER AutoSizeColumns
	    Resizes DataGridView control's columns after loading the items.
	#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.DataGridView]$DataGridView,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Item,
		[Parameter(Mandatory = $false)]
		[string]$DataMember,
		[System.Windows.Forms.DataGridViewAutoSizeColumnMode]$AutoSizeColumns = 'None'
	)
	$DataGridView.SuspendLayout()
	$DataGridView.DataMember = $DataMember
	
	if ($Item -is [System.Data.DataSet] -and $Item.Tables.Count -gt 0)
	{
		$DataGridView.DataSource = $Item.Tables[0]
	}
	elseif ($Item -is [System.ComponentModel.IListSource]`
		-or $Item -is [System.ComponentModel.IBindingList] -or $Item -is [System.ComponentModel.IBindingListView])
	{
		$DataGridView.DataSource = $Item
	}
	else
	{
		$array = New-Object System.Collections.ArrayList
		
		if ($Item -is [System.Collections.IList])
		{
			$array.AddRange($Item)
		}
		else
		{
			$array.Add($Item)
		}
		$DataGridView.DataSource = $array
	}
	
	if ($AutoSizeColumns -ne 'None')
	{
		$DataGridView.AutoResizeColumns($AutoSizeColumns)
	}
	
	$DataGridView.ResumeLayout()
}

function ConvertTo-DataTable
{
	<#
		.SYNOPSIS
			Converts objects into a DataTable.
	
		.DESCRIPTION
			Converts objects into a DataTable, which are used for DataBinding.
	
		.PARAMETER  InputObject
			The input to convert into a DataTable.
	
		.PARAMETER  Table
			The DataTable you wish to load the input into.
	
		.PARAMETER RetainColumns
			This switch tells the function to keep the DataTable's existing columns.
		
		.PARAMETER FilterWMIProperties
			This switch removes WMI properties that start with an underline.
	
		.EXAMPLE
			$DataTable = ConvertTo-DataTable -InputObject (Get-Process)
	#>
	[OutputType([System.Data.DataTable])]
	param (
		[ValidateNotNull()]
		$InputObject,
		[ValidateNotNull()]
		[System.Data.DataTable]$Table,
		[switch]$RetainColumns,
		[switch]$FilterWMIProperties)
	
	if ($null -eq $Table)
	{
		$Table = New-Object System.Data.DataTable
	}
	
	if ($InputObject -is [System.Data.DataTable])
	{
		$Table = $InputObject
	}
	elseif ($InputObject -is [System.Data.DataSet] -and $InputObject.Tables.Count -gt 0)
	{
		$Table = $InputObject.Tables[0]
	}
	else
	{
		if (-not $RetainColumns -or $Table.Columns.Count -eq 0)
		{
			#Clear out the Table Contents
			$Table.Clear()
			
			if ($null -eq $InputObject) { return } #Empty Data
			
			$object = $null
			#find the first non null value
			foreach ($item in $InputObject)
			{
				if ($null -ne $item)
				{
					$object = $item
					break
				}
			}
			
			if ($null -eq $object) { return } #All null then empty
			
			#Get all the properties in order to create the columns
			foreach ($prop in $object.PSObject.Get_Properties())
			{
				if (-not $FilterWMIProperties -or -not $prop.Name.StartsWith('__')) #filter out WMI properties
				{
					#Get the type from the Definition string
					$type = $null
					
					if ($null -ne $prop.Value)
					{
						try { $type = $prop.Value.GetType() }
						catch { Out-Null }
					}
					
					if ($null -ne $type) # -and [System.Type]::GetTypeCode($type) -ne 'Object')
					{
						[void]$table.Columns.Add($prop.Name, $type)
					}
					else #Type info not found
					{
						[void]$table.Columns.Add($prop.Name)
					}
				}
			}
			
			if ($object -is [System.Data.DataRow])
			{
				foreach ($item in $InputObject)
				{
					$Table.Rows.Add($item)
				}
				return @( ,$Table)
			}
		}
		else
		{
			$Table.Rows.Clear()
		}
		
		foreach ($item in $InputObject)
		{
			$row = $table.NewRow()
			
			if ($item)
			{
				foreach ($prop in $item.PSObject.Get_Properties())
				{
					if ($table.Columns.Contains($prop.Name))
					{
						$row.Item($prop.Name) = $prop.Value
					}
				}
			}
			[void]$table.Rows.Add($row)
		}
	}
	
	return @( ,$Table)
}
#endregion

