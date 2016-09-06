# F5 Networks - Load Balancing Rules with Multiple Public IPs
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 06/09/2016

# Login to Azure RM
Login-AzureRmAccount

# Select resource group and location
$rgName = "rgPAPERSTSOAP"
$reLocation = "West Europe"

# Create additional static public IP addresses
New-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
New-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static
New-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName -Location $reLocation –AllocationMethod Static

# Add PIP1 to the LB
$pip1 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT1" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name "lbazEXTERNAL" | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT1" -PublicIpAddress $pip1 | Set-AzureRmLoadBalancer

# Add PIP2 to the LB
$pip2 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT2" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name "lbazEXTERNAL" | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT2" -PublicIpAddress $pip2 | Set-AzureRmLoadBalancer

# Add PIP3 to the LB
$pip3 = Get-AzureRmPublicIpAddress -Name "pipLBAZEXT3" -ResourceGroupName $rgName
Get-AzureRMLoadBalancer -ResourceGroupName $rgName -Name "lbazEXTERNAL" | Add-AzureRmLoadBalancerFrontendIpConfig -name "feipLBAZEXT3" -PublicIpAddress $pip3 | Set-AzureRmLoadBalancer

# Add LB rule for PIP1
$lb = Get-AzureRmLoadBalancer -ResourceGroupName $rgName
$pip1 = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT1"
$bepool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name "bepoolF5"
$probe1 = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE444"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE1" -FrontendIpConfiguration $pip1 -BackendAddressPool $bepool -Probe $probe1 -Protocol Tcp -FrontendPort 443 -BackendPort 444
$lb | Set-AzureRmLoadBalancer

# Add LB rule for PIP2
$lb = Get-AzureRmLoadBalancer -ResourceGroupName $rgName
$pip2 = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT2"
$bepool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name "bepoolF5"
$probe2 = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE445"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE2" -FrontendIpConfiguration $pip2 -BackendAddressPool $bepool -Probe $probe2 -Protocol Tcp -FrontendPort 443 -BackendPort 445
$lb | Set-AzureRmLoadBalancer

# Add LB rule for PIP3
$lb = Get-AzureRmLoadBalancer -ResourceGroupName $rgName
$pip3 = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name "feipLBAZEXT3"
$bepool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name "bepoolF5"
$probe3 = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "lbazPROBE446"
$lb | Add-AzureRmLoadBalancerRuleConfig -Name "lbrSERVICE3" -FrontendIpConfiguration $pip3 -BackendAddressPool $bepool -Probe $probe3 -Protocol Tcp -FrontendPort 443 -BackendPort 446
$lb | Set-AzureRmLoadBalancer
