# Deploying the BIG-IP VE in Azure - Auto Scale BIG-IP WAF (LTM + ASM) - VM Scale Set

[![Slack Status](https://f5cloudsolutions.herokuapp.com/badge.svg)](https://f5cloudsolutions.herokuapp.com)
[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates.svg)](https://github.com/f5networks/f5-azure-arm-templates/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates.svg)](https://github.com/f5networks/f5-azure-arm-templates/issues)

## Introduction

This solution uses an ARM template to launch the deployment of F5 BIG-IP LTM and ASM Virtual Edition (VE) instances in a Microsoft Azure VM Scale Set that is configured for auto scaling. Traffic flows from the Azure load balancer to the BIG-IP VE (cluster) and then to the application servers. The BIG-IP VE(s) are configured in single-NIC mode. As traffic increases or decreases, the number of BIG-IP VE LTM instances automatically increases or decreases accordingly.  Scaling thresholds are currently based on *network out* throughput. This solution is for BIG-IP LTM+ASM.

**Networking Stack Type:** This solution deploys into a new networking stack, which is created along with the solution.

## Prerequisites and configuration notes
  - **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See https://support.f5.com/csp/article/K2873 for details.
  - If you are deploying the BYOL template, you must have a valid BIG-IP license token.
  - See the **[Configuration Example](#config)** section for a configuration diagram and description for this solution.
  - See the important note about [optionally changing the BIG-IP Management port](#changing-the-big-ip-configuration-utility-gui-port).
  - This template supports service discovery.  See the [Service Discovery section](#service-discovery) for details.
  - This template requires service principal.  See the [Service Principal Setup section](#service-principal-authentication) for details.
  - This template has some optional post-deployment configuration.  See the [Post-Deployment Configuration section](#post-deployment-configuration) for details.
  - **Important**: After the template successfully deploys, you must log into one of the BIG-IP VEs to modify the Application Security Synchronization settings.  Log in to the BIG-IP VE, and then click **Security > Options > Synchronization > Application Security Synchronization**.  From the **Device Group** list, select **Sync**, and then click **Save**. This ensures any changes to the ASM security policy are synchronized to other devices in the cluster.


## Security
This ARM template downloads helper code to configure the BIG-IP system. If you want to verify the integrity of the template, you can open the template and ensure the following lines are present. See [Security Detail](#securitydetail) for the exact code.
In the *variables* section:
  - In the *verifyHash* variable: **script-signature** and then a hashed signature.
  - In the *installCloudLibs* variable: **tmsh load sys config merge file /config/verifyHash**.
  - In the *installCloudLibs* variable: ensure this includes **tmsh run cli script verifyHash /config/cloud/f5-cloud-libs.tar.gz**.


Additionally, F5 provides checksums for all of our supported templates. For instructions and the checksums to compare against, see https://devcentral.f5.com/codeshare/checksums-for-f5-supported-cft-and-arm-templates-on-github-1014.

## Supported BIG-IP versions
The following is a map that shows the available options for the template parameter **bigIpVersion** as it corresponds to the BIG-IP version itself. Only the latest version of BIG-IP VE is posted in the Azure Marketplace. For older versions, see downloads.f5.com.

| Azure BIG-IP Image Version | BIG-IP Version |
| --- | --- |
| 13.0.021 | 13.0.0 HF2 Build 2.10.1671 |
| 12.1.24 | 12.1.2 HF1 Build 1.34.271 |
| latest | This will select the latest BIG-IP version available |


## Supported instance types and hypervisors
  - For a list of supported Azure instance types for this solutions, see the **Azure instances for BIG-IP VE** section of https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/bigip-ve-setup-msft-azure-12-1-0/1.html#guid-71265d82-3a1a-43d2-bae5-892c184cc59b

  - For a list versions of the BIG-IP Virtual Edition (VE) and F5 licenses that are supported on specific hypervisors and Microsoft Azure, see https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ve-supported-hypervisor-matrix.html.

### Help
While this template has been created by F5 Networks, it is in the experimental directory and therefore has not completed full testing and is subject to change.  F5 Networks does not offer technical support for templates in the experimental directory. For supported templates, see the templates in the **supported** directory.

We encourage you to use our [Slack channel](https://f5cloudsolutions.herokuapp.com) for discussion and assistance on F5 ARM templates.  This channel is typically monitored Monday-Friday 9-5 PST by F5 employees who will offer best-effort support.


## Installation

You have three options for deploying this solution:
  - Using the Azure deploy buttons
  - Using [PowerShell](#powershell)
  - Using [CLI Tools](#cli)

### <a name="azure"></a>Azure deploy buttons

Use the appropriate button, depending on what type of BIG-IP licensing required:
   - **PAYG**: This allows you to use pay-as-you-go hourly billing. <br><a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FF5Networks%2Ff5-azure-arm-templates%2Fv3.3.2.0%2Fexperimental%2Fsolutions%2Fautoscale%2Fwaf%2Fnew_stack%2Fazuredeploy.json">
    <img src="http://azuredeploy.net/deploybutton.png"/></a><br><br>



### Template parameters

| Parameter | Required | Description |
| --- | --- | --- |
| vmScaleSetMinCount | Yes | The minimum (and default) number of BIG-IP VEs that will be deployed into the VM Scale Set. |
| vmScaleSetMaxCount | Yes | The maximum number of BIG-IP VEs that can be deployed into the VM Scale Set. |
| scaleOutThroughput | Yes | The percentage of 'Network Out' throughput that triggers a Scale Out event.  This is factored as a percentage of the F5 PAYG image bandwidth (Mbps) size you choose. |
| scaleInThroughput | Yes | The percentage of 'Network Out' throughput that triggers a Scale In event.  This is factored as a percentage of the F5 PAYG image bandwidth (Mbps) size you choose. |
| scaleTimeWindow | Yes | The time window required to trigger a scale event (in and out). This is used to determine the amount of time needed for a threshold to be breached, as well as to prevent excessive scaling events (flapping). |
| adminUsername | Yes | User name for the Virtual Machine. |
| adminPassword | Yes | Password to login to the Virtual Machine. |
| dnsLabel | Yes | Unique DNS Name for the Public IP address used to access the Virtual Machine |
| instanceType | Yes | Azure instance size of the Virtual Machine. |
| imageName | Yes | F5 SKU (IMAGE) you want to deploy. 'Best' is the only option because ASM is required. |
| bigIpVersion | Yes | F5 BIG-IP version you want to use. |
| licensedBandwidth | PAYG only: | The amount of licensed bandwidth (Mbps) you want the PAYG image to use. |
| vnetAddressPrefix | Yes | The start of the CIDR block the BIG-IP VEs use when creating the Vnet and subnets.  You MUST type just the first two octets of the /16 virtual network that will be created, for example '10.0', '10.100', 192.168'. |
| solutionDeploymentName | Yes | A unique name for this deployment. |
| applicationProtocols | Yes | The protocol(s) used by your application. |
| applicationAddress | Yes | The public IP address or DNS FQDN of the application that this WAF will protect. |
| applicationServiceFqdn | Yes | If you are deploying in front of an Azure App Service, the FQDN of the public application. |
| applicationPort | Yes | If you are deploying an HTTP application, the port on which your service listens for unencrypted traffic. This field is not required when deploying HTTPS only. |
| applicationSecurePort | Yes | If you are deploying an HTTPS application, the port on which your service listens for encrypted traffic. This field is not required when deploying HTTP only. |
| sslCert | Yes | The SSL certificate .pfx file corresponding to public facing virtual server. |
| sslPswd | Yes | The SSL certificate .pfx password corresponding to the certificate you entered. |
| applicationType | Yes | Is your application running on a Linux OS or a Windows OS? |
| blockingLevel | Yes | Select how aggressive you want the blocking level of this WAF.  Remember that the more aggressive the blocking level, the more potential there is for false-positives that the WAF might detect. Select Custom to specify your own security policy. |
| customPolicy | Yes | Specify the publicly available URL of a custom ASM security policy in XML format. This policy will be applied in place of the standard High/Medium/Low policy. |
| tenantId | Yes | Your Azure service principal application tenant ID. |
| clientId | Yes | Your Azure service principal application client ID. |
| servicePrincipalSecret | Yes | Your Azure service principal application secret. |
| notificationEmail | Yes | If you would like email notifications on scale events please specify an email address, otherwise leave the parameter as 'OPTIONAL'. |
| ntpServer | Yes | If you would like to change the NTP server the BIG-IP uses then replace the default ntp server with your choice. |
| timeZone | Yes | If you would like to change the time zone the BIG-IP uses then enter your choice. This is in the format of the Olson timezone string from /usr/share/zoneinfo, such as UTC, US/Central or Europe/London. |
| restrictedSrcAddress | Yes | This field restricts management access to a specific network or address. Enter an IP address or address range in CIDR notation, or asterisk for all sources |
| tagValues | Yes | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |


### <a name="powershell"></a>PowerShell Script Example

```powershell
## Script parameters being asked for below match to parameters in the azuredeploy.json file, otherwise pointing to the ##
## azuredeploy.parameters.json file for values to use.  Some options below are mandatory, some(such as region) can     ##
## be supplied inline when running this script but if they aren't then the default will be used as specificed below.   ##
## Example Command: .\Deploy_via_PS.ps1 -licenseType PAYG -licensedBandwidth 200m -vmScaleSetMinCount 2 -vmScaleSetMaxCount 4 -scaleOutThroughput 90 -scaleInThroughput 10 -scaleTimeWindow 10 -adminUsername azureuser -adminPassword <value> -dnsLabel <value> -instanceType Standard_DS2_v2 -imageName Best -bigIpVersion 13.0.021 -vnetAddressPrefix 10.0 -solutionDeploymentName <value> -applicationProtocols http-https -applicationAddress <value> -applicationServiceFqdn NOT_SPECIFIED -applicationPort 80 -applicationSecurePort 443 -sslCert NOT_SPECIFIED -sslPswd NOT_SPECIFIED -applicationType Linux -blockingLevel medium -customPolicy NOT_SPECIFIED -tenantId <value> -clientId <value> -servicePrincipalSecret <value> -notificationEmail OPTIONAL -ntpServer 0.pool.ntp.org -timeZone UTC -restrictedSrcAddress "*" -resourceGroupName <value>

param(
  [string] [Parameter(Mandatory=$True)] $licenseType,
  [string] $licensedBandwidth = $(if($licenseType -eq "PAYG") { Read-Host -prompt "licensedBandwidth"}),

  [string] [Parameter(Mandatory=$True)] $vmScaleSetMinCount,
  [string] [Parameter(Mandatory=$True)] $vmScaleSetMaxCount,
  [string] [Parameter(Mandatory=$True)] $scaleOutThroughput,
  [string] [Parameter(Mandatory=$True)] $scaleInThroughput,
  [string] [Parameter(Mandatory=$True)] $scaleTimeWindow,
  [string] [Parameter(Mandatory=$True)] $adminUsername,
  [string] [Parameter(Mandatory=$True)] $adminPassword,
  [string] [Parameter(Mandatory=$True)] $dnsLabel,
  [string] [Parameter(Mandatory=$True)] $instanceType,
  [string] [Parameter(Mandatory=$True)] $imageName,
  [string] [Parameter(Mandatory=$True)] $bigIpVersion,
  [string] [Parameter(Mandatory=$True)] $vnetAddressPrefix,
  [string] [Parameter(Mandatory=$True)] $solutionDeploymentName,
  [string] [Parameter(Mandatory=$True)] $applicationProtocols,
  [string] [Parameter(Mandatory=$True)] $applicationAddress,
  [string] [Parameter(Mandatory=$True)] $applicationServiceFqdn,
  [string] [Parameter(Mandatory=$True)] $applicationPort,
  [string] [Parameter(Mandatory=$True)] $applicationSecurePort,
  [string] [Parameter(Mandatory=$True)] $sslCert,
  [string] [Parameter(Mandatory=$True)] $sslPswd,
  [string] [Parameter(Mandatory=$True)] $applicationType,
  [string] [Parameter(Mandatory=$True)] $blockingLevel,
  [string] [Parameter(Mandatory=$True)] $customPolicy,
  [string] [Parameter(Mandatory=$True)] $tenantId,
  [string] [Parameter(Mandatory=$True)] $clientId,
  [string] [Parameter(Mandatory=$True)] $servicePrincipalSecret,
  [string] [Parameter(Mandatory=$True)] $notificationEmail,
  [string] [Parameter(Mandatory=$True)] $ntpServer,
  [string] [Parameter(Mandatory=$True)] $timeZone,
  [string] $restrictedSrcAddress = "*",
  [string] [Parameter(Mandatory=$True)] $resourceGroupName,
  [string] $region = "West US",
  [string] $templateFilePath = "azuredeploy.json",
  [string] $parametersFilePath = "azuredeploy.parameters.json"
)

Write-Host "Disclaimer: Scripting to Deploy F5 Solution templates into Cloud Environments are provided as examples. They will be treated as best effort for issues that occur, feedback is encouraged." -foregroundcolor green
Start-Sleep -s 3

# Connect to Azure, right now it is only interactive login
try {
    Write-Host "Checking if already logged in!"
    Get-AzureRmSubscription | Out-Null
    Write-Host "Already logged in, continuing..."
    }
    Catch {
    Write-Host "Not logged in, please login..."
    Login-AzureRmAccount
    }

# Create Resource Group for ARM Deployment
New-AzureRmResourceGroup -Name $resourceGroupName -Location "$region"

# Create Arm Deployment
$pwd = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$sps = ConvertTo-SecureString -String $servicePrincipalSecret -AsPlainText -Force
$sslpwd = ConvertTo-SecureString -String $sslPswd -AsPlainText -Force
$deployment = New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose -vmScaleSetMinCount "$vmScaleSetMinCount" -vmScaleSetMaxCount "$vmScaleSetMaxCount" -scaleOutThroughput "$scaleOutThroughput" -scaleInThroughput "$scaleInThroughput" -scaleTimeWindow "$scaleTimeWindow" -adminUsername "$adminUsername" -adminPassword $pwd -dnsLabel "$dnsLabel" -instanceType "$instanceType" -imageName "$imageName" -bigIpVersion "$bigIpVersion" -vnetAddressPrefix "$vnetAddressPrefix" -solutionDeploymentName "$solutionDeploymentName" -applicationProtocols "$applicationProtocols" -applicationAddress "$applicationAddress" -applicationServiceFqdn "$applicationServiceFqdn" -applicationPort "$applicationPort" -applicationSecurePort "$applicationSecurePort" -sslCert "$sslCert" -sslPswd $sslpwd -applicationType "$applicationType" -blockingLevel "$blockingLevel" -customPolicy "$customPolicy" -tenantId "$tenantId" -clientId "$clientId" -servicePrincipalSecret $sps -notificationEmail "$notificationEmail" -ntpServer "$ntpServer" -timeZone "$timeZone" -restrictedSrcAddress "$restrictedSrcAddress"  -licensedBandwidth "$licensedBandwidth"

# Print Output of Deployment to Console
$deployment
```

=======

### <a name="cli"></a>Azure CLI(1.0) Script Example

```bash
#!/bin/bash

## Bash Script to deploy an F5 ARM template into Azure, using azure cli 1.0 ##
## Example Command: ./deploy_via_bash.sh --licenseType PAYG --licensedBandwidth 200m --vmScaleSetMinCount 2 --vmScaleSetMaxCount 4 --scaleOutThroughput 90 --scaleInThroughput 10 --scaleTimeWindow 10 --adminUsername azureuser --adminPassword <value> --dnsLabel <value> --instanceType Standard_DS2_v2 --imageName Best --bigIpVersion 13.0.021 --vnetAddressPrefix 10.0 --solutionDeploymentName <value> --applicationProtocols http-https --applicationAddress <value> --applicationServiceFqdn NOT_SPECIFIED --applicationPort 80 --applicationSecurePort 443 --sslCert NOT_SPECIFIED --sslPswd NOT_SPECIFIED --applicationType Linux --blockingLevel medium --customPolicy NOT_SPECIFIED --tenantId <value> --clientId <value> --servicePrincipalSecret <value> --notificationEmail OPTIONAL --ntpServer 0.pool.ntp.org --timeZone UTC --restrictedSrcAddress "*" --resourceGroupName <value> --azureLoginUser <value> --azureLoginPassword <value>

# Assign Script Parameters and Define Variables
# Specify static items below, change these as needed or make them parameters
region="westus"
restrictedSrcAddress="*"
tagValues='{"application":"APP","environment":"ENV","group":"GROUP","owner":"OWNER","cost":"COST"}'

# Parse the command line arguments, primarily checking full params as short params are just placeholders
while [[ $# -gt 1 ]]; do
    case "$1" in
        --resourceGroupName)
            resourceGroupName=$2
            shift 2;;
        --azureLoginUser)
            azureLoginUser=$2
            shift 2;;
        --azureLoginPassword)
            azureLoginPassword=$2
            shift 2;;
        --licenseType)
            licenseType=$2
            shift 2;;
        --licensedBandwidth)
            licensedBandwidth=$2
            shift 2;;
        --licenseKey1)
            licenseKey1=$2
            shift 2;;
        --vmScaleSetMinCount)
            vmScaleSetMinCount=$2
            shift 2;;
        --vmScaleSetMaxCount)
            vmScaleSetMaxCount=$2
            shift 2;;
        --scaleOutThroughput)
            scaleOutThroughput=$2
            shift 2;;
        --scaleInThroughput)
            scaleInThroughput=$2
            shift 2;;
        --scaleTimeWindow)
            scaleTimeWindow=$2
            shift 2;;
        --adminUsername)
            adminUsername=$2
            shift 2;;
        --adminPassword)
            adminPassword=$2
            shift 2;;
        --dnsLabel)
            dnsLabel=$2
            shift 2;;
        --instanceType)
            instanceType=$2
            shift 2;;
        --imageName)
            imageName=$2
            shift 2;;
        --bigIpVersion)
            bigIpVersion=$2
            shift 2;;
        --vnetAddressPrefix)
            vnetAddressPrefix=$2
            shift 2;;
        --solutionDeploymentName)
            solutionDeploymentName=$2
            shift 2;;
        --applicationProtocols)
            applicationProtocols=$2
            shift 2;;
        --applicationAddress)
            applicationAddress=$2
            shift 2;;
        --applicationServiceFqdn)
            applicationServiceFqdn=$2
            shift 2;;
        --applicationPort)
            applicationPort=$2
            shift 2;;
        --applicationSecurePort)
            applicationSecurePort=$2
            shift 2;;
        --sslCert)
            sslCert=$2
            shift 2;;
        --sslPswd)
            sslPswd=$2
            shift 2;;
        --applicationType)
            applicationType=$2
            shift 2;;
        --blockingLevel)
            blockingLevel=$2
            shift 2;;
        --customPolicy)
            customPolicy=$2
            shift 2;;
        --tenantId)
            tenantId=$2
            shift 2;;
        --clientId)
            clientId=$2
            shift 2;;
        --servicePrincipalSecret)
            servicePrincipalSecret=$2
            shift 2;;
        --notificationEmail)
            notificationEmail=$2
            shift 2;;
        --ntpServer)
            ntpServer=$2
            shift 2;;
        --timeZone)
            timeZone=$2
            shift 2;;
        --restrictedSrcAddress)
            restrictedSrcAddress=$2
            shift 2;;
        --)
            shift
            break;;
    esac
done

#If a required parameter is not passed, the script will prompt for it below
required_variables="vmScaleSetMinCount vmScaleSetMaxCount scaleOutThroughput scaleInThroughput scaleTimeWindow adminUsername adminPassword dnsLabel instanceType imageName bigIpVersion vnetAddressPrefix solutionDeploymentName applicationProtocols applicationAddress applicationServiceFqdn applicationPort applicationSecurePort sslCert sslPswd applicationType blockingLevel customPolicy tenantId clientId servicePrincipalSecret notificationEmail ntpServer timeZone resourceGroupName licenseType "
for variable in $required_variables
        do
        if [ -z ${!variable} ] ; then
                read -p "Please enter value for $variable:" $variable
        fi
done

# Prompt for licensed bandwidth if not supplied and PAYG is selected
if [ $licenseType == "PAYG" ]; then
    if [ -z $licensedBandwidth ] ; then
            read -p "Please enter value for licensedBandwidth:" licensedBandwidth
    fi
    template_file="./azuredeploy.json"
    parameter_file="./azuredeploy.parameters.json"
fi

echo "Disclaimer: Scripting to Deploy F5 Solution templates into Cloud Environments are provided as examples. They will be treated as best effort for issues that occur, feedback is encouraged."
sleep 3

# Login to Azure, for simplicity in this example using username and password supplied as script arguments --azureLoginUser and --azureLoginPassword
# Perform Check to see if already logged in
azure account show > /dev/null 2>&1
if [[ $? != 0 ]] ; then
        azure login -u $azureLoginUser -p $azureLoginPassword
fi

# Switch to ARM mode
azure config mode arm

# Create ARM Group
azure group create -n $resourceGroupName -l $region

# Deploy ARM Template, right now cannot specify parameter file AND parameters inline via Azure CLI,
azure group deployment create -f $template_file -g $resourceGroupName -n $resourceGroupName -p "{\"vmScaleSetMinCount\":{\"value\":$vmScaleSetMinCount},\"vmScaleSetMaxCount\":{\"value\":$vmScaleSetMaxCount},\"scaleOutThroughput\":{\"value\":$scaleOutThroughput},\"scaleInThroughput\":{\"value\":$scaleInThroughput},\"scaleTimeWindow\":{\"value\":$scaleTimeWindow},\"adminUsername\":{\"value\":\"$adminUsername\"},\"adminPassword\":{\"value\":\"$adminPassword\"},\"dnsLabel\":{\"value\":\"$dnsLabel\"},\"instanceType\":{\"value\":\"$instanceType\"},\"imageName\":{\"value\":\"$imageName\"},\"bigIpVersion\":{\"value\":\"$bigIpVersion\"},\"vnetAddressPrefix\":{\"value\":\"$vnetAddressPrefix\"},\"solutionDeploymentName\":{\"value\":\"$solutionDeploymentName\"},\"applicationProtocols\":{\"value\":\"$applicationProtocols\"},\"applicationAddress\":{\"value\":\"$applicationAddress\"},\"applicationServiceFqdn\":{\"value\":\"$applicationServiceFqdn\"},\"applicationPort\":{\"value\":\"$applicationPort\"},\"applicationSecurePort\":{\"value\":\"$applicationSecurePort\"},\"sslCert\":{\"value\":\"$sslCert\"},\"sslPswd\":{\"value\":\"$sslPswd\"},\"applicationType\":{\"value\":\"$applicationType\"},\"blockingLevel\":{\"value\":\"$blockingLevel\"},\"customPolicy\":{\"value\":\"$customPolicy\"},\"tenantId\":{\"value\":\"$tenantId\"},\"clientId\":{\"value\":\"$clientId\"},\"servicePrincipalSecret\":{\"value\":\"$servicePrincipalSecret\"},\"notificationEmail\":{\"value\":\"$notificationEmail\"},\"ntpServer\":{\"value\":\"$ntpServer\"},\"timeZone\":{\"value\":\"$timeZone\"},\"restrictedSrcAddress\":{\"value\":\"$restrictedSrcAddress\"},\"tagValues\":{\"value\":$tagValues},\"licensedBandwidth\":{\"value\":\"$licensedBandwidth\"}}"
```

## Configuration Example <a name="config">

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE appliance is through an Azure Load Balancer. The Azure Load Balancer processes both management and data plane traffic into the BIG-IP VEs, which then distribute the traffic to web/application servers according to normal F5 patterns.

![Configuration Example](images/azure-example-diagram.png)

## Post-Deployment Configuration
This solution deploys an ARM template that fully configures BIG-IP VE(s) and handles clustering (DSC) and Azure creation of objects needed for management of those BIG-IP VEs.  However, once deployed the assumption is configuration will be performed on the BIG-IP VE(s) to create virtual servers, pools, and other objects used for processing application traffic.  Because that information is unknown at deployment time, ensure the following tasks are done for each unique service to allow traffic to reach the BIG-IP(s) in the VM Scale Set.

### Post-deployment tasks(example application on port 443)
  1. Add a "Health Probe" to the ALB (Azure Load Balancer) for port 443, you can choose TCP or HTTP depending on your needs.  This queries each BIG-IP at that port to determine if it is available for traffic.
  2. Add a "Load Balancing Rule" to the ALB where the port is 443 and the backend port is also 443 (assuming you are using same port on the BIG-IP), make sure the backend pool is selected (there should only be one backend pool which was created and is managed by the VM Scale set)
  3. Add an "Inbound Security Rule" to the Network Security Group (NSG) for port 443 as the NSG is added to the subnet where the BIG-IP VE(s) are deployed - You could optionally just remove the NSG from the subnet as the VM Scale Set is fronted by the ALB.

### Additional Optional Configuration Items
Here are some post-deployment options that are entirely optional but could be useful based on your needs.

#### BIG-IP Lifecycle Management
As new BIG-IP versions are released, existing VM scale sets can be upgraded to use those new images. In an existing implementation, we assume you have created different types of BIG-IP configuration objects (such as virtual servers, pools, and monitors), and you want to retain this BIG-IP configuration after an upgrade. This section describes the process of upgrading and retaining the configuration.

When this ARM template was initially deployed, a storage account was created in the same Resource Group as the VM scale set. This account name ends with **data000*** (the name of storage accounts have to be globally unique, so the prefix is a unique string). In this storage account, the template created a container named **backup**.  We use this backup container to hold backup [UCS](https://support.f5.com/csp/article/K13132) configuration files. Once the UCS is present in the container, you update the scale set "model" to use the newer BIG-IP version. Once the scale set is updated, you upgrade the BIG-IP VE(s). As a part of this upgrade, the provisioning checks the backup container for a UCS file and if one exists, it uploads the configuration (if more than one exists, it uses the latest).

**To upgrade the BIG-IP VE Image**
  1. Save a UCS backup file of the current BIG-IP configuration (cluster or standalone)
     - From the CLI command: ```# tmsh save /sys ucs /var/tmp/original.ucs```
     - From the Configuration utility: **System > Archives > Create**
  2. Upload the UCS into the **backup** container of the storage account ending in **data000** (it is a Blob container)
  3. Update the VM Scale Set Model to the new BIG-IP version
     - From PowerShell: Use the PowerShell script in the **scripts** folder in this directory
     - Using the Azure redeploy functionality: From the Resource Group where the ARM template was initially deployed, click the successful deployment and then select to redeploy the template. If necessary, re-select all the same variables, and **only change** the BIG-IP version to the latest.
  4. Upgrade the Instances
     1. In Azure, navigate to the VM Scale Set instances pane and verify the *Latest model* does not say **Yes** (it should have a caution sign instead of the word Yes)
     2. Select either all instances at once or each instance one at a time (starting with instance ID 0 and working up).
     3. Click the **Upgrade** action button.

#### Configure Scale Event Notifications
You can add notifications when scale up/down events happen, either in the form of email or webhooks. The following shows an example of adding an email address that receives an email from Azure whenever a scale up/down event occurs.

Log in to the [Azure Resource Explorer](https://resources.azure.com) and then navigate to the Auto Scale settings (**Subscriptions > Resource Groups >** *resource group where deployed* **> Providers > Microsoft.Insights > Autoscalesettings > autoscaleconfig**).  At the top of the screen click Read/Write, and then from the Auto Scale settings, click **Edit**.  Replace the current **notifications** json key with the example below, making sure to update the email address(es). Select PUT and notifications will be sent to the email addresses listed.

```json
    "notifications": [
      {
        "operation": "Scale",
        "email": {
          "sendToSubscriptionAdministrator": false,
          "sendToSubscriptionCoAdministrators": false,
          "customEmails": [
            "email@f5.com"
          ]
        },
        "webhooks": null
      }
    ]
```

## Documentation

The ***BIG-IP Virtual Edition and Microsoft Azure: Setup*** guide (https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/bigip-ve-setup-msft-azure-12-1-0.html) describes how to create a single NIC and multi-NIC BIG-IP without using an ARM template.

### Service Discovery
Once you launch your BIG-IP instance using the ARM template, you can use the Service Discovery iApp template on the BIG-IP VE to automatically update pool members based on auto-scaled cloud application hosts.  In the iApp template, you enter information about your cloud environment, including the tag key and tag value for the pool members you want to include, and then the BIG-IP VE programmatically discovers (or removes) members using those tags.

#### Tagging
In Microsoft Azure, you have three options for tagging objects that the Service Discovery iApp uses. Note that you select public or private IP addresses within the iApp.
  - *Tag a VM resource*<br>
The BIG-IP VE will discover the primary public or private IP addresses for the primary NIC configured for the tagged VM.
  - *Tag a NIC resource*<br>
The BIG-IP VE will discover the primary public or private IP addresses for the tagged NIC.  Use this option if you want to use the secondary NIC of a VM in the pool.
  - *Tag a Virtual Machine Scale Set resource*<br>
The BIG-IP VE will discover the primary private IP address for the primary NIC configured for each Scale Set instance.  Note you must select Private IP addresses in the iApp template if you are tagging a Scale Set.

The iApp first looks for NIC resources with the tags you specify.  If it finds NICs with the proper tags, it does not look for VM resources. If it does not find NIC resources, it looks for VM resources with the proper tags. In either case, it then looks for Scale Set resources with the proper tags.

**Important**: Make sure the tags and IP addresses you use are unique. You should not tag multiple Azure nodes with the same key/tag combination if those nodes use the same IP address.

To launch the template:
  1.	From the BIG-IP VE web-based Configuration utility, on the Main tab, click **iApps > Application Services > Create**.
  2.	In the **Name** field, give the template a unique name.
  3.	From the **Template** list, select **f5.service_discovery**.  The template opens.
  4.	Complete the template with information from your environment.  For assistance, from the Do you want to see inline help? question, select Yes, show inline help.
  5.	When you are done, click the **Finished** button.

### Service Principal Authentication
This solution requires access to the Azure API to determine how the BIG-IP VEs should be configured.  The most efficient and security-conscious way to handle this is to utilize Azure service principal authentication, for all the typical security reasons.  The following provides information/links on the options for configuring a service principal within Azure if this is the first time it is needed in a subscription.

_Ensure that however the creation of the service principal occurs to verify it only has minimum required access based on the solutions need(read vs read/write) prior to this template being deployed and used by the solution within the resource group selected(new or existing)._

**Minimum Required Access:** **Read** access is required, it can be limited to the resource group used by this solution.

The end result should be possession of a client(application) ID, tenant ID and service principal secret that can login to the same subscription this template will be deployed into.  Ensuring this is fully functioning prior to deploying this ARM template will save on some troubleshooting post-deployment if the service principal is in fact not fully configured.

#### 1. Azure Portal

Follow the steps outlined in the [Azure Portal documentation](https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/) to generate the service principal.

#### 2. Azure CLI

This method can be used with either the [Azure CLI v2.0 (Python)](https://github.com/Azure/azure-cli) or the [Azure Cross-Platform CLI (npm module)](https://github.com/Azure/azure-xplat-cli).

_Using the Python Azure CLI v2.0 - requires just one step_
```shell
$ az ad sp create-for-rbac
```

_Using the Node.js cross-platform CLI - requires additional steps for setting up_
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal-cli

#### 3. Azure PowerShell
Follow the steps outlined in the [Azure Powershell documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal) to generate the service principal.

## Deploying Custom Configuration to the BIG-IP (Azure Virtual Machine)

Once the solution has been deployed there may be a need to perform some additional configuration of the BIG-IP.  This can be accomplished via traditional methods such as via the GUI, logging into the CLI or using the REST API.  However, depending on the requirments it might be preferred to perform this custom configuration as a part of the initial deployment of the solution.  This can be accomplished in the below manner.

Within the Azure Resource Manager (ARM) template there is a variable called **customConfig**, this contains text similar to "### START(INPUT) CUSTOM CONFIGURATION", that can be replaced with custom shell scripting to perform additional configuration of the BIG-IP.  An example of what it would look like to configure the f5.ip_forwarding iApp is included below.

Warning: F5 does not support the template if you change anything other than the **customConfig** ARM template variable.

```json
"variables": {
    "customConfig": "### START (INPUT) CUSTOM CONFIGURATION HERE\ntmsh create sys application service my_deployment { device-group none template f5.ip_forwarding traffic-group none variables replace-all-with { basic__addr { value 0.0.0.0 } basic__forward_all { value No } basic__mask { value 0.0.0.0 } basic__port { value 0 } basic__vlan_listening { value default } options__advanced { value no }options__display_help { value hide } } }"
}
```
### Changing the BIG-IP Configuration utility (GUI) port
Depending on the deployment requirements, the default managament port for the BIG-IP may need to be changed. To change the Management port, see [Changing the Configuration utility port](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/bigip-ve-setup-msft-azure-12-0-0/2.html#GUID-3E6920CD-A8CD-456C-AC40-33469DA6922E) for instructions.<br>
***Important***: The default port provisioned is dependent on 1) which BIG-IP version you choose to deploy as well as 2) how many interfaces (NICs) are configured on that BIG-IP. BIG-IP v13.x and later in a single-NIC configuration uses port 8443. All prior BIG-IP versions default to 443 on the MGMT interface.<br>
***Important***: If you perform the procedure to change the port, you must check the Azure Network Security Group associated with the interface on the BIG-IP that was deployed and adjust the ports accordingly.

## Security Details <a name="securitydetail"></a>
This section has the code snippet for each the lines you should ensure are present in your template file if you want to verify the integrity of the helper code in the template.

Note the hashed script-signature may be different in your template.<br>

```json
"variables": {
    "apiVersion": "2015-06-15",
    "location": "[resourceGroup().location]",
    "singleQuote": "'",
    "f5CloudLibsTag": "release-2.0.0",
    "expectedHash": "8bb8ca730dce21dff6ec129a84bdb1689d703dc2b0227adcbd16757d5eeddd767fbe7d8d54cc147521ff2232bd42eebe78259069594d159eceb86a88ea137b73",
    "verifyHash": "[concat(variables('singleQuote'), 'cli script /Common/verifyHash {\nproc script::run {} {\n        if {[catch {\n            set file_path [lindex $tmsh::argv 1]\n            set expected_hash ', variables('expectedHash'), '\n            set computed_hash [lindex [exec /usr/bin/openssl dgst -r -sha512 $file_path] 0]\n            if { $expected_hash eq $computed_hash } {\n                exit 0\n            }\n            tmsh::log err {Hash does not match}\n            exit 1\n        }]} {\n            tmsh::log err {Unexpected error in verifyHash}\n            exit 1\n        }\n    }\n    script-signature fc3P5jEvm5pd4qgKzkpOFr9bNGzZFjo9pK0diwqe/LgXwpLlNbpuqoFG6kMSRnzlpL54nrnVKREf6EsBwFoz6WbfDMD3QYZ4k3zkY7aiLzOdOcJh2wECZM5z1Yve/9Vjhmpp4zXo4varPVUkHBYzzr8FPQiR6E7Nv5xOJM2ocUv7E6/2nRfJs42J70bWmGL2ZEmk0xd6gt4tRdksU3LOXhsipuEZbPxJGOPMUZL7o5xNqzU3PvnqZrLFk37bOYMTrZxte51jP/gr3+TIsWNfQEX47nxUcSGN2HYY2Fu+aHDZtdnkYgn5WogQdUAjVVBXYlB38JpX1PFHt1AMrtSIFg==\n}', variables('singleQuote'))]",
    "installCloudLibs": "[concat(variables('singleQuote'), '#!/bin/bash\necho about to execute\nchecks=0\nwhile [ $checks -lt 120 ]; do echo checking mcpd\n/usr/bin/tmsh -a show sys mcp-state field-fmt | grep -q running\nif [ $? == 0 ]; then\necho mcpd ready\nbreak\nfi\necho mcpd not ready yet\nlet checks=checks+1\nsleep 1\ndone\necho loading verifyHash script\n/usr/bin/tmsh load sys config merge file /config/verifyHash\nif [ $? != 0 ]; then\necho cannot validate signature of /config/verifyHash\nexit\nfi\necho loaded verifyHash\necho verifying f5-cloud-libs.targ.gz\n/usr/bin/tmsh run cli script verifyHash /config/cloud/f5-cloud-libs.tar.gz\nif [ $? != 0 ]; then\necho f5-cloud-libs.tar.gz is not valid\nexit\nfi\necho verified f5-cloud-libs.tar.gz\necho expanding f5-cloud-libs.tar.gz\ntar xvfz /config/cloud/f5-cloud-libs.tar.gz -C /config/cloud\ntouch /config/cloud/cloudLibsReady', variables('singleQuote'))]",
```


## Filing Issues
If you find an issue, we would love to hear about it.
You have a choice when it comes to filing issues:
  - Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and non-urgent bug fixes. Tell us as much as you can about what you found and how you found it.
  - Contact F5 Technical support via your typical method for more time sensitive changes and other issues requiring immediate support.


## Copyright

Copyright 2014-2017 F5 Networks Inc.


## License


Apache V2.0
~~~~~~~~~~~
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations
under the License.

Contributor License Agreement
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Individuals or business entities who contribute to this project must have
completed and submitted the [F5 Contributor License Agreement](http://f5-openstack-docs.readthedocs.io/en/latest/cla_landing.html).