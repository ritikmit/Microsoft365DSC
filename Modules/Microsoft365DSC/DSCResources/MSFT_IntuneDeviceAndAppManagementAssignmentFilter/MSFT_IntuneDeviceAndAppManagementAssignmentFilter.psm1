function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $True)]
        [System.String]
        $Identity,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('android', 'androidForWork','iOS', 'macOS', 'windowsPhone81', 'windows81AndLater', 'windows10AndLater', 'androidWorkProfile', 'unknown')]
        [System.String]
        $Platform,

        [Parameter()]
        [System.String]
        $Rule,

        [Parameter(Mandatory = $True)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Checking for the assignment filter {$DisplayName}"

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters `
        -ProfileName 'beta' -ErrorAction Stop

    $context=Get-MgContext
    if($null -eq $context)
    {
        New-M365DSCConnection -Workload 'MicrosoftGraph' `
            -InboundParameters $PSBoundParameters -ErrorAction Stop
    }

    Write-Verbose -Message "Select-MgProfile"
    Select-MgProfile -Name 'beta'
    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace "MSFT_", ""
    $CommandName  = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullResult = $PSBoundParameters
    $nullResult.Ensure = 'Absent'

    try
    {
        #Retrieve policy general settings
        $assignmentFilter = Get-MgDeviceAndAppManagementAssignmentFilter -Identity $Identity -ErrorAction Stop

        if ($null -eq $assignmentFilter)
        {
            Write-Verbose -Message "No assignment filter {$Identity} was found"
            return $nullResult
        }

        $returnHashtable=@{}
        $returnHashtable.Add("Identity",$Identity)
        $returnHashtable.Add("DisplayName",$assignmentFilter.displayName)
        $returnHashtable.Add("Description",$assignmentFilter.description)
        $returnHashtable.Add("Platform",$assignmentFilter.platform)
        $returnHashtable.Add("Rule",$assignmentFilter.rule)



        Write-Verbose -Message "Found assignment filter {$($assignmentFilter.displayName)}"

        $returnHashtable.Add("Ensure","Present")
        $returnHashtable.Add("Credential",$Credential)
        $returnHashtable.Add("ApplicationId",$ApplicationId)
        $returnHashtable.Add("TenantId",$TenantId)
        $returnHashtable.Add("ApplicationSecret",$ApplicationSecret)
        $returnHashtable.Add("CertificateThumbprint",$CertificateThumbprint)

        return $returnHashtable
    }
    catch
    {
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = ""
            $tenantIdValue = $Credential.UserName.Split('@')[1]
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return $nullResult
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [System.String]
        $Identity,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('android', 'androidForWork','iOS', 'macOS', 'windowsPhone81', 'windows81AndLater', 'windows10AndLater', 'androidWorkProfile', 'unknown')]
        [System.String]
        $Platform,

        [Parameter()]
        [System.String]
        $Rule,

        [Parameter(Mandatory = $True)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )


    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters `
        -ProfileName 'beta'

    Select-MgProfile -Name 'beta'
    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace "MSFT_", ""
    $CommandName  = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentPolicy = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Remove("Ensure") | Out-Null
    $PSBoundParameters.Remove("Credential") | Out-Null
    $PSBoundParameters.Remove("ApplicationId") | Out-Null
    $PSBoundParameters.Remove("TenantId") | Out-Null
    $PSBoundParameters.Remove("ApplicationSecret") | Out-Null
    $PSBoundParameters.Remove("CertificateThumbprint") | Out-Null

    if ($Ensure -eq 'Present' -and $currentPolicy.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating new assignment filter {$DisplayName}"

        New-MgDeviceAndAppManagementAssignmentFilter `
            -DisplayName $DisplayName `
            -Description $Description `
            -Platform $Platform `
            -Rule $Rule

    }
    elseif ($Ensure -eq 'Present' -and $currentPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Updating existing assignment filter {$DisplayName}"

        Update-MgDeviceAndAppManagementAssignmentFilter `
            -Identity $Identity `
            -DisplayName $DisplayName `
            -Description $Description `
            -Platform $Platform `
            -Rule $Rule

    }
    elseif ($Ensure -eq 'Absent' -and $currentPolicy.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing assignment filter {$DisplayName}"
        Remove-MgDeviceAndAppManagementAssignmentFilter -Identity $Identity
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $True)]
        [System.String]
        $Identity,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet('android', 'androidForWork','iOS', 'macOS', 'windowsPhone81', 'windows81AndLater', 'windows10AndLater', 'androidWorkProfile', 'unknown')]
        [System.String]
        $Platform,

        [Parameter()]
        [System.String]
        $Rule,

        [Parameter(Mandatory = $True)]
        [System.String]
        [ValidateSet('Absent', 'Present')]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace "MSFT_", ""
    $CommandName  = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion
    Write-Verbose -Message "Testing configuration of assignment filter {$DisplayName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('Credential') | Out-Null
    $ValuesToCheck.Remove('ApplicationId') | Out-Null
    $ValuesToCheck.Remove('TenantId') | Out-Null
    $ValuesToCheck.Remove('ApplicationSecret') | Out-Null

    $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $ApplicationSecret,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )


    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters `
        -SkipModuleReload:$true

    Select-MgProfile -Name 'Beta'
    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace "MSFT_", ""
    $CommandName  = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $dscContent = ''
    $i = 1

    try
    {
        [array]$assignmentFilters = Get-MgDeviceAndAppManagementAssignmentFilter -ErrorAction Stop

        if ($policies.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewLine
        }
        foreach ($assignmentFilter in $assignmentFilters)
        {
            Write-Host "    |---[$i/$($assignmentFilters.Count)] $($assignmentFilter.displayName)" -NoNewline

            $params = @{
                Identity                            = $assignmentFilter.id
                Ensure                              = 'Present'
                Credential                          = $Credential
                ApplicationId                       = $ApplicationId
                TenantId                            = $TenantId
                ApplicationSecret                   = $ApplicationSecret
                CertificateThumbprint               = $CertificateThumbprint
            }

            $Results = Get-TargetResource @params

            if ($Results.Ensure -eq 'Present')
            {
                $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                    -Results $Results
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $PSScriptRoot `
                    -Results $Results `
                    -Credential $Credential
                $dscContent += $currentDSCBlock
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName

                Write-Host $Global:M365DSCEmojiGreenCheckMark
                $i++
            }
        }
        return $dscContent
    }
    catch
    {
        Write-Host $Global:M365DSCEmojiRedX
        if ($_.Exception -like '*401*')
        {
            Write-Host "`r`n    $($Global:M365DSCEmojiYellowCircle) The current tenant is not registered for Intune."
        }
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = $Credential.UserName.Split('@')[1]

            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return ""
    }
}


function Get-MgDeviceAndAppManagementAssignmentFilter
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Identity
    )
    try
    {
        $assignmentFilters=@()
        $Uri="https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
        if(-not [String]::IsNullOrEmpty($Identity))
        {
            $Uri+="/$Identity"
        }
        Write-Verbose -Message $Uri
        $results=Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
        if($results.id)
        {
            return $results
        }
        $assignmentFilters+= $results.value
        while($results."@odata.nextLink")
        {
            $Uri=$results."@odata.nextLink"
            $results=Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
            $assignmentFilters+= $results.value
        }
        return $assignmentFilters
    }
    catch
    {
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = $Credential.UserName.Split('@')[1]

            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return $null
    }
}

function New-MgDeviceAndAppManagementAssignmentFilter
{
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = 'true')]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Platform,

        [Parameter()]
        [System.String]
        $Rule
    )

    $Uri="https://graph.microsoft.com/beta/deviceManagement/assignmentFilters"
    $policy=[ordered]@{
        "@odata.type"= "#microsoft.graph.deviceAndAppManagementAssignmentFilter"
        "displayName"=$DisplayName
        "description"=$Description
        "platform"=$Platform
        "rule"=$Rule
    }
    #write-verbose (($policy|ConvertTo-Json -Depth 20))
    Invoke-MgGraphRequest -Method POST `
        -Uri $Uri `
        -ContentType "application/json" `
        -Body ($policy|ConvertTo-Json -Depth 20)
}

function Update-MgDeviceAndAppManagementAssignmentFilter
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $Identity,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Platform,

        [Parameter()]
        [System.String]
        $Rule
    )

    $Uri="https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$Identity"
    $policy=[ordered]@{
        "@odata.type"= "#microsoft.graph.deviceAndAppManagementAssignmentFilter"
        "displayName"=$DisplayName
        "description"=$Description
        "rule"=$Rule
    }

    #write-verbose (($policy|ConvertTo-Json -Depth 20))

    Invoke-MgGraphRequest -Method PATCH `
        -Uri $Uri `
        -ContentType "application/json" `
        -Body ($policy|ConvertTo-Json -Depth 20)
}

function Remove-MgDeviceAndAppManagementAssignmentFilter
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = 'true')]
        [System.String]
        $Identity
    )

    $Uri="https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$Identity"
    Invoke-MgGraphRequest -Method DELETE -Uri $Uri
}

Export-ModuleMember -Function *-TargetResource,*
