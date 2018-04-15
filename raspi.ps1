# pull latest changes
cd tomtorggler.github.io
git pull

. ./MiningStats.ps1

$s9stats = Get-AntMinerStats -ComputerName s91,s92 -Type S9
$s9stats | ForEach-Object {
    $_ | Export-Csv -NoTypeInformation -NoClobber -Force -Append -Path "./_data/$($_.Host)stats.csv"
}

# Commit and push to GitHub
git add .
git commit -m "updates index by raspi"
git push
