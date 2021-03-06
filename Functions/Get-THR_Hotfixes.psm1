function Get-THR_Hotfixes {
    <#
    .SYNOPSIS 
        Gets the hotfixes applied to a given system.

    .DESCRIPTION 
        Gets the hotfixes applied to a given system. Get-Hotfix returns only OS-level hotfixes, this one grabs em all.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Hotfixes 
        Get-THR_Hotfixes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Hotfixes
        Get-THR_Hotfixes $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Hotfixes

    .NOTES 
        Updated: 2018-08-05

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2018
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
        
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.

    .LINK
        https://github.com/TonyPhipps/THRecon
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class Hotfix
        {
            [string] $Computer
            [string] $DateScanned

            [String] $Operation
            [string] $ResultCode
            [String] $HResult
            [String] $Date
            [String] $Title
            [String] $Description
            [String] $UnmappedResultCode
            [String] $ClientApplicationID
            [String] $ServerSelection
            [String] $ServiceID
            [String] $UninstallationNotes
            [String] $SupportUrl
        }

        $Command = {

            $Session = New-Object -ComObject "Microsoft.Update.Session"
            $Searcher = $Session.CreateUpdateSearcher()
            $historyCount = $Searcher.GetTotalHistoryCount()
            $Searcher.QueryHistory(0, $historyCount) | Where-Object Title -ne $null
        }
	}

    process{

        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }

        if ($ResultsArray){
            
            $OutputArray = foreach ($Hotfix in $ResultsArray) {

                $output = $null
                $output = [Hotfix]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o

                $output.Operation = $Hotfix.Operation
                $output.ResultCode = $Hotfix.ResultCode
                $output.HResult = $Hotfix.HResult
                $output.Date = $Hotfix.Date
                $output.Title = $Hotfix.Title
                $output.DESCRIPTION = $Hotfix.DESCRIPTION
                $output.UnmappedResultCode = $Hotfix.UnmappedResultCode
                $output.ClientApplicationID = $Hotfix.ClientApplicationID
                $output.ServerSelection = $Hotfix.ServerSelection
                $output.ServiceID = $Hotfix.ServiceID
                $output.UninstallationNotes = $Hotfix.UninstallationNotes
                $output.SupportUrl = $Hotfix.SupportUrl

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Hotfix]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format o
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}