$configuration = @{
    ProjectName = "TEST-VM"
    Location = "WestEurope"
    VirtualNetworkAddressPrefixes = "10.128.64.8/29"
    VirtualNetworkDnsServers = ("10.0.0.10","10.0.0.11")
    UpdateExistingVirtualNetwork = $true
    Subnets = @{
        Name            = "SNET-TEST-VM"
        AddressPrefix   = "10.0.0.0/29"
    }
    RemoteVirtualNetworks = @{
        RemoteVirtualNetwork1 = @{
            Name              = "VNet-SharedServices-Test"
            ResourceGroupName = "RG-SharedServices-Test"
        }
        RemoteVirtualNetwork2 = @{
            Name              = "VNet-Test01-General"
            ResourceGroupName = "RG-Test01-NET"
        }
    }
    Routes = @{
        Route1 = @{
            Name                = "Internet"
            AddressPrefix       = "0.0.0.0/0"
            NextHopType         = "VirtualAppliance"
            NextHopIpAddress    = "10.0.0.1"
        }
    }
    NetworkSecurityGroupRules = @{
        Rule1 = @{
            Name                = "AllowRemoteDesktopInBound"
        }
    }
    Verbose = $true
}

Import-Module ".\AzureDsc\AzureDsc.psm1" -Force
. Start-AzDscIaaSDeployment @configuration
