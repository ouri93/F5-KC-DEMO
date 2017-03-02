#!/bin/bash

## Bash Script to deploy an F5 ARM template into Azure, using azure cli 1.0 ##
## Example Command: ./deploy_via_bash.sh --licenseType PAYG --licensedBandwidth 200m --vmScaleSetCount 2 --scaleOutThroughput 90 --scaleInThroughput 10 --adminUsername azureuser --adminPassword <value> --dnsLabel <value> --instanceType Standard_D2_v2 --imageName Good --tenantId <value> --clientId <value> --servicePrincipalSecret <value> --restrictedSrcAddress "*" --resourceGroupName <value> --azureLoginUser <value> --azureLoginPassword <value>

# Assign Script Paramters and Define Variables
# Specify static items, change these as needed or make them parameters
region="westus"
restrictedSrcAddress="*"
tagValues='{"application":"APP","environment":"ENV","group":"GROUP","owner":"OWNER","cost":"COST"}'

ARGS=`getopt -o a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r: --long resourceGroupName:,azureLoginUser:,azureLoginPassword:,licenseType:,licensedBandwidth:,licenseKey1:,vmScaleSetCount:,scaleOutThroughput:,scaleInThroughput:,adminUsername:,adminPassword:,dnsLabel:,instanceType:,imageName:,tenantId:,clientId:,servicePrincipalSecret:,restrictedSrcAddress: -n $0 -- "$@"`
eval set -- "$ARGS"

# Parse the command line arguments, primarily checking full params as short params are just placeholders
while true; do
    case "$1" in
        -a|--resourceGroupName)
            resourceGroupName=$2
            shift 2;;
        -b|--azureLoginUser)
            azureLoginUser=$2
            shift 2;;
        -c|--azureLoginPassword)
            azureLoginPassword=$2
            shift 2;;
        -d|--licenseType)
            licenseType=$2
            shift 2;;
        -e|--licensedBandwidth)
            licensedBandwidth=$2
            shift 2;;
        -f|--licenseKey1)
            licenseKey1=$2
            shift 2;;
        -g|--vmScaleSetCount)
            vmScaleSetCount=$2
            shift 2;;
        -h|--scaleOutThroughput)
            scaleOutThroughput=$2
            shift 2;;
        -i|--scaleInThroughput)
            scaleInThroughput=$2
            shift 2;;
        -j|--adminUsername)
            adminUsername=$2
            shift 2;;
        -k|--adminPassword)
            adminPassword=$2
            shift 2;;
        -l|--dnsLabel)
            dnsLabel=$2
            shift 2;;
        -m|--instanceType)
            instanceType=$2
            shift 2;;
        -n|--imageName)
            imageName=$2
            shift 2;;
        -o|--tenantId)
            tenantId=$2
            shift 2;;
        -p|--clientId)
            clientId=$2
            shift 2;;
        -q|--servicePrincipalSecret)
            servicePrincipalSecret=$2
            shift 2;;
        -r|--restrictedSrcAddress)
            restrictedSrcAddress=$2
            shift 2;;
        --)
            shift
            break;;
    esac
done

#If a required paramater is not passed, the script will prompt for it below
required_variables="vmScaleSetCount scaleOutThroughput scaleInThroughput adminUsername adminPassword dnsLabel instanceType imageName tenantId clientId servicePrincipalSecret resourceGroupName licenseType "
for variable in $required_variables
        do
        if [ -v ${!variable} ] ; then
                read -p "Please enter value for $variable:" $variable
        fi
done

# Prompt for license key if not supplied and BYOL is selected
if [ $licenseType == "BYOL" ]; then
    if [ -v $licenseKey1 ] ; then
            read -p "Please enter value for licenseKey1:" licenseKey1
    fi
    template_file="./BYOL/azuredeploy.json"
    parameter_file="./BYOL/azuredeploy.parameters.json"
fi
# Prompt for license key if not supplied and PAYG is selected
if [ $licenseType == "PAYG" ]; then
    if [ -v $licensedBandwidth ] ; then
            read -p "Please enter value for licensedBandwidth:" licensedBandwidth
    fi
    template_file="./PAYG/azuredeploy.json"
    parameter_file="./PAYG/azuredeploy.parameters.json"
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
# such as can been done with Powershell...oh well!
azure group deployment create -f $template_file -g $resourceGroupName -n $resourceGroupName -p "{\"vmScaleSetCount\":{\"value\":\"$vmScaleSetCount\"},\"scaleOutThroughput\":{\"value\":\"$scaleOutThroughput\"},\"scaleInThroughput\":{\"value\":\"$scaleInThroughput\"},\"adminUsername\":{\"value\":\"$adminUsername\"},\"adminPassword\":{\"value\":\"$adminPassword\"},\"dnsLabel\":{\"value\":\"$dnsLabel\"},\"instanceType\":{\"value\":\"$instanceType\"},\"imageName\":{\"value\":\"$imageName\"},\"tenantId\":{\"value\":\"$tenantId\"},\"clientId\":{\"value\":\"$clientId\"},\"servicePrincipalSecret\":{\"value\":\"$servicePrincipalSecret\"},\"restrictedSrcAddress\":{\"value\":\"$restrictedSrcAddress\"},\"tagValues\":{\"value\":$tagValues},\"licensedBandwidth\":{\"value\":\"$licensedBandwidth\"}}"