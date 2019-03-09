Import-Module ".\AzureDsc\AzureDsc.psm1" -Force
$VerbosePreference = "Continue"

Describe "New-AzDscInfrastructure" {
    Context "Test-AzDscResourceGroup" {
        It "Return true if resource group exists in correct location" {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]@{
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                }
            }

            Test-AzDscResourceGroup -Name "RG-TEST" -Location "WestEurope" | Should be $true
        } 

        It "Return false if resource group doesn't exist" {
            Mock -CommandName Get-AzResourceGroup -MockWith {}
            Test-AzDscResourceGroup -Name "RG-TEST" -Location "WestEurope" | Should be $false
        }

        It "Return false if resource group exists in incorrect location" {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]@{
                    ResourceGroupName   = "RG-TEST"
                    Location            = "EastUS"
                }
            }

            Test-AzDscResourceGroup -Name "RG-TEST" -Location "WestEurope" | Should be False
        }
    }

    Context "Set-AzDscResourceGroup" {
        It "Create resource group and return resource group output if does not exist" {
            Mock -CommandName Get-AzResourceGroup -MockWith {}
            Mock -CommandName New-AzResourceGroup -MockWith {
                [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]@{
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                }
            }

            (Set-AzDscResourceGroup -Name "RG-TEST" -Location "WestEurope").GetType().Name | Should be PSResourceGroup
            Assert-MockCalled -CommandName New-AzResourceGroup -Times 1 -Exactly -Scope It
        }

        It "Return null if resource group exists" {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]@{
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                }
            }

            Set-AzDscResourceGroup -Name "RG-TEST" -Location "WestEurope" | Should be $null
            Assert-MockCalled -CommandName New-AzResourceGroup -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzResourceGroup -Times 1 -Exactly -Scope It
        }
    }

    Context "Test-AzDscVirtualNetwork" {
        It "Returns true if Virtual Network exists in correct Resource Group and location with the correct DNS servers and Address Prefix" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" | Should be $true
        }

        It "Return false if virtual network exists with incorrect address prefixes" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/7"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" | Should be $false
        }

        It "Return false if virtual network exists with incorrect address prefixes if more than one address prefix" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8","172.28.0.0/16"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST" -AddressPrefixes "10.0.0.0/8","172.31.0.0/16" `
            -DnsServers "10.0.0.10","10.0.0.11" | Should be $false
        }

        It "Return false if virtual network exists with incorrect DNS servers" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST"  -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10" | Should be $false
        }

        It "Return false if virtual network exists with incorrect DNS servers when more than one DNS server" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST"  -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.12" | Should be $false
        }

        It "Return false if virtual network exists in incorrect location" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "EastUS"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Test-AzDscVirtualNetwork -Name "VNET-TEST" -Location "WestEurope" -ResourceGroupName "RG-TEST" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" | Should be $false
        }
    }

    Context "Set-AzDscVirtualNetwork" {
        It "Create new virtual network and return virtual network object if it doesn't exist" {
            Mock -CommandName Get-AzVirtualNetwork -MockWith {}
            Mock -CommandName New-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            (Set-AzDscVirtualNetwork -Name "VNET-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11").GetType().Name | Should be PSVirtualNetwork
            Assert-MockCalled -CommandName New-AzVirtualNetwork -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetwork -Times 2 -Exactly -Scope It
        }

        It "Do nothing and return null if virtual network exists and -UpdateExistingVirtualNetwork is false" {
            Mock -CommandName New-AzVirtualNetwork -MockWith {}
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Set-AzDscVirtualNetwork -Name "VNET-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" -UpdateExistingVirtualNetwork $false | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetwork -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetwork -Times 2 -Exactly -Scope It
        }

        It "Do nothing if virtual network exists and -UpdateExistingVirtualNetwork is not specified" {
            Mock -CommandName New-AzVirtualNetwork -MockWith {}
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }

            Set-AzDscVirtualNetwork -Name "VNET-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" -UpdateExistingVirtualNetwork $false | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetwork -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetwork -Times 2 -Exactly -Scope It
        }

        It "Update virtual network and all settings if virtual network exists with incorrect settings and -UpdateExistingVirtualNetwork is true" {
            Mock -CommandName New-AzVirtualNetwork -ParameterFilter {$Force} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.11"
                    }
                }
            }
            Mock -CommandName Get-AzVirtualNetwork -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name                = "VNET-TEST"
                    ResourceGroupName   = "RG-TEST"
                    Location            = "WestEurope"
                    AddressSpace        = [Microsoft.Azure.Commands.Network.Models.PSAddressSpace]@{
                        AddressPrefixes = "10.0.0.0/8"
                    }
                    DhcpOptions         = [Microsoft.Azure.Commands.Network.Models.PSDhcpOptions]@{
                        DnsServers      = "10.0.0.10","10.0.0.12"
                    }
                }
            }

            (Set-AzDscVirtualNetwork -Name "VNET-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" -AddressPrefixes "10.0.0.0/8" `
            -DnsServers "10.0.0.10","10.0.0.11" -UpdateExistingVirtualNetwork $true).GetType().Name | Should be PSVirtualNetwork
            Assert-MockCalled -CommandName New-AzVirtualNetwork -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetwork -Times 2 -Exactly -Scope It
        }
    }

    Context "Test-AzDscVirtualNetworkPeering" {
        It "Return true if local and remote peering exist and both have a PeeringState of Connected" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST"
                    ResourceGroupName       = "RG-TEST"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST"
                    VirtualNetworkName      = "VNET-REMOTE-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworkName "VNET-REMOTE-TEST" -RemoteVirtualNetworkResourceGroupName "RG-REMOTE-TEST" | Should be $true
        }

        It "Return false if local peering exists with PeeringState which is not Connected" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST"
                    ResourceGroupName       = "RG-TEST"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Initializing"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST"
                    VirtualNetworkName      = "VNET-REMOTE-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworkName "VNET-REMOTE-TEST" -RemoteVirtualNetworkResourceGroupName "RG-REMOTE-TEST" | Should be $false
        }

        It "Return false if remote peering exists with PeeringState which is not Connected" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST"
                    ResourceGroupName       = "RG-TEST"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST"
                    VirtualNetworkName      = "VNET-REMOTE-TEST"
                    PeeringState            = "Initializing"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworkName "VNET-REMOTE-TEST" -RemoteVirtualNetworkResourceGroupName "RG-REMOTE-TEST" | Should be $false
        }


        It "Return false if local peering does not exist" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST"
                    ResourceGroupName       = "RG-TEST"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST"
                    VirtualNetworkName      = "VNET-REMOTE-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworkName "VNET-REMOTE-TEST" -RemoteVirtualNetworkResourceGroupName "RG-REMOTE-TEST" | Should be $false
        }

        It "Return false if remote peering does not exist" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST"
                    ResourceGroupName       = "RG-TEST"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST"
                    VirtualNetworkName      = "VNET-REMOTE-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST-2"
                    }
                }
            }

            Test-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworkName "VNET-REMOTE-TEST" -RemoteVirtualNetworkResourceGroupName "RG-REMOTE-TEST" | Should be $false
        }
    }

    Context "Set-AzDscVirtualNetworkPeering" {
        It "Do nothing if virtual network local and remote peering exists" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-1"
                    ResourceGroupName       = "RG-TEST-1"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                    }
                }
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-2"
                    ResourceGroupName       = "RG-TEST-2"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-1"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-1"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-2"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-2"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            $RemoteVirtualNetworks = @{
                RemoteVirtualNetwork1 = @{
                    Name              = "VNET-REMOTE-TEST-1"
                    ResourceGroupName = "RG-REMOTE-TEST-1"
                }
                RemoteVirtualNetwork2 = @{
                    Name              = "VNET-REMOTE-TEST-2"
                    ResourceGroupName = "RG-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Add-AzVirtualNetworkPeering -MockWith {}

            Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworks $RemoteVirtualNetworks -CreateVirtualNetworkPeering $true | Should be $null
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -Times 0 -Exactly -Scope It
        }

        It "Do nothing if -CreateVirtualNetworkPeering is false and local peering does not exist" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {}

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-1"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-1"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-2"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-2"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            $RemoteVirtualNetworks = @{
                RemoteVirtualNetwork1 = @{
                    Name              = "VNET-REMOTE-TEST-1"
                    ResourceGroupName = "RG-REMOTE-TEST-1"
                }
                RemoteVirtualNetwork2 = @{
                    Name              = "VNET-REMOTE-TEST-2"
                    ResourceGroupName = "RG-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Add-AzVirtualNetworkPeering -MockWith {}

            Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworks $RemoteVirtualNetworks -CreateVirtualNetworkPeering $false | Should be $null
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -Times 0 -Exactly -Scope It
        }

        It "Do nothing if -CreateVirtualNetworkPeering is false and a remote peering does not exist" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }

            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-1"
                    ResourceGroupName       = "RG-TEST-1"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                    }
                }
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-2"
                    ResourceGroupName       = "RG-TEST-2"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} -MockWith {}

            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-2"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-2"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }

            $RemoteVirtualNetworks = @{
                RemoteVirtualNetwork1 = @{
                    Name              = "VNET-REMOTE-TEST-1"
                    ResourceGroupName = "RG-REMOTE-TEST-1"
                }
                RemoteVirtualNetwork2 = @{
                    Name              = "VNET-REMOTE-TEST-2"
                    ResourceGroupName = "RG-REMOTE-TEST-2"
                }
            }

            Mock -CommandName Add-AzVirtualNetworkPeering -MockWith {}

            Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworks $RemoteVirtualNetworks -CreateVirtualNetworkPeering $false | Should be $null
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -Times 0 -Exactly -Scope It
        }

        It "Create new virtual network local peering if it doesn't exist and -CreateVirtualNetworkPeering is true" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
        
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                }
            }
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {}
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-1"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-1"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-2"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-2"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }
        
            $RemoteVirtualNetworks = @{
                RemoteVirtualNetwork1 = @{
                    Name              = "VNET-REMOTE-TEST-1"
                    ResourceGroupName = "RG-REMOTE-TEST-1"
                }
                RemoteVirtualNetwork2 = @{
                    Name              = "VNET-REMOTE-TEST-2"
                    ResourceGroupName = "RG-REMOTE-TEST-2"
                }
            }
        
            Mock -CommandName Add-AzVirtualNetworkPeering -MockWith {}
            Mock -CommandName Remove-AzVirtualNetworkPeering -MockWith {}
        
            Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworks $RemoteVirtualNetworks -CreateVirtualNetworkPeering $true | Should be $null
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} `
            -Times 4 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1" -and $RemoteVirtualNetworkId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2" -and $RemoteVirtualNetworkId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"} `
            -Times 1 -Exactly -Scope It
        }

        It "Create new virtual network remote peering if it doesn't exist and -CreateVirtualNetworkPeering is true" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
        
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-1"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                }
            }
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-1"
                    ResourceGroupName       = "RG-TEST-1"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-1/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-1"
                    }
                }
                @{
                    Name                    = "Peer-to-VNET-REMOTE-TEST-2"
                    ResourceGroupName       = "RG-TEST-2"
                    VirtualNetworkName      = "VNET-TEST"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-REMOTE-TEST-2/providers/Microsoft.Network/virtualNetworks/VNET-REMOTE-TEST-2"
                    }
                }
            }
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} -MockWith {}
        
            Mock -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} -MockWith {
                @{
                    Name                    = "Peer-to-VNET-TEST"
                    ResourceGroupName       = "RG-REMOTE-TEST-2"
                    VirtualNetworkName      = "VNET-REMOTE-TEST-2"
                    PeeringState            = "Connected"
                    RemoteVirtualNetwork    = @{
                        Id  = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                    }
                }
            }
        
            $RemoteVirtualNetworks = @{
                RemoteVirtualNetwork1 = @{
                    Name              = "VNET-REMOTE-TEST-1"
                    ResourceGroupName = "RG-REMOTE-TEST-1"
                }
                RemoteVirtualNetwork2 = @{
                    Name              = "VNET-REMOTE-TEST-2"
                    ResourceGroupName = "RG-REMOTE-TEST-2"
                }
            }
        
            Mock -CommandName Add-AzVirtualNetworkPeering -MockWith {}
            Mock -CommandName Remove-AzVirtualNetworkPeering -MockWith {}
        
            Set-AzDscVirtualNetworkPeering -LocalVirtualNetworkName "VNET-TEST" -LocalVirtualNetworkResourceGroupName "RG-TEST" `
            -RemoteVirtualNetworks $RemoteVirtualNetworks -CreateVirtualNetworkPeering $true | Should be $null
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-TEST"} `
            -Times 3 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-1"} `
            -Times 2 -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzVirtualNetworkPeering -ParameterFilter {$VirtualNetworkName -eq "VNET-REMOTE-TEST-2"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzVirtualNetworkPeering -ParameterFilter {$Name -eq "VNET-TEST" -and $RemoteVirtualNetworkId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"} `
            -Times 1 -Exactly -Scope It
        }
    }

    Context "Test-AzDscSubnet" {
        It "Return true if subnet exists in correct virtual network with correct address prefix, route table and network security group" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -MockWith {
                @{
                    Name                    = "SUBNET-TEST"
                    AddressPrefix           = "10.0.0.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }
            
            Test-AzDscSubnet -Name "SUBNET-TEST" -AddressPrefix "10.0.0.0/24" -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST"`
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $true
        }

        It "Return false if subnet does not exist in correct virtual network" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -MockWith {}
            
            Test-AzDscSubnet -Name "SUBNET-TEST" -AddressPrefix "10.0.0.0/24" -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST"`
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $false
        }

        It "Return false if subnet exists in correct virtual network with incorrect address prefix" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -MockWith {
                @{
                    Name                    = "SUBNET-TEST"
                    AddressPrefix           = "10.0.0.0/25"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }
            
            Test-AzDscSubnet -Name "SUBNET-TEST" -AddressPrefix "10.0.0.0/24" -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST"`
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $false
        }

        It "Return false if subnet exists in correct virtual network with incorrect route table" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -MockWith {
                @{
                    Name                    = "SUBNET-TEST"
                    AddressPrefix           = "10.0.0.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST-1"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }
            
            Test-AzDscSubnet -Name "SUBNET-TEST" -AddressPrefix "10.0.0.0/24" -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST"`
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $false
        }

        It "Return false if subnet exists in correct virtual network with incorrect network security group" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -MockWith {
                @{
                    Name                    = "SUBNET-TEST"
                    AddressPrefix           = "10.0.0.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST-1"
                    }
                }
            }
            
            Test-AzDscSubnet -Name "SUBNET-TEST" -AddressPrefix "10.0.0.0/24" -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST"`
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $false
        }
    }

    Context "Set-AzDscSubnet" {
        It "Return null if subnet exists in correct virtual network with correct settings" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-1"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-1"
                    AddressPrefix           = "10.0.1.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-2"
                    AddressPrefix           = "10.0.2.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName New-AzVirtualNetworkSubnetConfig -MockWith {}
            Mock -CommandName Set-AzVirtualNetworkSubnetConfig -MockWith {}

            $subnets = @{
                Subnet1 = @{
                    Name            = "SUBNET-TEST-1"
                    AddressPrefix   = "10.0.1.0/24"
                }
                Subnet2 = @{
                    Name            = "SUBNET-TEST-2"
                    AddressPrefix   = "10.0.2.0/24"
                }
            }
            
            Set-AzDscSubnet -Subnets $subnets -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST" `
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetworkSubnetConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzVirtualNetworkSubnetConfig -Times 0 -Exactly -Scope It
        }
        
        It "Create subnet with correct address prefix, network security group and route table if does not exist in virtual network" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-1"} -MockWith {}

            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-2"
                    AddressPrefix           = "10.0.2.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName New-AzVirtualNetworkSubnetConfig -MockWith {}
            Mock -CommandName Set-AzVirtualNetworkSubnetConfig -MockWith {}

            $subnets = @{
                Subnet1 = @{
                    Name            = "SUBNET-TEST-1"
                    AddressPrefix   = "10.0.1.0/24"
                }
                Subnet2 = @{
                    Name            = "SUBNET-TEST-2"
                    AddressPrefix   = "10.0.2.0/24"
                }
            }
            
            Set-AzDscSubnet -Subnets $subnets -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST" `
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetworkSubnetConfig -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzVirtualNetworkSubnetConfig -Times 0 -Exactly -Scope It
        }

        It "Update network security group if subnet already exists" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-1"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-1"
                    AddressPrefix           = "10.0.1.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-2"
                    AddressPrefix           = "10.0.2.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST-2"
                    }
                }
            }

            Mock -CommandName New-AzVirtualNetworkSubnetConfig -MockWith {}
            Mock -CommandName Set-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2" -and $NetworkSecurityGroupId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"} -MockWith {}

            $subnets = @{
                Subnet1 = @{
                    Name            = "SUBNET-TEST-1"
                    AddressPrefix   = "10.0.1.0/24"
                }
                Subnet2 = @{
                    Name            = "SUBNET-TEST-2"
                    AddressPrefix   = "10.0.2.0/24"
                }
            }
            
            Set-AzDscSubnet -Subnets $subnets -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST" `
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetworkSubnetConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2" -and $NetworkSecurityGroupId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"} -Times 1 -Exactly -Scope It
        }

        It "Update route table if subnet already exists" {
            Mock -CommandName Get-AzVirtualNetwork -ParameterFilter {$Name -eq "VNET-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]@{
                    Name = "VNET-TEST"
                    Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/virtualNetworks/VNET-TEST"
                }
            }
            
            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-1"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-1"
                    AddressPrefix           = "10.0.1.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName Get-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2"} -MockWith {
                @{
                    Name                    = "SUBNET-TEST-2"
                    AddressPrefix           = "10.0.2.0/24"
                    VirtualNetwork          = "VNET-TEST"
                    RouteTable              = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST-2"
                    }
                    NetworkSecurityGroup    = @{
                        Id = "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST"
                    }
                }
            }

            Mock -CommandName New-AzVirtualNetworkSubnetConfig -MockWith {}
            Mock -CommandName Set-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2" -and $RouteTableId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"} -MockWith {}

            $subnets = @{
                Subnet1 = @{
                    Name            = "SUBNET-TEST-1"
                    AddressPrefix   = "10.0.1.0/24"
                }
                Subnet2 = @{
                    Name            = "SUBNET-TEST-2"
                    AddressPrefix   = "10.0.2.0/24"
                }
            }
            
            Set-AzDscSubnet -Subnets $subnets -VirtualNetworkName "VNET-TEST" -VirtualNetworkResourceGroupName "RG-TEST" `
            -RouteTableId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST" `
            -NetworkSecurityGroupId "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/networkSecurityGroups/NSG-TEST" `
            | Should be $null
            Assert-MockCalled -CommandName New-AzVirtualNetworkSubnetConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzVirtualNetworkSubnetConfig -ParameterFilter {$Name -eq "SUBNET-TEST-2" -and $RouteTableId -eq `
            "/subscriptions/12345678-9012-3456-789012345678/resourceGroups/RG-TEST/providers/Microsoft.Network/routeTables/RT-TEST"} -Times 1 -Exactly -Scope It
        }
    }

    Context "Test-AzDscRouteTable" {
        It "Return true if route table exists in the correct resource group" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }

            Test-AzDscRouteTable -Name "RT-TEST" -ResourceGroupName "RG-TEST" | Should be $true
            Assert-MockCalled -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }

        It "Return false if route table does not exist in the correct resource group" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {}

            Test-AzDscRouteTable -Name "RT-TEST" -ResourceGroupName "RG-TEST" | Should be $false
            Assert-MockCalled -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }
    }

    Context "Set-AzDscRouteTable" {
        It "Do nothing if route table exists in Resource Group" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }

            Mock -CommandName New-AzRouteTable -MockWith {}

            Set-AzDscRouteTable -Name "RT-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" | Should be $null
            Assert-MockCalled -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
            Assert-MockCalled -CommandName New-AzRouteTable -Exactly -Times 0 -Scope It
        }

        It "Create route table if does not exist in Resource Group" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {}
            Mock -CommandName New-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }

            (Set-AzDscRouteTable -Name "RT-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope").Name | Should be "RT-TEST"
            Assert-MockCalled -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
            Assert-MockCalled -CommandName New-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }
    }
    
    Context "Test-AzDscNetworkSecurityGroup" {
        It "Return true if network security group exists in the correct resource group" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                = "NSG-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
    
            Test-AzDscNetworkSecurityGroup -Name "NSG-TEST" -ResourceGroupName "RG-TEST" | Should be $true
            Assert-MockCalled -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }
    
        It "Return false if network security group does not exist in the correct resource group" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {}
    
            Test-AzDscNetworkSecurityGroup -Name "NSG-TEST" -ResourceGroupName "RG-TEST" | Should be $false
            Assert-MockCalled -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }
    }
    
    Context "Set-AzDscNetworkSecurityGroup" {
        It "Do nothing if network security group exists in Resource Group" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                = "NSG-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
    
            Mock -CommandName New-AzNetworkSecurityGroup -MockWith {}
    
            Set-AzDscNetworkSecurityGroup -Name "NSG-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
            Assert-MockCalled -CommandName New-AzNetworkSecurityGroup -Exactly -Times 0 -Scope It
        }
    
        It "Create network security group if does not exist in Resource Group" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {}
            Mock -CommandName New-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                = "NSG-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
    
            (Set-AzDscNetworkSecurityGroup -Name "NSG-TEST" -ResourceGroupName "RG-TEST" -Location "WestEurope").Name | Should be "NSG-TEST"
            Assert-MockCalled -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
            Assert-MockCalled -CommandName New-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST" -and $ResourceGroupName -eq "RG-TEST"} -Exactly -Times 1 `
            -Scope It
        }
    }

    Context "Test-AzDscRouteConfig" {
        It "Return true if routes match hashtable input" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Test-AzDscRouteConfig -Name "Internet" -NextHopType "VirtualAppliance" -AddressPrefix "0.0.0.0/0" -NextHopIpAddress "10.128.31.36" -RouteTableName `
            "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $true
        }

        It "Return false if route does not exist" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {}

            Test-AzDscRouteConfig -Name "Internet" -NextHopType "VirtualAppliance" -AddressPrefix "0.0.0.0/0" -NextHopIpAddress "10.128.31.36" -RouteTableName `
            "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $false
        }

        It "Return false if route has wrong NextHopType" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualNetworkGateway"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Test-AzDscRouteConfig -Name "Internet" -NextHopType "VirtualAppliance" -AddressPrefix "0.0.0.0/0" -NextHopIpAddress "10.128.31.36" -RouteTableName `
            "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $false
        }

        It "Return false if route has wrong NextHopIpAddress" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.38"
                }
            }

            Test-AzDscRouteConfig -Name "Internet" -NextHopType "VirtualAppliance" -AddressPrefix "0.0.0.0/0" -NextHopIpAddress "10.128.31.36" -RouteTableName `
            "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $false
        }

        It "Return false if route has wrong AddressPrefix" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "10.0.0.0/8"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Test-AzDscRouteConfig -Name "Internet" -NextHopType "VirtualAppliance" -AddressPrefix "0.0.0.0/0" -NextHopIpAddress "10.128.31.36" -RouteTableName `
            "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $false
        }
    }

    Context "Set-AzDscRouteConfig" {
        It "Do nothing if route exists with correct NextHopType, NextHopIpAddress and AddressPrefix" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Add route if route does not exist" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {}

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Add multiple routes if they do not exist" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {}

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {}

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Add-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Update route if exists with incorrect NextHopType" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualGateway"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Update route if exists with incorrect NextHopIpAddress" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.38"
                }
            }

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Update route if exists with incorrect AddressPrefix" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.4.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 0 -Scope It
        }

        It "Remove other existing routes in route table" {
            Mock -CommandName Get-AzRouteTable -ParameterFilter {$Name -eq "RT-TEST" -and $ResourceGroupName -eq "RG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRouteTable]@{
                    Name                = "RT-TEST"
                    ResourceGroupName   = "RG-TEST"
                }
            }
            
            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "Internet"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -ParameterFilter {$Name -eq "HeadOffice"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Mock -CommandName Get-AzRouteConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "Internet"
                        AddressPrefix       = "0.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                        Name                = "HeadOffice"
                        AddressPrefix       = "10.0.0.0/0"
                        NextHopType         = "VirtualAppliance"
                        NextHopIpAddress    = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                    = "AdditionalRoute1"
                    AddressPrefix           = "0.0.0.0/0"
                    NextHopType             = "VirtualAppliance"
                    NextHopIpAddress        = "10.128.31.36"
                }
                [Microsoft.Azure.Commands.Network.Models.PSRoute]@{
                    Name                    = "AdditionalRoute2"
                    AddressPrefix           = "0.0.0.0/0"
                    NextHopType             = "VirtualAppliance"
                    NextHopIpAddress        = "10.128.31.36"
                }
            }

            Mock -CommandName Add-AzRouteConfig -MockWith {}
            Mock -CommandName Set-AzRouteConfig -MockWith {}
            Mock -CommandName Remove-AzRouteConfig -MockWith {}

            $routes = @{
                Route1 = @{
                    Name                = "Internet"
                    AddressPrefix       = "0.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
                Route2 = @{
                    Name                = "HeadOffice"
                    AddressPrefix       = "10.0.0.0/0"
                    NextHopType         = "VirtualAppliance"
                    NextHopIpAddress    = "10.128.31.36"
                }
            }

            Set-AzDscRouteConfig -Routes $routes -RouteTableName "RT-TEST" -RouteTableResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Add-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Set-AzRouteConfig -Exactly -Times 0 -Scope It
            Assert-MockCalled -CommandName Remove-AzRouteConfig -Exactly -Times 2 -Scope It
        }
    }

    Context "Test-AzDscNetworkSecurityRuleConfig" {
        It "Return true if network security group rule settings correct" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $true
        }

        It "Return false if network security group rule does not exist" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {}

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule exists with incorrect Protocol" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule with incorrect SourcePortRange" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"45644,7846"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule with incorrect DestinationPortRange" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,78433268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule exists with incorrect SourceAddressPrefix" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"10.120.125.0/29"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule exists with incorrect DestinationAddressPrefix" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29, 10.128.115.0/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule exists with incorrect Access" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Deny"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule with incorrect Priority" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "102"
                    Direction                   = "Outbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }

        It "Return false if network security group rule with incorrect Direction" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Test-AzDscNetworkSecurityRuleConfig -Name "ADTCPOutbound" -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" -Protocol "TCP" -SourcePortRange "*" -DestinationPortRange "389,3268,88,464" `
            -SourceAddressPrefix "*" -DestinationAddressPrefix "10.128.120.48/29" -Access "Allow" -Priority "100" -Direction Outbound | `
            Should be $false
        }
    }

    Context "Set-AzDscNetworkSecurityRuleConfig" {
        It "Do nothing if network security group rule exists with correct Protocol, SourcePortRange, DestinationPortRange etc" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
        }

        It "Add network security group rule if network security group rule does not exist on network security group " {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {}
            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect Protocol" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect SourcePortRange" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "400-500"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect DestinationPortRange" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389, 3390"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect SourceAddressPrefix" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "10.128.125.4"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect DestinationAddressPrefix" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/28"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect Access" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Deny"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect Priority" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "104"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Update network security group rule if exists with incorrect Direction" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 2 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -ParameterFilter {$name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
        }

        It "Remove other existing routes in route table" {
            Mock -CommandName Get-AzNetworkSecurityGroup -ParameterFilter {$Name -eq "NSG-TEST"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]@{
                    Name                        = "NSG-TEST"
                    ResourceGroupName           = "RG-TEST"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Mock -CommandName Get-AzNetworkSecurityRuleConfig -MockWith {
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"389,3268,88,464"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"53,88"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"3389"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "AllowAllInbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"*"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"*"
                    Access                      = "Allow"
                    Priority                    = "110"
                    Direction                   = "Inbound"
                }
                [Microsoft.Azure.Commands.Network.Models.PSSecurityRule]@{
                    Name                        = "AllowAllOutbound"
                    Protocol                    = "*"
                    SourcePortRange             = [System.Collections.Generic.List[String]]"*"
                    DestinationPortRange        = [System.Collections.Generic.List[String]]"*"
                    SourceAddressPrefix         = [System.Collections.Generic.List[String]]"*"
                    DestinationAddressPrefix    = [System.Collections.Generic.List[String]]"*"
                    Access                      = "Allow"
                    Priority                    = "110"
                    Direction                   = "Outbound"
                }
            }

            Mock -CommandName Add-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Set-AzNetworkSecurityRuleConfig -MockWith {}
            Mock -CommandName Remove-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "AllowAllInbound"} -MockWith {}
            Mock -CommandName Remove-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "AllowAllOutbound"} -MockWith {}

            $nsgRules = @{
                Rule1 = @{
                    Name                        = "ADTCPOutbound"
                    Protocol                    = "TCP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "389,3268,88,464"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Outbound"
                }
                Rule2 = @{
                    Name                        = "ADUDPOutbound"
                    Protocol                    = "UDP"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "53,88"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.120.48/29"
                    Access                      = "Allow"
                    Priority                    = "101"
                    Direction                   = "Outbound"
                }
                Rule3 = @{
                    Name                        = "RDPInbound"
                    Protocol                    = "*"
                    SourcePortRange             = "*"
                    DestinationPortRange        = "3389"
                    SourceAddressPrefix         = "*"
                    DestinationAddressPrefix    = "10.128.121.64/29"
                    Access                      = "Allow"
                    Priority                    = "100"
                    Direction                   = "Inbound"
                }
            }

            Set-AzDscNetworkSecurityRuleConfig -NetworkSecurityGroupRules $nsgRules -NetworkSecurityGroupName "NSG-TEST" `
            -NetworkSecurityGroupResourceGroupName "RG-TEST" | Should be $null
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADTCPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "ADUDPOutbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Get-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "RDPInbound"} -Times 1 `
            -Exactly -Scope It
            Assert-MockCalled -CommandName Add-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Set-AzNetworkSecurityRuleConfig -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName Remove-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "AllowAllInbound"} `
            -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName Remove-AzNetworkSecurityRuleConfig -ParameterFilter {$Name -eq "AllowAllOutbound"} `
            -Times 1 -Exactly -Scope It
        }
    }
}
