
Param(
    $DownloadFolder = "", #Defaults to .\assets\Downloads
    $CommerceAssetFolder = "" #Defaults to .\assets

)


$packagesToExtract = ('{"files":[
							   {
								   "name":  "SIF.Sitecore.Commerce",
								   "version":  "1.1.4"
							   },
							   {
								   "name":  "Sitecore.Commerce.Engine",
								   "version":  "2.1.55"
							   },
							   {
								   "name":  "Sitecore.BizFX",
								   "version":  "1.1.9"
							   },
							   {
								   "name":  "Sitecore.Commerce.Engine.SDK",
								   "version":  "2.1.10"
							   }
						   ]}') | ConvertFrom-Json
													   
if ($DownloadFolder -eq "" -or $DownloadFolder -eq $null) {
    $DownloadFolder = Join-Path "$PWD" "Downloads"
    if (!(Test-Path $DownloadFolder)) {
        New-Item -ItemType Directory -Force -Path $DownloadFolder
    }
}
if ($CommerceAssetFolder -eq "" -or $CommerceAssetFolder -eq $null) {
    $CommerceAssetFolder = Join-Path "$PWD" "assets"
}

Function Invoke-FetchSitecoreCredentials {
    #   Credit: https://jermdavis.wordpress.com/2017/11/27/downloading-stuff-from-dev-sitecore-net/
    $file = "dev.creds.xml"
 
    if (Test-Path ".\\$file") {
        $cred = Import-Clixml ".\\$file"
    }
    else {
        $cred = Get-Credential -Message "Enter your SDN download credentials:"
        $cred | Export-Clixml ".\\$file"
    }
 
    return $cred
}

Function Invoke-FetchDownloadAuthentication($cred) {
    #   Credit: https://jermdavis.wordpress.com/2017/11/27/downloading-stuff-from-dev-sitecore-net/

    $authUrl = "https://dev.sitecore.net/api/authorization"
 
    $pwd = $cred.GetNetworkCredential().Password
 
    $postParams = "{ ""username"":""$($cred.UserName)"", ""password"":""$pwd"" }"
 
    $authResponse = Invoke-WebRequest -Uri $authUrl -Method Post -ContentType "application/json;charset=UTF-8" -Body $postParams -SessionVariable webSession
    $authCookies = $webSession.Cookies.GetCookies("https://sitecore.net")
 
    $marketPlaceCookie = $authCookies["marketplace_login"]
 
    if ([String]::IsNullOrWhiteSpace($marketPlaceCookie)) {
        throw "Credentials appear invalid"
    }
 
    $devUrl = "https://dev.sitecore.net"
 
    $devResponse = Invoke-WebRequest -Uri $devUrl -WebSession $webSession
    $devCookies = $webSession.Cookies.GetCookies("https://dev.sitecore.net")
 
    $sessionCookie = $devCookies["ASP.Net_SessionId"]
 
    return "$marketPlaceCookie; $sessionCookie"
}

function Invoke-SitecoreFileDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Uri,
 
        [Parameter(Mandatory)]
        [string] $OutputFile,
 
        [string] $cookies
    )
    #   Credit: https://jermdavis.wordpress.com/2017/11/27/downloading-stuff-from-dev-sitecore-net/

    $webClient = New-Object System.Net.WebClient
 
    if (!([String]::IsNullOrWhiteSpace($cookies))) {
        $webClient.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
    }
 
    $data = New-Object psobject -Property @{Uri = $Uri; OutputFile = $OutputFile}
 
    $changed = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -MessageData $data -Action {
        Write-Progress -Activity "Downloading $($event.MessageData.Uri)" -Status "To $($event.MessageData.OutputFile)" -PercentComplete $eventArgs.ProgressPercentage
    }
 
    try {
        $handle = $webClient.DownloadFileAsync($Uri, $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputFile))
 
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 1000
        }
    }
    finally {
        Write-Progress -Activity "Downloading $Uri" -Completed
 
        Remove-Job $changed -Force
        Get-EventSubscriber | Where SourceObject -eq $webClient | Unregister-Event -Force
    }    
}
Function Invoke-SitecoreDownload {
    param(
        [string]$url,
        [string]$target
    )
 
    $cred = Invoke-FetchSitecoreCredentials
    $cookie = Invoke-FetchDownloadAuthentication $cred
 
    Invoke-SitecoreFileDownload -Uri $url -OutputFile $target -Cookies $cookie

}
Function Invoke-DownloadAndExtractAssets {
  
    
    $CommercePackageUrl = "https://dev.sitecore.net/~/media/F08E9950D0134D1DA325801057C96B35.ashx" #Your download url here
    $commercePackageFileName = "Sitecore.Commerce.2018.03-2.1.55.zip"
    $commercePackageDestination = $([io.path]::combine($DownloadFolder, $commercePackageFileName)).ToString()
    
    Write-Host "Saving $CommercePackageUrl to $commercePackageDestination - if required" -ForegroundColor Green
    if (!(Test-Path $commercePackageDestination)) {
        Invoke-SitecoreDownload $CommercePackageUrl $commercePackageDestination
    }
    

    $sxaPackageUrl = "https://dev.sitecore.net/~/media/573443081B494E2B9D83D3208B549E49.ashx"
    $sxaPackageDestination = $([io.path]::combine($CommerceAssetFolder, "Sitecore Experience Accelerator 1.7 rev. 180410 for 9.0.zip"))
    if (!(Test-Path $sxaPackageDestination)) {
        Invoke-SitecoreDownload $sxaPackageUrl $sxaPackageDestination
    }
   
    $spePackageUrl = "https://marketplace.sitecore.net/services/~/download/3D2CADDAB4A34CEFB1CFD3DD86D198D5.ashx?data=Sitecore%20PowerShell%20Extensions-4.7.2%20for%20Sitecore%208&itemId=6aaea046-83af-4ef1-ab91-87f5f9c1aa57"
    $spePackageDestination = $([io.path]::combine($CommerceAssetFolder, "Sitecore PowerShell Extensions-4.7.2 for Sitecore 8.zip"))
   
    if (!(Test-Path $spePackageDestination)) {
        Invoke-SitecoreDownload $spePackageUrl $spePackageDestination
    }

    $msbuildNuGetUrl = "https://www.nuget.org/api/v2/package/MSBuild.Microsoft.VisualStudio.Web.targets/14.0.0.3"
    $msbuildNuGetPackageFileName = "msbuild.microsoft.visualstudio.web.targets.14.0.0.3.nupkg"
    $msbuildNuGetPackageDestination = $([io.path]::combine($DownloadFolder, $msbuildNuGetPackageFileName))
    
    Write-Host "Saving $msbuildNuGetUrl to $msbuildNuGetPackageDestination - if required" -ForegroundColor Green
    if (!(Test-Path $msbuildNuGetPackageDestination)) {
        Invoke-WebRequest  -Uri $msbuildNuGetUrl -OutFile $msbuildNuGetPackageDestination
        #Start-BitsTransfer -source $msbuildNuGetUrl -Destination $msbuildNuGetPackageDestination
    }
    $aspnetCoreGetUrl = "https://aka.ms/dotnetcore-2-windowshosting"
    $aspnetCoreFileName = "DotNetCore.2.0.5-WindowsHosting.exe"
    $aspnetPackageDestination = $([io.path]::combine($DownloadFolder, $aspnetCoreFileName))
    
    Write-Host "Saving $aspnetCoreGetUrl to $aspnetPackageDestination - if required" -ForegroundColor Green
    if (!(Test-Path $aspnetPackageDestination)) {
        Start-BitsTransfer -source $aspnetCoreGetUrl -Destination $aspnetPackageDestination
    }
    
    $netCoreSDKUrl = "https://download.microsoft.com/download/0/F/D/0FD852A4-7EA1-4E2A-983A-0484AC19B92C/dotnet-sdk-2.0.0-win-x64.exe"
    $netCoreSDKFileName = "dotnet-sdk-2.0.0-win-x64.exe"
    $netCoreSDKPackageDestination = $([io.path]::combine($DownloadFolder, $netCoreSDKFileName))
    
    Write-Host "Saving $netCoreSDKUrl to $netCoreSDKPackageDestination - if required" -ForegroundColor Green
    if (!(Test-Path $netCoreSDKPackageDestination)) {
        Start-BitsTransfer -source $netCoreSDKUrl -Destination $netCoreSDKPackageDestination
    }
    
  
    Write-Host "Extracting to $($CommerceAssetFolder)"
    set-alias sz "$env:ProgramFiles\7-zip\7z.exe"
    sz x -o"$CommerceAssetFolder" $commercePackageDestination  -y -aoa
    
    foreach ($package in $packagesToExtract.files) {
                
        $extract = Join-Path $CommerceAssetFolder $($package.name + "." + $package.version + ".zip")
        $output = Join-Path $CommerceAssetFolder $($package.name + "." + $package.version)
              
           
        sz x -o"$($output)" $extract -r -y -aoa    
    }
    #Extract MSBuild nuget package
    $extract = $(Join-Path $DownloadFolder "msbuild.microsoft.visualstudio.web.targets.14.0.0.3.nupkg")
    $output = $(Join-Path $CommerceAssetFolder "msbuild.microsoft.visualstudio.web.targets.14.0.0.3")
    sz x -o"$($output)" $extract -r -y -aoa
    
}


Invoke-DownloadAndExtractAssets