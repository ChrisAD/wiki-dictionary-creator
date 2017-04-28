$url = "https://dumps.wikimedia.org/other/static_html_dumps/current/"
$dir = iwr -uri $url
$links = $dir.Links.innerText
$cnt = 0
foreach ($link in $links) {
	if($link -ne "../") {
		$cnt = $cnt +1
		write-host "*"$cnt" "$link 
	}

}
#TODO: Future tech: Comma separated list
$choice = Read-Host -Prompt "? Choose the number of which language you want to grab titles from"
write-host "-"$($links[$choice].replace("/",""))"it is..."
#Download into a tmp outfile and check if it exists	
if(!(Test-Path $($links[$choice].replace("/","")))) {
	write-host $links[$choice] "it is... Parsing..."
	$fetchUrl = $($url)+$($links[$choice])+$("html.lst")
	$parseThis = iwr -uri $fetchUrl
	$path = $link -replace "/",""
	write-host "Fetching URL: "$fetchUrl
	$logCnt = 0
	$x = @()
	foreach ($line in $parseThis.toString().split()) {
		$logCnt += 1
		if ($($logCnt) % 100 -eq 0) { 
			write-host $("* Working article #")$($logCnt)$($line)
		}		
		if ($line.toString().split("/").length -gt 4) {
			$clean = $line.toString().split("/")[5].split(".")[0]
			#Remove some wikipedia specifics
			$clean = $clean -replace "User~",""
			$clean = $clean -replace "Image~",""
			$clean = $clean -replace "User_talk~",""
			$clean = $clean -replace "Wikipedia~",""
			$clean = $clean -replace "Category~",""
			$clean = $clean -replace "Template~",""
			$clean = $clean -replace "Talk~",""

			$out += $clean
			$out += $clean -replace "_", " "
			$out += $clean -replace "-", " "
			$out += $clean -replace "_", "" | %{$_ -replace "!", ""} | %{$_ -replace "-", ""} | %{$_ -replace "~", ""}
			#$out = $out | sort -unique
			$out | out-file $links[$choice].replace("/","")
			#Get-Content $path | Sort-Object | Get-Unique | set-content -encoding utf8 -Path $path
			#write-host $parseThis
			#break
		}
	} else {
		write-host "File: "$links[$choice]
	}
} else {
	write-host "!" $($links[$choice].replace("/","")) "exists... Exiting!"
}