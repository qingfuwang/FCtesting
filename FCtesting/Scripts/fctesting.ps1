$linuxagentpath=$args[0]
$distro=$args[1]
$password=$args[2]
echo "linuxagentpath  $linuxagentpath distro $distro "
cd C:\DeploymentScripts_FC123_withPdu

 $nodesinfo = .\StartFCClient.cmd nodes?;
 $str_nodesinfo=[System.String]::Join(";",$nodesinfo);
 $str_nodesinfo  -match '(?m).*(00000000-\S*).*'
 $nodeid=$Matches[1]
 $waitReady=100;
#$nodeid="00000000-0000-0000-0000-008cfa086314"
 $output = .\StartFCClient.cmd nodeip? /node:$nodeid
 $str_nodesip=[System.String]::Join(";", $output);
 $str_nodesip  -match '(?m).*'+$nodeid+'- (.*);; .*'
$nodeip=$Matches[1]

 net use /DELETE \\$nodeip
 "net use \\$nodeip /user:rdTestUser $password"
 net use \\$nodeip /user:rdTestUser $password
 if(-not $LASTEXITCODE -eq 0)
{
 while($waitReady-- -gt 0)
{
  .\StartFCClient.cmd createuseraccount:$nodeid /username:rdTestUser /password:$password /expiration:30000 
  if ($LASTEXITCODE -eq 0) {break};
  sleep 30;
  write-host "$(date) Wait for $nodeid ready"
  
};
}

sc start RemoteAccess

cd $linuxagentpath
$tests = "
OSBlobName,ISOBlobName,TestName,TenantName
$distro,linux_Certs_page.iso,PositiveTests,$distro.replace(".","")
"
Set-Content -Value $tests .\temp_data.csv
.\RunTestsWithCSV.ps1 .\data2.csv
