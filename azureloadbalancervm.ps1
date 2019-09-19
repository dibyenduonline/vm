#####

# Create a resource group

New-AzResourceGroup `
  -ResourceGroupName "myRG02" `
  -Location "EastUS"

  ##########################################
  #create public address
  $publicIP = New-AzPublicIpAddress `
  -ResourceGroupName "myRG02" `
  -Location "EastUS" `
  -AllocationMethod "Static" `
  -Name "myPublicIP"
  
  
  #################################
  #Create fronend IP

  $frontendIP = New-AzLoadBalancerFrontendIpConfig `
  -Name "myFrontEndPool" `
  -PublicIpAddress $publicIP


  ################################
  #Create a backend pool

  $backendPool = New-AzLoadBalancerBackendAddressPoolConfig `
  -Name "myBackEndPool"


  ###################
  #Create load balancer

  $lb = New-AzLoadBalancer `
  -ResourceGroupName "myRG02" `
  -Name "myLoadBalancer" `
  -Location "EastUS" `
  -FrontendIpConfiguration $frontendIP `
  -BackendAddressPool $backendPool


  ###################
  #Health probe config

  Add-AzLoadBalancerProbeConfig `
  -Name "myHealthProbe" `
  -LoadBalancer $lb `
  -Protocol tcp `
  -Port 80 `
  -IntervalInSeconds 15 `
  -ProbeCount 2

  #######################################
  #set health probe
  Set-AzLoadBalancer -LoadBalancer $lb

  #######################################
  #Load balancer rule

  $probe = Get-AzLoadBalancerProbeConfig -LoadBalancer $lb -Name "myHealthProbe"

Add-AzLoadBalancerRuleConfig `
  -Name "myLoadBalancerRule" `
  -LoadBalancer $lb `
  -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
  -BackendAddressPool $lb.BackendAddressPools[0] `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80 `
  -Probe $probe
  ############################
  #set rule
  Set-AzLoadBalancer -LoadBalancer $lb


  ######################################################
  #Create network

  # Create subnet config
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name "mySubnet" `
  -AddressPrefix 192.168.1.0/24

# Create the virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName "myRG02" `
  -Location "EastUS" `
  -Name "myVnet" `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

  #######################
  #Create NIC

  for ($i=1; $i -le 3; $i++)
{
   New-AzNetworkInterface `
     -ResourceGroupName "myRG02" `
     -Name myVM$i `
     -Location "EastUS" `
     -Subnet $vnet.Subnets[0] `
     -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0]
}

########################################
#Create availablity set
$availabilitySet = New-AzAvailabilitySet `
  -ResourceGroupName "myRG02" `
  -Name "myAvailabilitySet" `
  -Location "EastUS" `
  -Sku aligned `
  -PlatformFaultDomainCount 2 `
  -PlatformUpdateDomainCount 2



  ###########################
  #Create VM

  $cred = Get-Credential



  for ($i=1; $i -le 3; $i++)
{
    New-AzVm `
        -ResourceGroupName "myRG02" `
        -Name "myVM$i" `
        -Location "East US" `
        -VirtualNetworkName "myVnet" `
        -SubnetName "mySubnet" `
        -SecurityGroupName "myNetworkSecurityGroup" `
        -OpenPorts 80 `
        -AvailabilitySetName "myAvailabilitySet" `
        -Credential $cred `
        -AsJob
}
##################################
#check status of background jobs

job



###################################
#Configure IIS
for ($i=1; $i -le 3; $i++)
{
   Set-AzVMExtension `
     -ResourceGroupName "myRG02" `
     -ExtensionName "IIS" `
     -VMName myVM$i `
     -Publisher Microsoft.Compute `
     -ExtensionType CustomScriptExtension `
     -TypeHandlerVersion 1.8 `
     -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
     -Location EastUS
}

###################
#Get IP
Get-AzPublicIPAddress `
  -ResourceGroupName "myResourceGroupLoadBalancer" `
  -Name "myPublicIP" | select IpAddress