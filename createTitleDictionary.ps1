#Options
$extractTitles = $TRUE
$force = $FALSE

#Requirements
#Install-Module -Name 7Zip4Powershell

$localWorkingDirectory = $env:LOCALAPPDATA + "\wikipedia-dictionary-creator"
if (!(Test-Path $localWorkingDirectory)) {
	Write-host "Creating folder "$localWorkingDirectory" and using it for temporary files." -ForegroundColor Cyan
	New-Item -Path $localWorkingDirectory -ItemType "Directory" | Out-Null
} else {
	Write-host "Using "$localWorkingDirectory" for storing temporary files." -ForegroundColor Cyan
}


$url = "https://dumps.wikimedia.org/other/static_html_dumps/current/"
$dir = Invoke-WebRequest -uri $url
$links = $dir.Links.innerText
[System.Collections.ArrayList]$col1 = @()
[System.Collections.ArrayList]$col2 = @()
[System.Collections.ArrayList]$col3 = @()
$linkCount = 0
foreach ($link in $links) {
	if($link -ne "../") {
		$linkCount += 1
		$arrayStore = $linkCount % 3
		if ($arrayStore -eq 1) {
			$col1.Add("#"+$linkCount+" - "+$link) | Out-Null
		} elseif ($arrayStore -eq 2) {
			$col2.Add("#"+$linkCount+" - "+$link) | Out-Null
		} elseif ($arrayStore -eq 0) {
			$col3.Add("#"+$linkCount+" - "+$link) | Out-Null
		}
	}
}

for ($i = 0; $i -lt $col1.Count; $i++) {
	if ($col1[$i]) {
		write-host $col1[$i]"`t`t`t"$col2[$i]"`t`t`t"$col3[$i] -ForegroundColor Blue
	}
}

#TODO: Future tech: Comma separated list
Write-Host "? - Choose the number of which language you want to grab titles from" -ForegroundColor Green
$choice = Read-Host -Prompt "..."
#$choice = "166"
$selectedLanguageFile = "$($localWorkingDirectory)\$($links[$choice].replace('/','')).txt"
write-host "- $($links[$choice].replace('/','')) selected... Storing file in$($selectedLanguageFile)" -ForegroundColor Blue
#Download into a tmp outfile and check if it exists	
if(!(Test-Path $selectedLanguageFile) -or ($force)) {
	$fetchUrl = $($url)+$($links[$choice])+$("html.lst") #TODO: Support full wiki, not just titles
	write-host "- Fetching URL: "$fetchUrl -ForegroundColor Blue
	Invoke-WebRequest -uri $fetchUrl -OutFile $selectedLanguageFile
	$fetchUrl = $($url)+$($links[$choice])+$("images.lst") #TODO: Support full wiki, not just titles
	write-host "- Fetching URL: "$fetchUrl -ForegroundColor Blue
	Invoke-WebRequest -uri $fetchUrl -OutFile $selectedLanguageFile
} else {
	write-host "! - $($selectedLanguageFile) exists... Reusing. Use flag -force to re-download" -ForegroundColor Red
}
#Garbage collect to clean up the Invoke-WebRequest lol
[GC]::Collect() 
if($extractTitles) { #TODO: Support full wiki, not just titles
	$logCnt = 0
	$totalCountOfFile = get-content $selectedLanguageFile | measure-object | ForEach-Object {$_.Count}
	write-host "- Parsing data from $($selectedLanguageFile). Total lines: $($totalCountOfFile)" -ForegroundColor Blue #TODO add percentage and int from count
	$oldPercentage = 0
	foreach ($lines in get-content $selectedLanguageFile -ReadCount 0 -Encoding "utf8") {
		ForEach($line in $lines) {
			$logCnt += 1
			$subStrLength = $line.LastIndexOf(".")-$line.LastIndexOf("/")-1
			$clean = $line.Substring($line.LastIndexOf("/")+1,$subStrLength)
			#Remove some wikipedia specifics
			$clean = $clean.Substring($clean.IndexOf("~")+1)
			$percentage = [Math]::truncate($logCnt / $totalCountOfFile * 100)
			if ($oldPercentage -ne $percentage) { 
				$oldPercentage = $percentage
				write-host "- Working #$($logCnt) - $($percentage)% done - Candidate: $($line). Cleaned output: $($clean)" -ForegroundColor Blue
			}		
			Add-Content -Path "$($selectedLanguageFile).dict" $clean
		}
	}
} else {
	write-host "File: "$links[$choice] -ForegroundColor Blue
}