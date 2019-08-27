#Options with default values. These should be inputted preferably from command line. Pull request anyone? 
$extractTitles = $TRUE
$force = $FALSE
$cleanDictionary = $TRUE


if (!(Get-MpPreference | foreach-object{$_.DisableRealtimeMonitoring})) {
	Write-Host "! - Windows defender Real Time monitoring enabled, expect significant performance reduction! Disable with 'Set-MpPreference -DisableRealtimeMonitoring 1'" -ForegroundColor Red
}

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
write-host "o - $($links[$choice].replace('/','')) selected... Storing file in$($selectedLanguageFile)" -ForegroundColor Blue
#Download into a tmp outfile and check if it exists	
if(!(Test-Path $selectedLanguageFile) -or ($force)) {
	$fetchUrl = $($url)+$($links[$choice])+$("html.lst") #TODO: Support full wiki, not just titles
	write-host "o - Fetching URL: "$fetchUrl -ForegroundColor Blue
	Invoke-WebRequest -uri $fetchUrl -OutFile $selectedLanguageFile
} else {
	write-host "! - $($selectedLanguageFile) exists... Reusing. Use flag -force to re-download" -ForegroundColor Red
}
#Garbage collect to clean up the Invoke-WebRequest. Probably unnecessary. 
[GC]::Collect() 
if($extractTitles) { #TODO: Support full wiki, not just titles
	$logCnt = 0
	$totalCountOfFile = get-content $selectedLanguageFile | measure-object | ForEach-Object {$_.Count}
	write-host "o - Parsing data from $($selectedLanguageFile). Total lines: $($totalCountOfFile)" -ForegroundColor Blue 
	$oldPercentage = 0
	foreach ($lines in get-content $selectedLanguageFile -ReadCount 0 -Encoding "utf8") {
		ForEach($line in $lines) {
			$logCnt += 1
			$subStrLength = $line.LastIndexOf(".")-$line.LastIndexOf("/")-1
			$clean = $line.Substring($line.LastIndexOf("/")+1,$subStrLength)
			#Remove some wikipedia specifics
			$clean = $clean.Substring($clean.IndexOf("~")+1)
			if ($clean -match '_[0-9a-f]{4}') { #Todo: recursive
				$indexOfChar = $clean.LastIndexOf("_")
				$clean = $clean.Substring(0,$indexOfChar)
			}
			$ipRegex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
			#Ignore IP addresses
			if (!($clean -match $ipRegex)) {
				#Show progress 
				$percentage = [Math]::truncate($logCnt / $totalCountOfFile * 100)
				if ($oldPercentage -ne $percentage) { 
					$oldPercentage = $percentage
					write-host "o - Working #$($logCnt) - $($percentage)% done - Candidate: $($line). Cleaned output before tokenizing: $($clean)" -ForegroundColor Blue
				}		
				Add-Content -Path "$($selectedLanguageFile).dict" $clean
				#Further tokenize the $clean to pull out more and interesting words. 
				$splitChars = @(";",",",".","-","_","!","@","#","%","&")
				
				foreach($chr in $splitChars) {
					if ($clean.Contains($chr)) {
						$splits = $clean.Split($chr)
						foreach ($s in $splits) {
							Add-Content -Encoding "utf8" -Path "$($selectedLanguageFile).dict" $s
						}
					}
				}
			}
			
		}
	}
} else {
	write-host "! - No actions specified." -ForegroundColor Red
}

if ($cleanDictionary) {
	write-host "o - Cleaning up the dictionary file $($selectedLanguageFile).dict." -ForegroundColor Blue
	get-content "$($selectedLanguageFile).dict" | Sort-Object | get-unique > "$($selectedLanguageFile).sort.uniq.dict"
	write-host "o - Saved cleaned dictionary file to: $($selectedLanguageFile).sort.uniq.dict" -ForegroundColor Cyan
}
write-host "x - Execution finished. Good luck with your wordlist!" -ForegroundColor Cyan