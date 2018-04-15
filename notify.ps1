function Send-MailJetMail {
	param(
        [string]$Sender = "notification@tomt.it",
        [string]$Recipient,
        [string]$Subject,
        [string]$Text,
        [string]$ApiKey,
        [string]$Secret
    )
    $body = @{
        Messages = @(@{
            From = @{
                Email = $sender
                Name = "Notification"
            }
            To = @(@{
                Email = $recipient
                Name = ""
            })
            Subject = $subject
            TextPart = $text
        })
    
    } | ConvertTo-Json -Depth 4
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiKey,$Secret)))
	$Result = Invoke-RestMethod -Uri "https://api.mailjet.com/v3.1/send" -ContentType "application/json" -body $body -Method POST -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UseBasicParsing
    if($Result) {
        $Result.Messages
    }
}

function Test-Online {
    param($hostname)
    $url = -join("http://",$hostname)
    $curl = curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s $url
    if($curl) {
        return 1
    } else {
        return 0
    }
}

# Get Keys
$keys = Get-Content keys.json | ConvertFrom-Json

$status = Get-Content raspi -ErrorAction SilentlyContinue

switch($status) {
    0 {
        if (Test-Online 6slsw42zq5n76gt7.onion) {
            "Was offline, now online"
            Send-MailJetMail -Recipient tom@uclab.eu -Subject "Raspi Online!" -ApiKey $keys.MailApiKey -Sender $keys.MailSecret
            Set-Content -Value 1 -Path raspi -Force
        } else {
            "Was offline, now offline"
            Set-Content -Value 0 -Path raspi -Force
        }

    }
    1 {
        if (Test-Online 6slsw42zq5n76gt7.onion) {
            "Was online, now online"
            Set-Content -Value 1 -Path raspi -Force
        } else {
            "Was online, now offline"
            Send-MailJetMail -Recipient tom@uclab.eu -Subject "Raspi Offline!" -ApiKey $keys.MailApiKey -Sender $keys.MailSecret
            Set-Content -Value 0 -Path raspi -Force
        }
    }
}
