$ProjectRoot = $env:BHProjectPath
$ModuleRoot = $env:BHModulePath
$ModuleName = $env:BHProjectName
$ModulePath = $env:BHPSModuleManifest
Import-Module $ModulePath -Force

# Use InModuleScope to expose Private functions
InModuleScope $ModuleName {

    Describe 'CIEdge Tests' {

        Mock Test-CIConnection -Verifiable {
            # Does not throw an exception if blank
            return
        }

        Context 'Input' {

            Mock Get-CIEdgeView -Verifiable {
                param ($Name)

                $CIEdgeView = New-Object 'VMware.VimAutomation.Cloud.Views.Gateway'
                $CIEdgeView.Name = $Name
                $CIEdgeView.Href = "$Name MockedHrefValue"
                $CIEdgeView.Id = "$Name MockedIdValue"

                Write-Output $CIEdgeView
            }

            Mock Get-CIEdgeXML -Verifiable {
                param ($Name)

                [xml]$EdgeXML = New-Object system.Xml.XmlDocument
                $EdgeXMLString = @"
<?xml version="1.0" encoding="UTF-8"?>
<EdgeGateway xmlns="http://www.vmware.com/vcloud/v1.5" status="1" name="$Name" id="urn:vcloud:gateway:1234abcd-1234-abcd-1234-123456789abc" href="https://api.vcloud.example.com/api/admin/edgeGateway/1234abcd-1234-abcd-1234-123456789abc" type="application/vnd.vmware.admin.edgeGateway+xml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/v1.5 http://10.10.10.10/api/v1.5/schema/master.xsd">
  <Description>$Name</Description>
    <Configuration>
        <GatewayBackingConfig>full</GatewayBackingConfig>
        <GatewayInterfaces>
            <GatewayInterface>
                <Name>InternalNetwork01</Name>
                <DisplayName>InternalNetwork01</DisplayName>
                <Network href="https://api.vcloud.example.com/api/admin/network/12345678-1234-abcd-1234-123456789abc" name="InternalNetwork01" type="application/vnd.vmware.admin.network+xml" />
                <InterfaceType>internal</InterfaceType>
                <SubnetParticipation>
                    <Gateway>192.168.1.1</Gateway>
                    <Netmask>255.255.255.224</Netmask>
                    <IpAddress>192.168.1.1</IpAddress>
                </SubnetParticipation>
                <ApplyRateLimit>false</ApplyRateLimit>
                <UseForDefaultRoute>false</UseForDefaultRoute>
            </GatewayInterface>
            <GatewayInterface>
                <Name>ExternalNetwork01</Name>
                <DisplayName>ExternalNetwork01</DisplayName>
                <Network href="https://api.vcloud.example.com/api/admin/network/abcdef-1234-abcd-1234-123456789abc" name="ExternalNetwork01" type="application/vnd.vmware.admin.network+xml" />
                <InterfaceType>uplink</InterfaceType>
                <SubnetParticipation>
                    <Gateway>11.22.33.44</Gateway>
                    <Netmask>255.255.255.248</Netmask>
                    <IpAddress>11.22.33.45</IpAddress>
                    <IpRanges>
                        <IpRange>
                            <StartAddress>11.22.33.44</StartAddress>
                            <EndAddress>11.22.33.45</EndAddress>
                        </IpRange>
                    </IpRanges>
                </SubnetParticipation>
                <ApplyRateLimit>false</ApplyRateLimit>
                <InRateLimit>100.0</InRateLimit>
                <OutRateLimit>100.0</OutRateLimit>
                <UseForDefaultRoute>true</UseForDefaultRoute>
            </GatewayInterface>
        </GatewayInterfaces>
        <EdgeGatewayServiceConfiguration xmlns="http://www.vmware.com/vcloud/v1.5">
            <GatewayDhcpService>
                <IsEnabled>false</IsEnabled>
            </GatewayDhcpService>
            <FirewallService>
                <IsEnabled>false</IsEnabled>
            </FirewallService>
            <NatService>
                <IsEnabled>false</IsEnabled>
            </NatService>
            <GatewayIpsecVpnService>
                <IsEnabled>false</IsEnabled>
            </GatewayIpsecVpnService>
            <StaticRoutingService>
                <IsEnabled>false</IsEnabled>
            </StaticRoutingService>
        </EdgeGatewayServiceConfiguration>
        <HaEnabled>false</HaEnabled>
        <UseDefaultRouteForDnsRelay>false</UseDefaultRouteForDnsRelay>
    </Configuration>
</EdgeGateway>
"@
                $EdgeXML.LoadXml($EdgeXMLString)

                Write-Output $EdgeXML
            }

            # Confirm parameter validation works as expected
            It 'Should accept a single string' {
                { Get-CIEdge -Name 'Edge01' } | Should Not Throw
            }
            It 'Should accept multiple strings' {
                { Get-CIEdge -Name 'Edge01', 'Edge02' } | Should Not Throw
            }
            It 'Should not accept object without Name property' {
                { Get-CIEdge -Name [PSCustomObject]@{ NotName='value' } } | Should Throw
            }

            # Ensure function accepts pipeline input
            It 'Should accept a single string via pipeline' {
                { 'Edge01' | Get-CIEdge } | Should Not Throw
            }
            It 'Should accept multiple strings via pipeline' {
                { 'Edge01', 'Edge02' | Get-CIEdge } | Should Not Throw
            }

            # Are Mocks called?
            It 'Mocks are called' {
                Assert-VerifiableMock
            }

        } # End Input Context

        Context 'Execution' {

            # Test logic flow
            Mock Get-CIEdgeView -Verifiable {$null}

            It 'Should write an Error Message if no Edge Views are found' {
                $null = Get-CIEdge -Name 'NotExist' -ErrorAction SilentlyContinue -ErrorVariable ErrorVar
                Write-Verbose "ErrorVar is $ErrorVar"
                $ErrorVar | Should be 'No Edge Gateways were found.'
            }
            It 'Should throw an Exception if no EdgeXML is found' {
                # Return Mock EdgeView first
                Mock Get-CIEdgeView -Verifiable {
                    param ($Name)

                    $CIEdgeView = New-Object 'VMware.VimAutomation.Cloud.Views.Gateway'
                    $CIEdgeView.Name = $Name
                    $CIEdgeView.Href = "$Name MockedHrefValue"
                    $CIEdgeView.Id = "$Name MockedIdValue"

                    Write-Output $CIEdgeView
                }

                { Get-CIEdge -Name 'NotExist' } | Should Throw
            }

            # Are Mocks called?
            It 'Mocks are called' {
                Assert-VerifiableMock
            }

        } # End Execution Context

        Context 'Output' {
            # Confirm object type is as expected
            # Check the correct amount of objects are returned
            # Ensure property structure is correct; both property names and values
        }

    } # End Describe

} # End InModuleScope
