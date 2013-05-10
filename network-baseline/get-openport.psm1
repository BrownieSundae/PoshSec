﻿



function Get-OpenPort{

<#
.Synopsis
  Compare currently open tcp ports to an established baseline.  Baselines are created by using the -baseline switch.
  Baseline is written as a .csv file, defaults to C:\Windows\poshsec_ports.csv

.PARAMETER Computername
  List of computers to run the cmdlet against. Powershell Remoting (WinRM) must be enabled on target machines.

.PARAMETER Baseline
  Indicates the cmdlet should write results to the baseline database, instead of comparing to the existing database.

.PARAMETER Csv
  Specify location to write or read baseline from.

.EXAMPLE
  Create initial baseline for localhost
  PS C:\> Get-OpenPort -baseline

.EXAMPLE
  Compare WEBSERV01 to the baseline
  PS C:\> Get-OpenPort -computername WEBSERV01

 .Link
        https://github.com/organizations/PoshSec

#>

[CmdletBinding()]
param(
    [alias('IP')]
    [string[]]$computername = 'localhost',

    [switch]$baseline,

    [string]$csv = 'C:\Windows\poshsec_ports.csv'

    )


    function Write-Baseline{
      if (-not ($computername[0] -eq 'localhost') -or $computername.Length -gt 1 ){
         $base = Invoke-Command -ComputerName $computername -ScriptBlock {
        
         $ipgp = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties();
       $listens = $ipgp.GetActiveTcpListeners();
       foreach($ip in $listens){
       $table += $computername + ", " + $ip.Port + "\n"    
          
       }
        $table
         }
         Out-File -filepath $csv -Append -NoClobber -inputobject $table

          }
          #local-only if no remoting
         else{
         
         $ipgp = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties();
       $listens = $ipgp.GetActiveTcpListeners();
       foreach($ip in $listens){
       $row = "localhost," + $ip.Port        
        Out-File -filepath $csv -Append -NoClobber -inputobject $row
       }

         }
          
       
    }

    function Get-Baseline{
      try{
       $comp = Import-Csv -Path $csv -Header Computer, Port
      }
      catch{
        Write-Error "File not found at $csv"
        return;
      }
       $comp
      
       $ipgp = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties();
       $listens = $ipgp.GetActiveTcpListeners();
       foreach($ip in $listens){
         if($comp| where {$_.port -eq $ip.port}){
         #Write-host $ip.Port + " checked"
         }
         else{
         $warn = "Port " + ($ip.Port).ToString() + " is not part of the baseline."
         Write-Warning $warn
         }
         
         }
      
         
       
       }
    

    if($baseline){
    Write-Baseline
    }
    else{
    Get-Baseline
    }

  }