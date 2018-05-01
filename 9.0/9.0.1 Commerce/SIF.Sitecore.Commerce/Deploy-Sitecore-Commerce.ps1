#Requires -Version 3

# Hide progress bar to speed up installtion
$global:ProgressPreference = 'silentlyContinue'
Clear-Host

# Parameters
$prefix = "sc9"
$siteName = "$prefix.local"
$commerceSiteName = "$prefix.commerce"

$commerceSearchProvider = "SOLR"
$engineSdkPath = "c:/tmp/sitecore/engine_sdk"
$nugetPath = "c:/tmp/msbuild.microsoft.visualstudio.web.targets.14.0.0.3"
$password = "vagrant"
$siteHostHeader = "$prefix.local"
$solrInstallDir = "C:/tools/solr-6.6.2"
$solrUrl = "https://localhost:8983/solr"
$speZipPath = "c:/tmp/Sitecore PowerShell Extensions-4.7.2 for Sitecore 8.zip"
$sqlServer = "localhost"
$sxaZipPath = "c:/tmp/Sitecore Experience Accelerator 1.7 rev. 180410 for 9.0.zip"
$user = "vagrant"

# Import additional modules
$global:DEPLOYMENT_DIRECTORY = Split-Path $MyInvocation.MyCommand.Path
$modulesPath = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "Modules" )
if ($env:PSModulePath -notlike "*$modulesPath*") {
    $p = $env:PSModulePath + ";" + $modulesPath
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
}

$params = @{
    Path                                     = Resolve-Path '.\Configuration\Commerce\Master_SingleServer.json'

    # General configurations
    CommerceSearchProvider                   = $commerceSearchProvider
    RootCertFileName                         = "SitecoreRootCert"

    # SOLR
    SolrCorePrefix                           = $prefix
    SolrInstallDir                           = $solrInstallDir
    SolrSchemasDir                           = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SolrSchemas" )
    SolrServiceName                          = "SOLR"
    SolrUrl                                  = $solrUrl

    # Azure Search
    AzureSearchIndexPrefix                   = $prefix
    AzureSearchServiceName                   = ""
    AzureSearchAdminKey                      = ""
    AzureSearchQueryKey                      = ""

    # CM instance and XConnect settings
    SiteName                                 = $siteName
    SiteHostHeader                           = $siteHostHeader
    SiteInstallDir                           = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$prefix.local"
    XConnectInstallDir                       = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$prefix.xconnect"

    # SQL
    SqlCommerceServicesDbName                = "$($prefix)_SharedEnvironments"
    SqlCommerceServicesDbServer              = $sqlServer    #OR "SQLServerName\SQLInstanceName"
    SqlCommerceServicesGlobalDbName          = "$($prefix)_Global"
    SqlSitecoreCoreDbName                    = "$($prefix)_Core"
    SqlSitecoreDbServer                      = $sqlServer            #OR "SQLServerName\SQLInstanceName"

    # Commerce Services
    CommerceAuthoring                        = "$commerceSiteName-authoring"
    CommerceAuthoringCertificateDnsName      = "*.sc9.local"
    CommerceAuthoringCertificateName         = "all.sc9.local"
    CommerceAuthoringDir                     = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-authoring"
    CommerceAuthoringHostHeader              = "commerce-authoring.$siteName"
    CommerceAuthoringServicesPort            = "443"

    CommerceMinions                          = "$commerceSiteName-minions"
    CommerceMinionsCertificateDnsName        = "*.sc9.local"
    CommerceMinionsCertificateName           = "all.sc9.local"
    CommerceMinionsDir                       = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-minions"
    CommerceMinionsHostHeader                = "commerce-minions.$siteName"
    CommerceMinionsServicesPort              = "443"

    CommerceOps                              = "$commerceSiteName-ops"
    CommerceOpsCertificateDnsName            = "*.sc9.local"
    CommerceOpsCertificateName               = "all.sc9.local"
    CommerceOpsDir                           = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-ops"
    CommerceOpsHostHeader                    = "commerce-ops.$siteName"
    CommerceOpsServicesPort                  = "443"

    CommerceShops                            = "$commerceSiteName-shops"
    CommerceShopsCertificateDnsName          = "*.sc9.local"
    CommerceShopsCertificateName             = "all.sc9.local"
    CommerceShopsDir                         = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-shops"
    CommerceShopsHostHeader                  = "commerce-shops.$siteName"
    CommerceShopsServicesPort                = "443"

    SitecoreIdentityServer                   = "$commerceSiteName-identity"
    SitecoreIdentityServerCertificateDnsName = "*.sc9.local"
    SitecoreIdentityServerCertificateName    = "all.sc9.local"
    SitecoreIdentityServerDir                = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-identity"
    SitecoreIdentityServerHostHeader         = "identity.$siteName"
    SitecoreIdentityServerServicesPort       = "443"

    SitecoreBizFx                            = "$commerceSiteName-bizfx"
    SitecoreBizFxCertificateDnsName          = "*.sc9.local"
    SitecoreBizFxCertificateName             = "all.sc9.local"
    SitecoreBizFxDir                         = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$commerceSiteName-bizfx"
    SitecoreBizFxHostHeader                  = "bizfx.$siteName"
    SitecoreBizFxServicesPort                = "443"

    CommerceServicesPrefix                   = $prefix
    CommerceEngineCertificatePath            = "c:\certificates\$commerceSiteName.crt"
    CommerceEngineCertificateName            = $commerceSiteName

    # Packages
    PackageAdventureWorksImagesPath          = Resolve-Path -Path "..\Adventure Works Images.zip"
    PackageCEConnectPath                     = Resolve-Path -Path "..\Sitecore.Commerce.Engine.Connect*.update"
    PackageCommerceConnectPath               = Resolve-Path -Path "..\Sitecore Commerce Connect*.zip"
    PackageCommerceEngineDacPacPath          = "$engineSdkPath\Sitecore.Commerce.Engine.DB.dacpac"
    PackageHabitatImagesPath                 = Resolve-Path -Path "..\Sitecore.Commerce.Habitat.Images-*.zip"
    PackagePowerShellExtensionsPath          = $speZipPath
    PackageSitecoreBizFxServicesContentDir   = Resolve-Path -Path "..\bizfx"
    PackageSitecoreCommerceEnginePath        = Resolve-Path -Path "..\Sitecore.Commerce.Engine.2.*.zip"
    PackageSitecoreIdentityServerPath        = Resolve-Path -Path "..\Sitecore.IdentityServer.1.*.zip"
    PackageSXACommercePath                   = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator 1.*.zip"
    PackageSXAPath                           = $sxaZipPath
    PackageSXAStorefrontCatalogPath          = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Habitat Catalog*.zip"
    PackageSXAStorefrontPath                 = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Storefront 1.*.zip"
    PackageSXAStorefrontThemePath            = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Storefront Themes*.zip"

    # Tools
    ToolsSiteUtilitiesDir                    = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SiteUtilityPages" )
    ToolsMergeToolPath                       = "$nugetPath\tools\VSToolsPath\Web\Microsoft.Web.XmlTransform.dll"

    # Accounts
    SitecoreUsername                         = "sitecore\admin"
    SitecoreUserPassword                     = "b"

    UserAccount                              = @{
        Domain   = $Env:COMPUTERNAME
        UserName = $user
        Password = $password
    }

    BraintreeAccount                         = @{
        MerchantId = ''
        PublicKey  = ''
        PrivateKey = ''
    }
}

### --------- HACK IGNORE UNTRUSTED CERT IN PS -----------------------------------------------------
# if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
#     $certCallback = @"
#     using System;
#     using System.Net;
#     using System.Net.Security;
#     using System.Security.Cryptography.X509Certificates;
#     public class ServerCertificateValidationCallback
#     {
#         public static void Ignore()
#         {
#             if(ServicePointManager.ServerCertificateValidationCallback ==null)
#             {
#                 ServicePointManager.ServerCertificateValidationCallback +=
#                     delegate
#                     (
#                         Object obj,
#                         X509Certificate certificate,
#                         X509Chain chain,
#                         SslPolicyErrors errors
#                     )
#                     {
#                         return true;
#                     };
#             }
#         }
#     }
# "@
#     Add-Type $certCallback
# }
# [ServerCertificateValidationCallback]::Ignore()
### --------------------------------------------------------------

if ($commerceSearchProvider -eq "SOLR") {
    Install-SitecoreConfiguration @params
}
elseif ($commerceSearchProvider -eq "AZURE") {
    Install-SitecoreConfiguration @params -Skip InstallSolrCores
}