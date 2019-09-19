
$cred = Get-Credential

#command for VM Create
New-AzVm `
    -ResourceGroupName "myResourceGroup" `
    -Name "dibsVM01" `
    -Location "EastUS" `
    -VirtualNetworkName "myVnet" `
    -SubnetName "mySubnet" `
    -SecurityGroupName "myNetworkSecurityGroup" `
    -PublicIpAddressName "myPublicIpAddress" `
    -Credential $cred


#Get the public address

Get-AzPublicIpAddress    -ResourceGroupName "myResourceGroup"  | Select IpAddress

#connect to VM
mstsc /v:104.45.140.248


#get image publisher
Get-AzVMImagePublisher -Location "EastUS"

#get image offer
Get-AzVMImageOffer `
   -Location "EastUS" `
   -PublisherName "MicrosoftWindowsServer"


#get sku
Get-AzVMImageSku `
   -Location "EastUS" `
   -PublisherName "MicrosoftWindowsServer" `
   -Offer "WindowsServer"




#With specific sku
New-AzVm `
    -ResourceGroupName "myResourceGroup" `
    -Name "dibsVM02" `
    -Location "EastUS" `
    -VirtualNetworkName "myVnet" `
    -SubnetName "mySubnet" `
    -SecurityGroupName "myNetworkSecurityGroup" `
    -PublicIpAddressName "myPublicIpAddress2" `
    -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-with-Containers:latest" `
    -Credential $cred `
    -AsJob

    #loginto azure
    Connect-AzAccount

    # resource group create

    New-AzResourceGroup   -Name "MyRG01"   -Location "EastUS"
    #######################################################################

    #VMSS Creation

# create VMSS
    New-AzVmss `
  -ResourceGroupName "MyRG01" `
  -Location "EastUS" `
  -VMScaleSetName "myScaleSet" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -PublicIpAddressName "myPublicIPAddress" `
  -LoadBalancerName "myLoadBalancer" `
  -UpgradePolicyMode "Automatic"

  ###################################################################

  #install IIS
 # Define the script for your Custom Script Extension to run
$publicSettings = @{
    "fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1");
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1"
}

# Get information about the scale set
$vmss = Get-AzVmss `
  -ResourceGroupName "MyRG01" `
  -VMScaleSetName "myScaleSet"

# Use Custom Script Extension to install IIS and configure basic website
Add-AzVmssExtension -VirtualMachineScaleSet $vmss `
  -Name "customScript" `
  -Publisher "Microsoft.Compute" `
  -Type "CustomScriptExtension" `
  -TypeHandlerVersion 1.8 `
  -Setting $publicSettings

# Update the scale set and apply the Custom Script Extension to the VM instances
Update-AzVmss `
  -ResourceGroupName "MyRG01" `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmss
  #############################################################################################


  ### Allow traffic to VMSS , setting up NSG

  # Get information about the scale set
$vmss = Get-AzVmss `
  -ResourceGroupName "MyRG01" `
  -VMScaleSetName "myScaleSet"

#Create a rule to allow traffic over port 80
$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
  -Name myFrontendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

#Create a network security group and associate it with the rule
$nsgFrontend = New-AzNetworkSecurityGroup `
  -ResourceGroupName  "MyRG01" `
  -Location EastUS `
  -Name myFrontendNSG `
  -SecurityRules $nsgFrontendRule

$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName  "MyRG01" `
  -Name myVnet

$frontendSubnet = $vnet.Subnets[0]

$frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name mySubnet `
  -AddressPrefix $frontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend

Set-AzVirtualNetwork -VirtualNetwork $vnet

# Update the scale set and apply the Custom Script Extension to the VM instances
Update-AzVmss `
  -ResourceGroupName "MyRG01" `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmss


  ##################################################################################################

  ##get IP Address

Get-AzPublicIPAddress `
  -ResourceGroupName "MyRG01" `
  -Name "myPublicIPAddress" | select IpAddress
  ###################################


  #Check VM

  Get-AzVmssVM `
  -ResourceGroupName "MyRG01" `
  -VMScaleSetName "myScaleSet"