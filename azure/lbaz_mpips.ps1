# F5 Networks - Load Balancing Rules with Multiple Public IPs
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.2, 13/09/2016

# Login to Azure RM
Login-AzureRmAccount

# Show all subscriptions
Get-AzureRmSubscription

# Select the relevant subscription
$subName = Get-AzureRmSubscription -SubscriptionName "Paper Street Soap"
$subName | Select-AzureRmSubscription

# Select resource group name, location, load balancer and backend pool names
$rgName = "rgPAPERSTSOAP"
$reLocation = "West Europe"
$lbName = "lbazEXTERNAL"
$bpName = "bepoolF5"

# Create new static public IP addresses
$pip1 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
$pip2 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
$pip3 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static

# Create new LBAZ
$lb = New-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName -Location $reLocation

# Add public IPs to LBAZ
$lb | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT1" -PublicIpAddress $pip1
$lb | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT2" -PublicIpAddress $pip2
$lb | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT3" -PublicIpAddress $pip3
# Add new backend pool
$lb | Add-AzureRmLoadBalancerBackendAddressPoolConfig -Name $bpName
$lb | Set-AzureRmLoadBalancer

# Create LBAZ probes

# Add LBAZ rule for PIP1
$fip = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT1"
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE444"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE1" -FrontendIpConfiguration $fip -BackendAddressPool $bepool -Probe $probe -Protocol Tcp -FrontendPort 443 -BackendPort 444
$lb | Set-AzureRmLoadBalancer

# Add LBAZ rule for PIP2
$fip = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT2"
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE445"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE2" -FrontendIpConfiguration $fip -BackendAddressPool $bepool -Probe $probe -Protocol Tcp -FrontendPort 443 -BackendPort 445
$lb | Set-AzureRmLoadBalancer

# Add LBAZ rule for PIP3
$fip = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT3"
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE446"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE3" -FrontendIpConfiguration $fip -BackendAddressPool $bepool -Probe $probe -Protocol Tcp -FrontendPort 443 -BackendPort 446
$lb | Set-AzureRmLoadBalancer
