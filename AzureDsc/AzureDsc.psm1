function Test-AzDscResourceGroup
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $Location,
        [parameter()]
        [boolean]
        $IgnoreLocation = $false
    )

    $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
    if (!$rg)
    {
        Write-Verbose "Resource Group $Name does not exist"
        return $false
    }
    else
    {
        if ($rg.Location -ne $Location)
        {
            if ($IgnoreLocation -eq $false)
            {
                Write-Verbose "Resource group $Name exists in the wrong location. Expected value: $Location, actual value: $($rg.Location)"
                return $false
            }
            else 
            {
                Write-Verbose "Resource group $Name exists in the wrong location. Expected value: $Location, actual value: $($rg.Location)"
                Write-Verbose "Ignoring location because IgnoreLocation is set to True"
                return $true
            }
        }
        else 
        {
            Write-Verbose "Resource Group $Name exists in the correct location"
            return $true
        }
    }
}

function Set-AzDscResourceGroup
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $Location,
        [parameter()]
        [boolean]
        $IgnoreLocation = $false
    )

    if ((Test-AzDscResourceGroup -Name $Name -Location $Location -IgnoreLocation $IgnoreLocation) -eq $false)
    {
        Write-Verbose "Creating resource group $Name in location $Location"
        New-AzResourceGroup -Name $Name -Location $Location -Force
    }
}

function Test-AzDscVirtualNetwork
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $Location,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string[]]
        $AddressPrefixes,
        [parameter(Mandatory = $true)]
        [array]
        $DnsServers = @()
    )

    $virtualNetwork = Get-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($virtualNetwork) 
    {
        Write-Verbose "Virtual Network $Name exists in Resource Group $ResourceGroupName"
        if (-not (Compare-Object $virtualNetwork.AddressSpace.AddressPrefixes.ToArray() $AddressPrefixes) -and $virtualNetwork.Location -eq $Location `
        -and (-not (Compare-Object $virtualNetwork.DhcpOptions.DnsServers.ToArray() $DnsServers)))
        {
            Write-Verbose "Virtual Network $Name exists in Resource Group $ResourceGroupName with correct settings"
            return $true
        }
        else 
        {
            Write-Verbose "Virtual Network $Name exists in Resource Group $ResourceGroupName with incorrect settings"
            return $false
        }
    }
    else 
    {
        Write-Verbose "Virtual Network $Name does not exist in Resource Group $ResourceGroupName"
        return $false
    }
}

function Set-AzDscVirtualNetwork
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $Location,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string[]]
        $AddressPrefixes,
        [parameter(Mandatory = $true)]
        [array]
        $DnsServers = @(),
        [parameter()]
        [boolean]
        $UpdateExistingVirtualNetwork = $false
    )

    $existingVirtualNetwork = Get-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

    if ((Test-AzDscVirtualNetwork -Name $Name -Location $Location -ResourceGroupName $ResourceGroupName -AddressPrefixes $AddressPrefixes `
    -DnsServers $DnsServers) -eq $false)
    {
        if (($existingVirtualNetwork) -and $UpdateExistingVirtualNetwork -eq $true)
        {
            # Update the virtual network if it exists and UpdateExistingVirtualNetwork is true
            Write-Verbose "Updating virtual network $Name in location $Location"
            New-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AddressPrefixes -DnsServer `
            $DnsServers -Force
        }
        else 
        {
            # Create virtual network if it does not already exist
            Write-Verbose "Creating virtual network $Name in location $Location"
            New-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AddressPrefixes -DnsServer `
            $DnsServers
        }
    }
}

function Test-AzDscVirtualNetworkPeering
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $LocalVirtualNetworkName,
        [parameter(Mandatory = $true)]
        [string]
        $LocalVirtualNetworkResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $RemoteVirtualNetworkName,
        [parameter(Mandatory = $true)]
        [string]
        $RemoteVirtualNetworkResourceGroupName
    )

    $localVirtualNetworkId = (Get-AzVirtualNetwork -Name $LocalVirtualNetworkName -ResourceGroupName `
    $LocalVirtualNetworkResourceGroupName).Id

    $remoteVirtualNetworkId = (Get-AzVirtualNetwork -Name $RemoteVirtualNetworkName -ResourceGroupName `
    $RemoteVirtualNetworkResourceGroupName).Id

    $localPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $LocalVirtualNetworkName -ResourceGroupName `
    $LocalVirtualNetworkResourceGroupName -ErrorAction SilentlyContinue
    $localPeering = $localPeering | Where-Object {$_.RemoteVirtualNetwork.Id -eq $remoteVirtualNetworkId}

    $remotePeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $RemoteVirtualNetworkName -ResourceGroupName `
    $RemoteVirtualNetworkResourceGroupName -ErrorAction SilentlyContinue
    $remotePeering = $remotePeering | Where-Object {$_.RemoteVirtualNetwork.Id -eq $localVirtualNetworkId}

    if ($RemotePeering.PeeringState -eq "Connected" -and $localPeering.PeeringState -eq "Connected")
    {
        Write-Verbose "Peering between $LocalVirtualNetworkName and $RemoteVirtualNetworkName is connected"
        return $true
    }
    else 
    {
        Write-Verbose "Peering between $LocalVirtualNetworkName and $RemoteVirtualNetworkName is not connected or does not exist"
        return $false
    }
}

function Set-AzDscVirtualNetworkPeering 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $LocalVirtualNetworkName,
        [parameter(Mandatory = $true)]
        [string]
        $LocalVirtualNetworkResourceGroupName,
        [parameter(Mandatory = $true)]
        [object[]]
        $RemoteVirtualNetworks,
        [parameter()]
        [boolean]
        $CreateVirtualNetworkPeering = $true
    )

    $localVirtualNetworkObject = Get-AzVirtualNetwork -Name $LocalVirtualNetworkName -ResourceGroupName `
    $LocalVirtualNetworkResourceGroupName

    foreach ($RemoteVirtualNetwork in $RemoteVirtualNetworks.Keys)
    {
        # Check if peering is not working
        if ((Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName $LocalVirtualNetworkName -LocalVirtualNetworkResourceGroupName `
        $LocalVirtualNetworkResourceGroupName -RemoteVirtualNetworkName $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name `
        -RemoteVirtualNetworkResourceGroupName $RemoteVirtualNetworks.$RemoteVirtualNetwork.ResourceGroupName) -eq $false -and `
        $CreateVirtualNetworkPeering -eq $true)
        {
            # Get remote virtual network object
            $remoteVirtualNetworkObject = Get-AzVirtualNetwork -Name $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name `
            -ResourceGroupName $RemoteVirtualNetworks.$RemoteVirtualNetwork.ResourceGroupName

            # Remove local peering if it exists
            if(Get-AzVirtualNetworkPeering -VirtualNetworkName $LocalVirtualNetworkName -ResourceGroupName `
            $LocalVirtualNetworkResourceGroupName | Where-Object {$_.RemoteVirtualNetwork.Id -eq $remoteVirtualNetworkObject.Id})
            {
                Write-Verbose "Removing peering to $($remoteVirtualNetworkObject.Id) on virtual network $LocalVirtualNetworkName"
                Remove-AzVirtualNetworkPeering -Name $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name -VirtualNetwork $LocalVirtualNetworkName `
                -ResourceGroupName $LocalVirtualNetworkResourceGroupName -Force
            }

            # Remove remote peering if it exists
            if (Get-AzVirtualNetworkPeering -VirtualNetworkName $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name -ResourceGroupName `
            $RemoteVirtualNetworks.$RemoteVirtualNetwork.ResourceGroupName | Where-Object {$_.RemoteVirtualNetwork.Id -eq $localVirtualNetworkObject.Id})
            {
                Write-Verbose "Removing peering to $($localVirtualNetworkObject.Id) on virtual network $($RemoteVirtualNetworks.$RemoteVirtualNetwork.Name)"
                Remove-AzVirtualNetworkPeering -Name $LocalVirtualNetworkName -VirtualNetwork $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name `
                -ResourceGroupName $RemoteVirtualNetworks.$RemoteVirtualNetwork.ResourceGroupName -Force
            }

            # Add local peering
            Write-Verbose "Creating peering to $($remoteVirtualNetworkObject.Id) on virtual network $LocalVirtualNetworkName"
            Add-AzVirtualNetworkPeering -Name $RemoteVirtualNetworks.$RemoteVirtualNetwork.Name -VirtualNetwork $LocalVirtualNetworkObject `
            -RemoteVirtualNetworkId $remoteVirtualNetworkObject.Id

            # Add remote peering
            Write-Verbose "Creating peering to $($localVirtualNetworkObject.Id) on virtual network $($RemoteVirtualNetworks.$RemoteVirtualNetwork.Name)"
            Add-AzVirtualNetworkPeering -Name $LocalVirtualNetworkName -VirtualNetwork $remoteVirtualNetworkObject `
            -RemoteVirtualNetworkId $localVirtualNetworkObject.Id
        }
    }
}

function Test-AzDscSubnet 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $AddressPrefix,
        [parameter(Mandatory = $true)]
        [string]
        $VirtualNetworkName,
        [parameter(Mandatory = $true)]
        [string]
        $VirtualNetworkResourceGroupName,
        [parameter()]
        [string]
        $RouteTableId,
        [parameter()]
        [string]
        $NetworkSecurityGroupId
    )

    $virtualNetworkObject = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $VirtualNetworkResourceGroupName `
    -ErrorAction SilentlyContinue


    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $Name -VirtualNetwork $virtualNetworkObject -ErrorAction SilentlyContinue
    if ($subnet)
    {
        if ($subnet.AddressPrefix -eq $AddressPrefix -and $subnet.RouteTable.Id -eq $RouteTableId -and $subnet.NetworkSecurityGroup.Id `
        -eq $NetworkSecurityGroupId)
        {
            Write-Verbose "Subnet $Name exists in virtual network $VirtualNetworkName with the correct settings"
            return $true
        }
        else 
        {
            Write-Verbose "Subnet $Name exists in virtual network $VirtualNetworkName with the incorrect settings"
            return $false
        }
    }
    else 
    {
        Write-Verbose "Subnet $Name does not exist in virtual network $VirtualNetworkName"
        return $false
    }
}

function Set-AzDscSubnet 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $VirtualNetworkName,
        [parameter(Mandatory = $true)]
        [string]
        $VirtualNetworkResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $RouteTableId,
        [parameter(Mandatory = $true)]
        [string]
        $NetworkSecurityGroupId,
        [parameter()]
        [string]
        $UpdateExistingSubnet = $true,
        [parameter(Mandatory = $true)]
        [hashtable]
        $Subnets
    )

    $virtualNetworkObject = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $VirtualNetworkResourceGroupName `
    -ErrorAction SilentlyContinue
    foreach ($Subnet in $Subnets.Keys)
    {
        if ((Test-AzDscSubnet -Name $Subnets.$Subnet.Name -AddressPrefix $Subnets.$Subnet.AddressPrefix -VirtualNetworkName $VirtualNetworkName `
        -VirtualNetworkResourceGroupName $VirtualNetworkResourceGroupName -RouteTableId $RouteTableId -NetworkSecurityGroupId $NetworkSecurityGroupId) -eq $false)
        {
            if (Get-AzVirtualNetworkSubnetConfig -Name $Subnets.$Subnet.Name -VirtualNetwork $virtualNetworkObject)
            {
                Write-Verbose "Updating subnet $($Subnets.$Subnet.Name) in virtual network $VirtualNetworkName"
                Set-AzVirtualNetworkSubnetConfig -Name $Subnets.$Subnet.Name -VirtualNetwork $virtualNetworkObject -AddressPrefix `
                $Subnets.$Subnet.AddressPrefix -NetworkSecurityGroupId $NetworkSecurityGroupId -RouteTableId $RouteTableId
            }
            else 
            {
                Write-Verbose "Creating subnet $($Subnets.$Subnet.Name) in virtual network $VirtualNetworkName"
                New-AzVirtualNetworkSubnetConfig -Name $Subnets.$Subnet.Name -AddressPrefix $Subnets.$Subnet.AddressPrefix `
                -NetworkSecurityGroupId $NetworkSecurityGroupId -RouteTableId $RouteTableId
            }
        }
    }
}

function Test-AzDscRouteTable 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName
    )

    if (Get-AzRouteTable -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Route table $Name exists in resource group $ResourceGroupName"
        return $true
    }
    else 
    {
        Write-Verbose "Route table $Name does not exist in resource group $ResourceGroupName"
        return $false
    }
}

function Set-AzDscRouteTable
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $Location
    )

    if ((Test-AzDscRouteTable -Name $Name -ResourceGroupName $ResourceGroupName) -eq $false)
    {
        Write-Verbose "Creating route table $Name in resource group $ResourceGroupName"
        New-AzRouteTable -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location
    }
}

function Test-AzDscNetworkSecurityGroup 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName
    )

    if (Get-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Network security group $Name exists in resource group $ResourceGroupName"
        return $true
    }
    else 
    {
        Write-Verbose "Network security group $Name does not exist in resource group $ResourceGroupName"
        return $false
    }
}

function Set-AzDscNetworkSecurityGroup
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $Location
    )

    if ((Test-AzDscNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName) -eq $false)
    {
        Write-Verbose "Creating Network security group $Name in resource group $ResourceGroupName"
        New-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location
    }
}

function Test-AzDscRouteConfig {
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $AddressPrefix,
        [parameter(Mandatory = $true)]
        [string]
        $NextHopType,
        [parameter(Mandatory = $true)]
        [string]
        $NextHopIpAddress,
        [parameter(Mandatory = $true)]
        [string]
        $RouteTableName,
        [parameter(Mandatory = $true)]
        [string]
        $RouteTableResourceGroupName
    )

    $routeTableObject = Get-AzRouteTable -Name $RouteTableName -ResourceGroupName $RouteTableResourceGroupName
    $routeConfig = Get-AzRouteConfig -Name $Name -RouteTable $routeTableObject -ErrorAction SilentlyContinue
    if ($routeConfig.AddressPrefix -eq $AddressPrefix -and $routeConfig.NextHopType -eq $NextHopType -and $routeConfig.NextHopIpAddress `
    -eq $NextHopIpAddress)
    {
        Write-Verbose "Route $Name exists with correct settings"
        return $true
    }
    else 
    {
        Write-Verbose "Route $Name exists with incorrect settings or does not exist"    
        return $false
    }
}

function Set-AzDscRouteConfig 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [hashtable]
        $Routes,
        [parameter(Mandatory = $true)]
        [string]
        $RouteTableName,
        [parameter(Mandatory = $true)]
        [string]
        $RouteTableResourceGroupName
    )

    $routeTableObject = Get-AzRouteTable -Name $RouteTableName -ResourceGroupName $RouteTableResourceGroupName

    # Check that all routes exist and create/update as needed
    foreach ($Route in $Routes.Keys)    
    {
        if ((Test-AzDscRouteConfig -Name $Routes.$Route.Name -AddressPrefix $Routes.$Route.AddressPrefix -NextHopType $Routes.$Route.NextHopType `
        -NextHopIpAddress $Routes.$Route.NextHopIpAddress -RouteTableName $RouteTableName -RouteTableResourceGroupName $RouteTableResourceGroupName) `
        -eq $false)
        {
            # Create the route if it doesn't exist and update the route if it has incorrect settings
            if (!(Get-AzRouteConfig -RouteTable $routeTableObject -Name $Routes.$Route.Name -ErrorAction SilentlyContinue))
            {
                Write-Verbose "Creating route $($Routes.$Route.Name)"
                Add-AzRouteConfig -Name $Routes.$Route.Name -AddressPrefix $Routes.$Route.AddressPrefix -NextHopType $Routes.$Route.NextHopType `
                -NextHopIpAddress $Routes.$Route.NextHopIpAddress -RouteTable $routeTableObject | Set-AzRouteTable
            }
            else 
            {
                Write-Verbose "Updating route $($Routes.$Route.Name)"
                Set-AzRouteConfig -Name $Routes.$Route.Name -AddressPrefix $Routes.$Route.AddressPrefix -NextHopType $Routes.$Route.NextHopType `
                -NextHopIpAddress $Routes.$Route.NextHopIpAddress -RouteTable $routeTableObject | Set-AzRouteTable
            }
        }
    }

    # Find additional routes in route table and remove them
    $expectedRoutes = @()
    foreach ($Route in $Routes.Keys)
    {
        $expectedRoutes += $Routes.$Route.Name
    }

    $actualRoutes = Get-AzRouteConfig -RouteTable $routeTableObject

    $additionalRoutes = (Compare-Object -ReferenceObject $expectedRoutes -DifferenceObject $actualRoutes.Name).InputObject
    if ($additionalRoutes)
    {
        Write-Verbose "Additional routes found. Removing routes"
        foreach ($additionalRoute in $additionalRoutes)
        {
            Write-Verbose "Removing additional route $additionalRoute"
            Remove-AzRouteConfig -RouteTable $routeTableObject -Name $additionalRoute -Confirm:$false | `
            Set-AzRouteTable
        }
    }
}

function Test-AzDscNetworkSecurityRuleConfig
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [string]
        $NetworkSecurityGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $NetworkSecurityGroupResourceGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $Protocol,
        [parameter(Mandatory = $true)]
        [string]
        $SourcePortRange,
        [parameter(Mandatory = $true)]
        [string]
        $SourceAddressPrefix,
        [parameter(Mandatory = $true)]
        [string]
        $DestinationPortRange,
        [parameter(Mandatory = $true)]
        [string]
        $DestinationAddressPrefix,
        [parameter(Mandatory = $true)]
        [string]
        $Access,
        [parameter(Mandatory = $true)]
        [string]
        $Priority,
        [parameter(Mandatory = $true)]
        [string]
        $Direction
    )

    $nsgObject = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $NetworkSecurityGroupResourceGroupName
    $nsgRule = Get-AzNetworkSecurityRuleConfig -Name $Name -NetworkSecurityGroup $nsgObject

    if ($nsgRule.Protocol -eq $Protocol -and $nsgRule.SourcePortRange -eq $SourcePortRange -and $nsgRule.DestinationPortRange -eq `
    $DestinationPortRange -and $nsgRule.SourceAddressPrefix -eq $SourceAddressPrefix -and $nsgRule.DestinationAddressPrefix -eq `
    $DestinationAddressPrefix -and $nsgRule.Access -eq $Access -and $nsgrule.Priority -eq $Priority -and $nsgRule.Direction -eq `
    $Direction)
    {
        Write-Verbose "Network security group rule $Name exists and settings are correct"
        return $true
    }
    else 
    {
        Write-Verbose "Network security group rule $Name does not exist or settings are incorrect"    
        return $false
    }
}

function Set-AzDscNetworkSecurityRuleConfig 
{
    [cmdletbinding()]
    param 
    (
        [parameter(Mandatory = $true)]
        [hashtable]
        $NetworkSecurityGroupRules,
        [parameter(Mandatory = $true)]
        [string]
        $NetworkSecurityGroupName,
        [parameter(Mandatory = $true)]
        [string]
        $NetworkSecurityGroupResourceGroupName
    )

    $nsgObject = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $NetworkSecurityGroupResourceGroupName

    # Check that all routes exist and create/update as needed
    foreach ($NetworkSecurityGroupRule in $NetworkSecurityGroupRules.Keys)
    {
        if ((Test-AzDscNetworkSecurityRuleConfig -Name $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name -NetworkSecurityGroupName `
        $NetworkSecurityGroupName -NetworkSecurityGroupResourceGroupName $NetworkSecurityGroupResourceGroupName -Protocol `
        $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Protocol -SourcePortRange $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourcePortRange `
        -SourceAddressPrefix $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourceAddressPrefix -DestinationPortRange `
        $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationPortRange -DestinationAddressPrefix `
        $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationAddressPrefix -Access $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Access `
        -Priority $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Priority -Direction $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Direction) `
        -eq $false)
        {
            # Create the network security group rule if it doesn't exist and update the network security group rule if it has incorrect settings
            if (!(Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgObject -Name $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name `
            -ErrorAction SilentlyContinue))
            {
                Write-Verbose "Creating network security group rule $($NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name)"
                Add-AzNetworkSecurityRuleConfig `
                -Name $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name `
                -NetworkSecurityGroup $nsgObject `
                -Protocol $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Protocol `
                -SourcePortRange $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourcePortRange `
                -DestinationPortRange $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationPortRange `
                -SourceAddressPrefix $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourceAddressPrefix `
                -DestinationAddressPrefix $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationAddressPrefix `
                -Access $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Access `
                -Priority $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Priority `
                -Direction $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Direction `
                | Set-AzNetworkSecurityGroup
            }
            else 
            {
                Write-Verbose "Updating network security group rule $($NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name)"
                Set-AzNetworkSecurityRuleConfig `
                -Name $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name `
                -NetworkSecurityGroup $nsgObject `
                -Protocol $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Protocol `
                -SourcePortRange $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourcePortRange `
                -DestinationPortRange $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationPortRange `
                -SourceAddressPrefix $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.SourceAddressPrefix `
                -DestinationAddressPrefix $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.DestinationAddressPrefix `
                -Access $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Access `
                -Priority $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Priority `
                -Direction $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Direction `
                | Set-AzNetworkSecurityGroup
            }
        }
    }

    # Find additional rules in network security group and remove them
    $expectedRules = @()
    foreach ($NetworkSecurityGroupRule in $NetworkSecurityGroupRules.Keys)
    {
        $expectedRules += $NetworkSecurityGroupRules.$NetworkSecurityGroupRule.Name
    }

    $actualRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgObject
    $additionalRules = (Compare-Object -ReferenceObject $expectedRules -DifferenceObject $actualRules.Name).InputObject
    if ($additionalRules)
    {
        Write-Verbose "Additional network security rules found. Removing Rules"
        foreach ($additionalRule in $additionalRules)
        {
            Write-Verbose "Removing additional network security rule $additionalRule"
            Remove-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgObject -Name $additionalRule `
            | Set-AzNetworkSecurityGroup
        }
    }
}

function Start-AzDscIaaSDeployment
{
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $ProjectName,
        [parameter()]
        [string]
        $ResourceGroupName,
        [parameter()]
        [string]
        $Location = "WestEurope",
        [parameter()]
        [string]
        $VirtualNetworkName,
        [parameter()]
        [string]
        $VirtualNetworkResourceGroupName,
        [parameter(Mandatory = $true)]
        [array]
        $VirtualNetworkAddressPrefixes,
        [parameter()]
        [array]
        $VirtualNetworkDnsServers = ("10.0.0.10","10.0.0.11"),
        [parameter()]
        [boolean]
        $UpdateExistingVirtualNetwork = $false,
        [parameter(Mandatory = $true)]
        [hashtable]
        $Subnets,
        [parameter()]
        [boolean]
        $UpdateExistingSubnet = $false,
        [parameter()]
        [hashtable]
        $RemoteVirtualNetworks,
        [parameter()]
        [string]
        $RouteTableName,
        [parameter()]
        [hashtable]
        $Routes,
        [parameter()]
        [string]
        $NetworkSecurityGroupName,
        [parameter()]
        [hashtable]
        $NetworkSecurityGroupRules
    )

    # Generate parameters if undefined
    if (!$ResourceGroupName) {$ResourceGroupName = "RG-$ProjectName"}
    if (!$VirtualNetworkName) {$VirtualNetworkName = "VNET-$ProjectName"}
    if (!$VirtualNetworkResourceGroupName) {$VirtualNetworkResourceGroupName = $ResourceGroupName}
    if (!$RouteTableName) {$RouteTableName = "RT-$ProjectName"}
    if (!$NetworkSecurityGroupName) {$NetworkSecurityGroupName = "NSG-$ProjectName"}

    # Create resource group
    Set-AzDscResourceGroup -Name $resourceGroupName -Location $Location

    # Create virtual network
    Set-AzDscVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $VirtualNetworkResourceGroupName `
    -Location $Location -AddressPrefixes $VirtualNetworkAddressPrefixes -DnsServers $VirtualNetworkDnsServers `
    -UpdateExistingVirtualNetwork $UpdateExistingVirtualNetwork

    # Create virtual network peerings if RemoteVirtualNetworks specified
    if ($RemoteVirtualNetworks)
    {
        Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName $VirtualNetworkName -LocalVirtualNetworkResourceGroupName $resourceGroupName `
        -RemoteVirtualNetworks $RemoteVirtualNetworks
    }

    # Create route table
    Set-AzDscRouteTable -Name $RouteTableName -ResourceGroupName $resourceGroupName -Location $Location

    # Create network security group
    Set-AzDscNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $Location

    # Create routes
    Set-AzDscRouteConfig -Routes $Routes -RouteTableName $RouteTableName -RouteTableResourceGroupName $ResourceGroupName

    # Create subnet
    #Set-AzDscSubnet -Subnets $Subnets -RouteTableId (Get-AzRouteTable -Name $RouteTableName -ResourceGroupName $resourceGroupName).Id `
    #-VirtualNetworkName $VirtualNetworkName -VirtualNetworkResourceGroupName $VirtualNetworkResourceGroupName
}
