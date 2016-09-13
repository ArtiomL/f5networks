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

# Create static public IP addresses
$pip1 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
$pip2 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
$pip3 = New-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static

# Create frontend IP config
$fip1 = New-AzureRmLoadBalancerFrontendIpConfig -Name "feipLBAZEXT1" -PublicIpAddress $pip1
$fip2 = New-AzureRmLoadBalancerFrontendIpConfig -Name "feipLBAZEXT2" -PublicIpAddress $pip2
$fip3 = New-AzureRmLoadBalancerFrontendIpConfig -Name "feipLBAZEXT3" -PublicIpAddress $pip3

# Create LBAZ probes
$probe4 = New-AzureRmLoadBalancerProbeConfig -Name "lbazPROBE444" -Protocol Tcp -Port 444 -IntervalInSeconds 5 -ProbeCount 2
$probe5 = New-AzureRmLoadBalancerProbeConfig -Name "lbazPROBE445" -Protocol Tcp -Port 445 -IntervalInSeconds 5 -ProbeCount 2
$probe6 = New-AzureRmLoadBalancerProbeConfig -Name "lbazPROBE446" -Protocol Tcp -Port 446 -IntervalInSeconds 5 -ProbeCount 2

# Create backend pool
$bepool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $bpName

# Create new LBAZ with public IPs, probes and backend pool
$lb = New-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName -Location $reLocation -FrontendIpConfiguration $fip1, $fip2, $fip3 -Probe $probe4, $probe5, $probe6 -BackendAddressPool $bepool

# Add LBAZ rules for public IPs
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE1" -FrontendIpConfiguration $fip1 -BackendAddressPool $bepool -Probe $probe4 -Protocol Tcp -FrontendPort 443 -BackendPort 444
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE2" -FrontendIpConfiguration $fip2 -BackendAddressPool $bepool -Probe $probe5 -Protocol Tcp -FrontendPort 443 -BackendPort 445
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE3" -FrontendIpConfiguration $fip3 -BackendAddressPool $bepool -Probe $probe6 -Protocol Tcp -FrontendPort 443 -BackendPort 446
$lb | Set-AzureRmLoadBalancer
