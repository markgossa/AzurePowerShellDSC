# Introduction

Idempotent Azure Module to create IaaS solutions in Azure.

# Start-AzDscIaaSDeployment

## Required Parameters

### __-ProjectName__

Name of the project e.g. TEST-VM. In this case, the resource group will be created with the name RG-AMS-TEST-VM.

```yaml
Type: String

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-Location__

The location for all resources which are created.

```yaml
Type: String

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-VirtualNetworkName__:

This specifies the virtual network for the infrastructure. It will be created if it does not exist.

```yaml
Type: String

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-VirtualNetworkAddressPrefixes__:

This is a comma separated list of the address prefixes to set on the virtual network.

```yaml
Type: Array

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-VirtualNetworkDnsServers__:

This is a comma separated list of the DNS servers that will be set on the virtual network.

```yaml
Type: Array

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-Subnets__:

This is a hashtable of the subnets which includes the names and address prefixes of all required subnets. Subnets are created in the virtual network that is specified using the __VirtualNetworkName__ parameter.

```yaml
Type: Hashtable

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-Routes__:

This is a hashtable of the routes that will be created on the route table which will be associated with the subnets.

```yaml
Type: Hashtable

Required: True
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## Optional Parameters

### __-VirtualNetworkResourceGroupName__:

This specifies the resource group where the virtual network will be created. If not specified, it will be created in the same resource group as the other resources.

```yaml
Type: String

Required: False
Default value: Base resource group
Accept pipeline input: False
Accept wildcard characters: False
```

### __-ResourceGroupName__:

This is the name for the resource group where all resources will be created. If not specified, it is generated from the __-ProjectName__ parameter. For example, if the __ProjectName__ is "TEST-VM", the resource group will be called "RG-AMS-TEST-VM".

```yaml
Type: Array

Required: False
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-RemoteVirtualNetworks__:

This is a hashtable of the remote virtual networks that the virtual network should be peered to. If there is no peering then one will be created on the local and remote virtual networks. If there is a connected peering then no changes will be made. If there is a missing peering then this will be created. If there is an existing peering which is not in the connected state then this will be recreated on both the local and remote virtual network. If this parameter is not specified then no virtual network peerings will be created.

```yaml
Type: Array

Required: False
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-UpdateExistingVirtualNetwork__:

By default, if the virtual network exists, no settings will be changed e.g. Address Space or DNS servers. If you set this parameter to __True__ then the virtual network settings will be updated.

```yaml
Type: Boolean

Required: False
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### __-RouteTableName__:

This is the name for the route table that is created in the resource group. If the project name is TEST-VM, this defaults to RT-AMS-TEST-VM.

```yaml
Type: String

Required: False
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-NetworkSecurityGroupName__:

This is the name for the network security group that is created in the resource group. If the project name is TEST-VM, this defaults to NSG-AMS-TEST-VM.

```yaml
Type: String

Required: False
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### __-UpdateExistingSubnet__:

If a subnet already exists, its settings are updated by default (e.g Address Prefix, RouteTableId, NetworkSecurityGruopId). If this is not required, set this parameter to $false.

```yaml
Type: String

Required: False
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```
