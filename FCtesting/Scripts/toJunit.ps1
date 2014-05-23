
$filename = $args[0]
$resultfile = $args[1]
$casename = $args[2]
if(-not $filename)
{
   Write-Host "toJunit.ps1 fcresultinputfile resultoutputfile TestSuitname"
   exit 0
}
if(-not $resultfile)
{
  $casename="result.xml"
}

if(-not $casename)
{
  $casename="FCtesting"
}

 Write-Host "toJunit.ps1 $filename $resultfile $casename"

Function Write-JunitXml([System.Collections.ArrayList] $Results, [System.Collections.HashTable] $HeaderData, [System.Collections.HashTable] $Statistics, $ResultFilePath)
{
$template = @'
<testsuite name="" file="">
<testcase classname="" name="" time="">
    <failure type=""></failure>
</testcase>
</testsuite>
'@

    $guid = [System.Guid]::NewGuid().ToString("N")
    $templatePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $guid + ".txt");

    $template | Out-File $templatePath -encoding UTF8
    # load template into XML object
    $xml = New-Object xml
    $xml.Load($templatePath)
    # grab template user
    $newTestCaseTemplate = (@($xml.testsuite.testcase)[0]).Clone()  

    $className = $HeaderData.className
    $xml.testsuite.name = $className
    $xml.testsuite.file = $HeaderData.className

    foreach($result in $Results) 
    {   
        $newTestCase = $newTestCaseTemplate.clone()
        $newTestCase.classname = $className
        $newTestCase.name = $result.Test.ToString()
        $newTestCase.time = $result.Time.ToString()
        if($result.Result -match "PASS")
        {   #Remove the failure node
            $newTestCase.RemoveChild($newTestCase.ChildNodes.item(0)) | Out-Null
        }
        else
        {
            $newTestCase.failure.InnerText =  $result.Result
        }
        $xml.testsuite.AppendChild($newTestCase) > $null
    }   

    # remove users with undefined name (remove template)
    $xml.testsuite.testcase | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.testsuite.RemoveChild($_) }
    # save xml to file
    Write-Host "Path" $ResultFilePath

    $xml.Save($ResultFilePath)

    Remove-Item $templatePath #clean up
}

$sample = '
TESTCASE 01: Verify cert works - PASS
TESTCASE 02: Verify ssh connectivity successful - PASS
e new password and reset password - PASS
TESTCASE 15: Verify that new user can be added - Fail
TESTCASE Deprovision(a) - Fail
'

[Array]$results=$();
$lines=$sample.Split("`n");
$lines|%{
   if($_ -match 'TESTCASE (.*) - (.*)')
   {
      echo "$($Matches[1]) $($Matches[2])"
      $results+=@{Test=$($Matches[1]);Time=-1;Result=$($Matches[2]);};
   }

}

[Array]$results=$();

Get-Content $args[0]|%{
   if($_ -match 'TESTCASE (.*) - (.*)')
   {
      echo "$($Matches[1]) $($Matches[2])"
      $results+=@{Test=$($Matches[1]);Time=-1;Result=$($Matches[2]);};
   }

}

$HeaderData=@{className=$casename}
Write-JunitXml -Results $results -HeaderData $HeaderData -ResultFilePath $resultfile
