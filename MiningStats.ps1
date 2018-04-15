# A quick test to read AntMiner stats via API
# ... and more quick stuff to gather pool data 
# pwsh -f ". ./MiningStats.ps1; Get-AntMinerStats -ComputerName l31,l32 -Type l3"

function Get-AntMinerStats {
    [cmdletbinding()]
    param(
        $ComputerName,
        $Port = 4028,
        [ValidateSet("S9","L3")]
        $Type
    )
    foreach ($miner in $ComputerName) {

        # first check to see if miner is online... core does not yet have Test-Connection so go with ping
        Remove-Variable out,StringData,ping -ErrorAction SilentlyContinue
        #$ping = ping $miner -c 1
        $StringData = $null
        $StringData = (echo '{"command":"stats"}' | nc $miner $port).split(",").replace(":","=").replace('"','') | ConvertFrom-StringData
        if($StringData) {
            $out = [ordered]@{
                "TimeStamp" = $(get-date -Format "yyyy-MM-dd HH:mm:ss")
                "Host" = $miner
                "Uptime" = [math]::round((New-TimeSpan -Seconds $($StringData.Where{$_.Keys -eq "Elapsed"}.Values)).TotalHours,2)
                "HashRate" = $StringData.Where{$_.Keys -eq "GHS av"}.Values
                "Freq" = $StringData.Where{$_.Keys -eq "Frequency"}.Values
                "T_max" = $StringData.Where{$_.Keys -eq "temp_max"}.Values
                "ASIC" = "OK"        
            }
        
            # check for miner type and update outputs
            switch ($Type) {
                "S9" { 
                    foreach ($i in 6..8) {
                        $out.Add("T_$($i-5)",$StringData.Where{$_.Keys -eq "temp2_$i"}.Values)
                        $out.add("ASIC_$($i-5)_Status",$StringData.Where{$_.Keys -eq "chain_acs$i"}.Values)    
                        $out.add("ASIC_$($i-5)",$StringData.Where{$_.Keys -eq "chain_hw$i"}.Values)  
                    }
                    $out.Add("Fan_1",$StringData.Where{$_.Keys -eq "fan3"}.Values)
                    $out.Add("Fan_2",$StringData.Where{$_.Keys -eq "fan6"}.Values)
                }
                "L3" {
                    foreach ($i in 1..4) {
                        $out.add("T_$i",$StringData.Where{$_.Keys -eq "temp2_$i"}.Values)
                        $out.add("ASIC_$($i)_Status",$StringData.Where{$_.Keys -eq "chain_acs$i"}.Values)    
                        $out.add("ASIC_$($i)",$StringData.Where{$_.Keys -eq "chain_hw$i"}.Values)
                    }
                    $out.add("Fan_1",$StringData.Where{$_.Keys -eq "fan1"}.Values)
                    $out.add("Fan_2",$StringData.Where{$_.Keys -eq "fan2"}.Values)
                }
            }
    
            foreach ($item in $($out.Keys.Where{$_ -like "*Status"})) {
                if($out.$($item) -match "x") {
                    $out.ASIC = "x"
                } elseif($out.$($item) -match "-") {
                    $out.ASIC = "-"
                }
            }
            
        } else {
            Write-Warning "$miner is not reachable!"
            $out = [ordered]@{
                "TimeStamp" = $(get-date -Format "yyyy-MM-dd HH:mm:ss")
                "Host" = $miner
                "Uptime" = "-"
                "HashRate" = "-"
                "Freq" = "-"
                "T_max" = "-"
                "ASIC" = "-"        
            }
        }

        Write-Output (New-Object -TypeName psobject -Property $out) 
    }
}

function Get-M01Stats {
    param(
        $ComputerName = "m01"
    )
    
    # kind of complicated
    #$sensors = sensors | Select-String -Pattern ":"
    #$sensorsTable = $sensors -replace ":","=" | ConvertFrom-StringData

    try {
        $xmrApi = Invoke-RestMethod -uri "http://$ComputerName`:16000/api.json" -ErrorAction Stop
        $hashrate = $xmrApi | Select-Object -ExpandProperty hashrate | Select-Object -ExpandProperty total | Select-Object -First 1
    } catch {
        Write-Warning "Could not connect to XMR Api"
    }

    $out = [ordered]@{
        "TimeStamp" = $(get-date -Format "yyyy-MM-dd HH:mm:ss")
        "Host" = $ComputerName;
        "Uptime" = [math]::Round((New-TimeSpan -Start (uptime -s) -End (get-date)).TotalHours,2);
        "HashRate" = $hashrate
    }
    Write-Output (New-Object -TypeName psobject -Property $out)
}

function Get-NiceHashResults {
    [cmdletbinding()]
    param(
        $Address
    )
    $uri = "https://api.nicehash.com/api?method=stats.provider&addr=$Address"
    Invoke-RestMethod -Uri $uri 
}

function Get-NiceHashWorkers {
    [cmdletbinding()]
    param(
        $Address
    )
    $uri = "https://api.nicehash.com/api?method=stats.provider.workers&addr=$Address" 
    Invoke-RestMethod -Uri $uri | select -ExpandProperty result
}


function Get-LiteCoinResults {
    [cmdletbinding()]
    param(
        $Key
    )
    $uri = "https://www.litecoinpool.org/api?api_key=$key"
    Invoke-RestMethod -Uri $uri 
}

function Get-SupportXmrResults {
    [cmdletbinding()]
    param (
        $Address
    )
    $uri = "https://supportxmr.com/api/miner/$Address/stats"
    $out = Invoke-RestMethod -Uri $uri
    $out.amtDue = $out.amtDue / 1000000000000 
    $out
}

function Get-BitcoinComResults {
    [cmdletbinding()]
    param(
        $Key
    )
    $UserUri = "https://console.pool.bitcoin.com/srv/api/user?apikey=$Key"
    #$WorkerUri = "https://console.pool.bitcoin.com/srv/api/workers?apikey=$Key" 
    Invoke-RestMethod -Uri $UserUri
    #Invoke-RestMethod -Uri $WorkerUri   
}

function Get-MiningResults {
    param (
        $KeyFile = "../keys.json"
    )
    # safe keys/addresses in json formatted file like
    <#
        {
        "btcApiKey":  "my-api-key",
        "ltcApiKey":  "my-api-key"
        }
    #>
    $keys = Get-Content $KeyFile | ConvertFrom-Json

    $nh = Get-NiceHashResults -Address $keys.nhAddr | Select-Object -ExpandProperty result | Select-Object -ExpandProperty stats | Select-Object -ExpandProperty balance
    $ltc = Get-LiteCoinResults -Key $keys.ltcApiKey | Select-Object -ExpandProperty user
    $xmr = Get-SupportXmrResults -Address $keys.xmrAddr
    $btc = Get-BitcoinComResults -Key $keys.btcApiKey

    $out = [ordered]@{
        "BTC" = $btc.bitcoinBalance
        "BCH" = $btc.bitcoinCashBalance
        "LTC" = $ltc.unpaid_rewards
        "XMR" = $xmr.amtDue
    }

    Write-Output (New-Object -TypeName psobject -Property $out) 
}


function Update-CSV {
    param($path,$keep)

    $csv = Get-ChildItem -Path $path -Filter "*.csv" -Recurse -File
    foreach($file in $csv) {
        $content = Import-Csv -Path $file.fullname | select -Last $keep
        Remove-Item -Path $file.fullname -ErrorAction SilentlyContinue
        $content | Export-Csv -Path $file.fullname -NoTypeInformation -NoClobber -Force 
    }

}