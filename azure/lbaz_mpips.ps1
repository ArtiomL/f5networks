# F5 Networks - Load Balancing Rules with Multiple Public IPs
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 06/09/2016

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
New-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
New-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
New-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static

# Add PIP1 to LBAZ
$pip1 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name $lbName | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT1" -PublicIpAddress $pip1 | Set-AzureRmLoadBalancer

# Add PIP2 to LBAZ
$pip2 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name $lbName | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT2" -PublicIpAddress $pip2 | Set-AzureRmLoadBalancer

# Add PIP3 to LBAZ
$pip3 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name $lbName | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT3" -PublicIpAddress $pip3 | Set-AzureRmLoadBalancer

$lb = Get-AzureRmLoadBalancer -ResourceGroupName $rgName
$bepool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name $bpName

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
