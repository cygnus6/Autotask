﻿Function Get-AtwsDefinition
{ 
  Begin
  { 
    $EntityName = '#EntityName'
    $Prefix = '#Prefix'

    If ($Verbose)
    {
      # Make sure the -Verbose parameter is inherited
      $VerbosePreference = 'Continue'
    }

    Write-Verbose ('{0}: Begin of function' -F $MyInvocation.MyCommand.Name)

  }

  Process
  {
    If (-not ($Filter))
    {
      $Fields = Get-AtwsFieldInfo -Entity $EntityName -Connection $Prefix
        
      Foreach ($Parameter in $PSBoundParameters.GetEnumerator())
      {
        $Field = $Fields | Where-Object {$_.Name -eq $Parameter.Key}
        If ($Field)
        { 
          If ($Parameter.Value.Count -gt 1)
          {
            $Filter += '-begin'
          }
          Foreach ($ParameterValue in $Parameter.Value)
          {   
            $Operator = '-or'
            If ($Field.IsPickList)
            {
              $PickListValue = $Field.PickListValues | Where-Object {$_.Label -eq $ParameterValue}
              $Value = $PickListValue.Value
            }
            Else
            {
              $Value = $ParameterValue
            }
            $Filter += $Parameter.Key
            If ($Parameter.Key -in $NotEquals)
            { 
              $Filter += '-ne'
              $Operator = '-and'
            }
            ElseIf ($Parameter.Key -in $GreaterThan)
            { $Filter += '-gt'}
            ElseIf ($Parameter.Key -in $GreaterThanOrEqual)
            { $Filter += '-ge'}
            ElseIf ($Parameter.Key -in $LessThan)
            { $Filter += '-lt'}
            ElseIf ($Parameter.Key -in $LessThanOrEquals)
            { $Filter += '-le'}
            ElseIf ($Parameter.Key -in $Like)
            { 
              $Filter += '-like'
              $Value = $Value -replace '\*','%'
            }
            ElseIf ($Parameter.Key -in $NotLike)
            { 
              $Filter += '-notlike'
              $Value = $Value -replace '\*','%'
            }
            ElseIf ($Parameter.Key -in $BeginsWith)
            { $Filter += '-beginswith'}
            ElseIf ($Parameter.Key -in $EndsWith)
            { $Filter += '-endswith'}
            ElseIf ($Parameter.Key -in $Contains)
            { $Filter += '-contains'}
            Else
            { $Filter += '-eq'}
            $Filter += $Value
            If ($Parameter.Value.Count -gt 1 -and $ParameterValue -ne $Parameter.Value[-1])
            {
              $Filter += $Operator
            }
            ElseIf ($Parameter.Value.Count -gt 1)
            {
              $Filter += '-end'
            }
          }
            
        }
      }
        
    } #'NotEquals','GreaterThan','GreaterThanOrEqual','LessThan','LessThanOrEquals','Like','NotLike','BeginsWith','EndsWith

    $Result = Get-AtwsData -Entity $EntityName -Filter $Filter -Connection $Prefix

    Write-Verbose ('{0}: Number of entities returned by base query: {1}' -F $MyInvocation.MyCommand.Name, $Result.Count)
    
    if ( ($Result) -and ($GetReferenceEntityById))
    {
      Write-Verbose ('{0}: User has asked for external reference objects by {1}' -F $MyInvocation.MyCommand.Name, $GetReferenceEntityById)
      
      $Field = $Fields.Where({$_.Name -eq $GetReferenceEntityById})
      $ResultValues = $Result | Where-Object {$_.$GetReferenceEntityById -ne $null}
      If ($ResultValues.Count -lt $Result.Count)
      {
        Write-Warning ('{0}: Only {1} of the {2}s in the primary query had a value in the property {3}.' -F $MyInvocation.MyCommand.Name, 
          $ResultValues.Count,
          $EntityName,
          $GetReferenceEntityById) -WarningAction Continue
      }
      $Filter = 'id -eq {0}' -F $($ResultValues.$GetReferenceEntityById -join ' -or id -eq ')
      $ReferenceResult = Get-Atwsdata -Entity $Field.ReferenceEntityType -Filter $Filter -Connection $Prefix
      If ($ReferenceResult)
      {
        $Result = $ReferenceResult
      }
    }
  }

  End
  {
    Write-Verbose ('{0}: End of function' -F $MyInvocation.MyCommand.Name)
    If ($Result)
    {
      Return $Result
    }
  }

}
