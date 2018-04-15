# pull latest changes
cd tomtorggler.github.io
git pull

# dot source the functions 

. ./MiningStats.ps1

# Get Information from the API
$l3stats = Get-AntMinerStats -ComputerName l31,l32 -Type l3

$l3stats | ForEach-Object {
    $_ | Export-Csv -NoTypeInformation -NoClobber -Force -Append -Path "./_data/$($_.Host)stats.csv"
}
#yeah its latae...
Remove-Item ./_data/stats.csv -ErrorAction SilentlyContinue 

Get-M01Stats | Export-Csv -NoTypeInformation -NoClobber -Force -Append -Path "./_data/m01stats.csv"
Get-MiningResults | Export-Csv -Path ./_data/earnings.csv -Force -NoClobber -NoTypeInformation -Append

# Create output html tables 
#$out = $l3stats | Select-Object Host,Uptime,HashRate,'T. max',Fan*,'ASIC'
#$out += $s9stats | Select-Object Host,Uptime,HashRate,'T. max',Fan*,'ASIC'
#$out += $m01stats
#
#$outTemp= $l3stats | Select-Object Host,T.*,Fan*
#$outTemp += $s9stats | Select-Object Host,T.*,Fan*
#
#$outHw= $l3stats | Select-Object Host,Freq,ASIC_*
#$outHw += $s9stats | Select-Object Host,Freq,ASIC_*
#
#$outAsic = $l3stats | Select-Object Host,*Status
#$outAsic += $s9stats | Select-Object Host,*Status
#
#$mainTable = $out | ConvertTo-Html -Fragment
#$unpaidTable = Get-MiningResults | ConvertTo-Html -Fragment -As List
#$tempTable = $outTemp | ConvertTo-Html -Fragment
#$hardwareTable = $outHw | ConvertTo-Html -Fragment
#$asicTable = $outAsic | ConvertTo-Html -Fragment -As List 



# write html to file, not pretty but works for now :)
@"
---
layout: default
title: Mining Statistics
date: $(get-date -Format "yyyy-MM-dd HH:mm:ss")
---

$unpaidTable

$mainTable

"@ # | Set-Content -Path index.html

@"
---
layout: default
title: Hardware Details
date: $(get-date -Format "yyyy-MM-dd HH:mm:ss")
permalink: /hw/
---

<h2>Temperature Detail</h2> 

$tempTable 

<h2>ASIC Errors</h2>

$hardwareTable 

<h2>ASIC Status</h2>

$asicTable

"@ #| Set-Content hw.html

#$hardware = ConvertTo-Html -Body "<h2>Temperature Detail</h2> $tempTable <h2>ASIC Errors</h2> $hardwareTable <h2>ASIC Status</h2> $asicTable"  
#$index = ConvertTo-Html -Body "$unpaidTable $mainTable"

#clean csv
Update-CSV -path ./_data -keep 500


# commit and push to github
git add .
git commit -m "updates index by m01"
git push
