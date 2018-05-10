<#
.SYNOPSIS
    Installs the Sitecore Commerce Platform to the machine where this script is executed.
.DESCRIPTION
    Installs the Sitecore Commerce Platform to the machine where this script is executed.
    First make sure you have installed all the pre-requisites for SC9 from the Installation Guide
    Then make sure you walk through 2.2 Download the Sitecore XC release package and prerequisites of the SC9 Installation Guide, before running this script  
.EXAMPLE(S)
    C:\PS> Deploy-Sitecore-Commerce.ps1
.NOTES
    Author(s):  Alex Smagin
                Robbert Hock
#>

#Requires -Version 3

#parameters
param(
    [string]$Prefix = "sc9",
    [string]$SiteName = "$Prefix.local",	
    [string]$SiteHostHeader = "$Prefix.local",	
    [string]$SqlDbPrefix = $Prefix,
    [string]$CommerceSearchProvider = "SOLR",
    [string]$CommerceSiteName = "$Prefix.commerce",
    [string]$Drive = $($Env:SYSTEMDRIVE),
    [string]$XConnectSiteHostHeaderName = "$($Prefix).local.xconnect",
    [string]$SolrUrl = "https://localhost:8983/solr",
    [string]$SolrInstallDir = "C:/tools/solr-6.6.2",
    [string]$SolrService = "solr-6.6.2",
    [string]$SqlServer = "localhost",
    [string]$SitecoreUsername = "sitecore\admin",
    [string]$SitecoreUserPassword = "b",
    [string]$CommerceServerUserName = "CSRuntimeUser",
    [string]$CommerceServerUserPassword = "vagrant"
)

# Hide progress bar to speed up installation
$global:ProgressPreference = 'silentlyContinue'
Clear-Host

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
    CommerceSearchProvider                   = $CommerceSearchProvider
    RootCertFileName                         = "SitecoreRootCert"

    # SOLR
    SolrCorePrefix                           = $Prefix
    SolrInstallDir                           = $SolrInstallDir
    SolrSchemasDir                           = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SolrSchemas" )
    SolrServiceName                          = $SolrService
    SolrUrl                                  = $SolrUrl

    # Azure Search
    AzureSearchIndexPrefix                   = $Prefix
    AzureSearchServiceName                   = ""
    AzureSearchAdminKey                      = ""
    AzureSearchQueryKey                      = ""

    # CM instance and XConnect settings
    SiteName                                 = $SiteName
    SiteHostHeader                           = $siteHostHeader
    SiteInstallDir                           = "$($Drive)\inetpub\wwwroot\$Prefix.local"
    XConnectInstallDir                       = "$($Drive)\inetpub\wwwroot\$Prefix.xconnect"

    # SQL
    SqlCommerceServicesDbName                = "$($Prefix)_SitecoreCommerce_SharedEnvironments"
    SqlCommerceServicesDbServer              = $SqlServer    #OR "SQLServerName\SQLInstanceName"
    SqlCommerceServicesGlobalDbName          = "$($Prefix)_SitecoreCommerce_Global"
    SqlSitecoreCoreDbName                    = "$($Prefix)_Core"
    SqlSitecoreDbServer                      = $SqlServer    #OR "SQLServerName\SQLInstanceName"

    # Commerce Services
    CommerceAuthoring                        = "$CommerceSiteName-authoring"
    CommerceAuthoringCertificateDnsName      = "*.$Prefix.local"
    CommerceAuthoringCertificateName         = "all.$Prefix.local"
    CommerceAuthoringDir                     = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-authoring"
    CommerceAuthoringHostHeader              = "commerce-authoring.$SiteName"
    CommerceAuthoringServicesPort            = "443"

    CommerceMinions                          = "$CommerceSiteName-minions"
    CommerceMinionsCertificateDnsName        = "*.$Prefix.local"
    CommerceMinionsCertificateName           = "all.$Prefix.local"
    CommerceMinionsDir                       = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-minions"
    CommerceMinionsHostHeader                = "commerce-minions.$SiteName"
    CommerceMinionsServicesPort              = "443"

    CommerceOps                              = "$CommerceSiteName-ops"
    CommerceOpsCertificateDnsName            = "*.$Prefix.local"
    CommerceOpsCertificateName               = "all.$Prefix.local"
    CommerceOpsDir                           = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-ops"
    CommerceOpsHostHeader                    = "commerce-ops.$SiteName"
    CommerceOpsServicesPort                  = "443"

    CommerceShops                            = "$CommerceSiteName-shops"
    CommerceShopsCertificateDnsName          = "*.$Prefix.local"
    CommerceShopsCertificateName             = "all.$Prefix.local"
    CommerceShopsDir                         = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-shops"
    CommerceShopsHostHeader                  = "commerce-shops.$SiteName"
    CommerceShopsServicesPort                = "443"

    SitecoreIdentityServer                   = "$CommerceSiteName-identity"
    SitecoreIdentityServerCertificateDnsName = "*.$Prefix.local"
    SitecoreIdentityServerCertificateName    = "all.$Prefix.local"
    SitecoreIdentityServerDir                = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-identity"
    SitecoreIdentityServerHostHeader         = "identity.$SiteName"
    SitecoreIdentityServerServicesPort       = "443"

    SitecoreBizFx                            = "$CommerceSiteName-bizfx"
    SitecoreBizFxCertificateDnsName          = "*.$Prefix.local"
    SitecoreBizFxCertificateName             = "all.$Prefix.local"
    SitecoreBizFxDir                         = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$CommerceSiteName-bizfx"
    SitecoreBizFxHostHeader                  = "bizfx.$SiteName"
    SitecoreBizFxServicesPort                = "443"

    CommerceServicesPrefix                   = $Prefix
    CommerceEngineCertificatePath            = "c:\certificates\$CommerceSiteName.crt"
    CommerceEngineCertificateName            = $CommerceSiteName

    # Packages
    PackageAdventureWorksImagesPath          = Resolve-Path -Path "..\Adventure Works Images.zip"
    PackageCEConnectPath                     = Resolve-Path -Path "..\Sitecore.Commerce.Engine.Connect*.update"
    PackageCommerceConnectPath               = Resolve-Path -Path "..\Sitecore Commerce Connect*.zip"
    PackageCommerceEngineDacPacPath          = Resolve-Path -Path "..\Sitecore.Commerce.Engine.SDK.2.1.10\Sitecore.Commerce.Engine.DB.dacpac"
    PackageHabitatImagesPath                 = Resolve-Path -Path "..\Sitecore.Commerce.Habitat.Images-*.zip"
    PackagePowerShellExtensionsPath          = Resolve-Path -Path "..\Sitecore PowerShell Extensions-4.7.2 for Sitecore 8.zip"
    PackageSitecoreBizFxServicesContentDir   = Resolve-Path -Path "..\Sitecore.BizFX.1.1.9"
    PackageSitecoreCommerceEnginePath        = Resolve-Path -Path "..\Sitecore.Commerce.Engine.2.*.zip"
    PackageSitecoreIdentityServerPath        = Resolve-Path -Path "..\Sitecore.IdentityServer.1.*.zip"
    PackageSXACommercePath                   = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator 1.*.zip"
    PackageSXAPath                           = Resolve-Path -Path "..\Sitecore Experience Accelerator 1.7 rev. 180410 for 9.0.zip"
    PackageSXAStorefrontCatalogPath          = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Habitat Catalog*.zip"
    PackageSXAStorefrontPath                 = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Storefront 1.*.zip"
    PackageSXAStorefrontThemePath            = Resolve-Path -Path "..\Sitecore Commerce Experience Accelerator Storefront Themes*.zip"

    # Tools
    ToolsSiteUtilitiesDir                    = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SiteUtilityPages" )
    ToolsMergeToolPath                       = Resolve-Path -Path "..\Microsoft.Web.XmlTransform.dll"

    # Accounts
    SitecoreUsername                         = $SitecoreUsername
    SitecoreUserPassword                     = $SitecoreUserPassword

    UserAccount                              = @{
        Domain   = $Env:COMPUTERNAME
        UserName = $CommerceServerUserName
        Password = $CommerceServerUserPassword
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