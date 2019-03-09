# Test-VblAzureRmResourceGroup
## Return true if resource group exists in correct location
## Return false if resource group doesn't exist
## Return false if resource group exists in incorrect location

# Set-VblAzureRmResourceGroup
## Create resource group and return resource group output if does not exist
## Return resource group output if it exists

# Test-VblAzureRmVirtualNetwork
## Return true if virtual network exists with correct address prefixes, DNS servers, location and resource group name
## Return false if virtual network exists with incorrect address prefixes
## Return false if virtual network exists with incorrect DNS servers
## Return false if virtual network exists in incorrect location

# Set-VblAzureRmVirtualNetwork
## Create new virtual network if it doesn't exist
## Do nothing if virtual network exists and -UpdateExistingVirtualNetwork is false
## Do nothing if virtual network exists and -UpdateExistingVirtualNetwork is not specified
## Update virtual network and all settings if virtual network exists and -UpdateExistingVirtualNetwork is true

# Test-VblAzureRmVirtualNetworkPeering
## Return true if local and remote peering exist and both have a PeeringState of Connected
## Return false if local peering exists with PeeringState which is not Connected
## Return false if remote peering exists with PeeringState which is not Connected
## Return false if local peering does not exist
## Return false if remote peering does not exist

# Set-VblAzureRmVirtualNetworkPeering (hashtable of remote virtual networks)
## Do nothing if virtual network local and remote peering exists
## Do nothing if -CreateVirtualNetworkPeering is false and local peering does not exist
## Do nothing if -CreateVirtualNetworkPeering is false and remote peering does not exist
## Create new virtual network local peering if doesn't exist and -CreateVirtualNetworkPeering is true
## Create new virtual network remote peering if doesn't exist -CreateVirtualNetworkPeering is true

# Test-VblAzureRmSubnet
## Return true if subnet exist in correct virtual network with correct address prefix
## Return false if subnet does not exist in correct virtual network
## Return false if subnet exists in correct virtual network with incorrect address prefix
## Return false if subnet exists in correct virtual network with incorrect route table
## Return false if subnet exists in correct virtual network with incorrect network security group

# Set-VblAzureRmSubnet (hashtable input)
## Return null if subnet exists in correct virtual network with correct settings
## Create subnet with correct address prefix, network security group and route table if does not exist in virtual network
## Update network security group if subnet already exists
## Update route table if subnet already exists

# Test-VblAzureRmRouteTable
## Return true if route table exists in the correct resource group
## Return false if route table does not exist in the correct resource group

# Set-VblAzureRmRouteTable
## Do nothing if route table exists in Resource Group
## Create route table if does not exist in Resource Group

#Test-VblAzureRmNetworkSecurityGroup
## Return true if network security group exists in the correct resource group
## Return false if network security group does not exist in the correct resource group

# Set-VblAzureRmNetworkSecurityGroup
## Do nothing if network security group exists in Resource Group
## Create network security group if does not exist in Resource Group

#Test-VblAzureRmRouteConfig (single route input)
## Return true if routes match hashtable input
## Return false if route does not exist
## Return false if route has wrong NextHopType
## Return false if route has wrong NextHopIpAddress
## Return false if  has wrong AddressPrefix

# Set-VblAzureRmRouteConfig (hashtable input)
## Add route if route does not exist
## Do nothing if route exists with correct NextHopType, NextHopIpAddress and AddressPrefix
## Update route if exists with incorrect NextHopType
## Update route if exists with incorrect NextHopIpAddress
## Update route if exists with incorrect AddressPrefix
## Remove other existing routes in route table

# Test-VblAzureRmNetworkSecurityGroupRule (single rule input)
## Return true if network security group rule settings correct
## Return false if network security group rule does not exist
## Return false if network security group rule exists with incorrect Protocol
## Return false if network security group rule with incorrect SourcePortRange
## Return false if network security group rule with incorrect DestinationPortRange
## Return false if network security group rule exists with incorrect SourceAddressPrefix
## Return false if network security group rule exists with incorrect DestinationAddressPrefix
## Return false if network security group rule exists with incorrect Access
## Return false if network security group rule with incorrect Priority
## Return false if network security group rule with incorrect Direction

# Set-VblAzureRmNetworkSecurityGroupRules (hashtable input)
## Do nothing if network security group rule exists with correct Protocol, SourcePortRange, DestinationPortRange etc
## Add network security group rule if network security group rule does not exist on network security group 
## Update network security group rule if exists with incorrect Protocol
## Update network security group rule if exists with incorrect SourcePortRange
## Update network security group rule if exists with incorrect DestinationPortRange
## Update network security group rule if exists with incorrect SourceAddressPrefix
## Update network security group rule if exists with incorrect DestinationAddressPrefix
## Update network security group rule if exists with incorrect Access
## Update network security group rule if exists with incorrect Priority
## Update network security group rule if exists with incorrect Direction
## Remove other existing routes in route table












# Test-VblAzureRmVirtualMachineGeneralSettings
## Return true if virtual machine exists with correct size in resource group in correct location, availability set
## Return false if virtual machine exists in resource group in incorrect location
## Return false if virtual machine exists in resource group in incorrect availability set
## Return false if virtual machine exists in resource group with incorrect size
## Return false if virtual machine does not exist 

# Test-VblAzureRmVirtualMachineNetworkProfile
## Return true if network interface has correct DNS servers, PrivateIpAllocationMethod, PrivateIpAddress (if static)
## Return false if network interface has incorrect DNS servers, 
## Return false if network interface has incorrect PrivateIpAllocationMethod
## Return false if network interface has incorrect PrivateIpAddress (if static)

# Test-VblAzureRmVirtualMachineOSProfile
## Return true if OS profile has correct ComputerName and AdminUsername
## Return false if OS profile has incorrect ComputerName AdminUsername
## Return false if OS profile has incorrect AdminUsername

# Test-VblAzureRmVirtualMachineImage
## Return true if storage profile has correct image publisher, image offer, image sku, image version
## Return false if storage profile has incorrect image publisher
## Return false if storage profile has incorrect image offer
## Return false if storage profile has incorrect image sku
## Return false if storage profile has incorrect image version

# Test-VblAzureRmVirtualMachineOSDisk
## Return true if OS disk has correct has correct size and caching settings
## Return false if OS disk has incorrect size
## Return false if OS disk has incorrect caching settings

# Test-VblAzureRmVirtualMachineDataDisk
## Return true if data disks have correct has correct size and caching settings
## Return false if a single data disk has incorrect size
## Return false if a single data disk has caching settings

# Set-VblAzureRmVirtualMachine (VM name, subnet, static IP, OS)
## Create virtual machine if does not exist in resource group
## Do nothing if virtual machine exists in resource group and all settings correct and -UpdateExistingVirtualMachine is false
## Do nothing if virtual machine exists in resource group and all settings correct and -UpdateExistingVirtualMachine is not specified
## Destroy and recreate virtual machine if exists in resource group with incorrect image publisher and -UpdateExistingVirtualMachine is true
## Destroy and recreate virtual machine if exists in resource group with incorrect image offer and -UpdateExistingVirtualMachine is true
## Destroy and recreate virtual machine if exists in resource group with incorrect image sku and -UpdateExistingVirtualMachine is true
## Destroy and recreate virtual machine if exists in resource group with incorrect image version and -UpdateExistingVirtualMachine is true
## Destroy and recreate virtual machine if exists in resource group with incorrect availability set and -UpdateExistingVirtualMachine is true
## Destroy and recreate virtual machine if exists in resource group with incorrect ComputerName and -UpdateExistingVirtualMachine is true

# Test-VblAzureRmVirtualMachineAnsible
## Return true if ConfigureRemotingForAnsible VM extension exists and provisioning state is succeeded
## Return true if ConfigureRemotingForAnsible VM extension exists and provisioning state is not succeeded
## Return false if ConfigureRemotingForAnsible VM extension does not exist

# Enable-VblAzureRmVirtualMachineAnsible
## Do nothing if VM extension already exists and provisioning state is succeeded
## If VM extension does not already exist, create storage account and container and upload ps1 file then create VM extension 
## Delete and recreate VM extension if provisioning state is not succeeded

# Set-VblAzureRmTags (hashtable)
## Set tags on all resources in resource group

# Report error to VSTS:
## exit Error.Count
## -OutputFormat NUnitXml

# Enable verbose output everywhere

# Use JSON input instead of hashtable?
# Allow YAML input and convert to hashtable?