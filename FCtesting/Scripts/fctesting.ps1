$linuxagentpath=$args[0]
$distro=$args[1]
$password=$args[2]
 write-host "linuxagentpath  $linuxagentpath distro $distro "
cd C:\DeploymentScripts_FC123_withPdu

 $nodesinfo = .\StartFCClient.cmd nodes?;
 $str_nodesinfo=[System.String]::Join(";",$nodesinfo);
 $str_nodesinfo  -match '(?m).*(00000000-\S*).*'
 $nodeid=$Matches[1]
 $waitReady=100;

#$nodeid="00000000-0000-0000-0000-008cfa086314"
 $output = .\StartFCClient.cmd nodeip? /node:$nodeid
 $str_nodesip=[System.String]::Join(";", $output);
 $str_nodesip  -match '(?m).*'+$nodeid+' - (.*);; .*'
$nodeip=$Matches[1]

 while($waitReady-- -gt 0)
{
  .\StartFCClient.cmd deleteuseraccount:$nodeid /username:rdTestUser 
  .\StartFCClient.cmd createuseraccount:$nodeid /username:rdTestUser /password:$password /expiration:30000 
  net use /DELET \\$nodeip
  net use \\$nodeip /user:rdTestUser $password
  if ($LASTEXITCODE -eq 0) {break};
  sleep 30;
  write-host "$(date) Wait for $nodeid ready"
  
};


Start-Service RemoteAccess;
sleep 5
write-host $(Get-Service RemoteAccess).Status;

cd $linuxagentpath
$tests = @"
OSBlobName,ISOBlobName,TestName,TenantName
$distro,linux_Certs_page.iso,PositiveTests,$($distro.replace(".",""))
"@
Set-Content -Value $tests .\temp_data.csv
.\RunTestsWithCSV.ps1 .\temp_data.csv 

$results=dir $linuxagentpath\log |Sort-Object -Property LastWriteTime -Descending
$results=($results[0],$results[1])|Sort-Object -Property Length
cp -force $results[0].fullname $linuxagentpath\log\summary.log
cp -force $results[1].fullname $linuxagentpath\log\test.log
