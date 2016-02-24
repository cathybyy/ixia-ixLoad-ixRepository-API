package provide IxRepository  1.4

####################################################################################################
# IxRepository.tcl--
#   This file implements the Tcl encapsulation of IxRepository interface for Netgear.
#
# Copyright (c) Ixia technologies, Inc.
# Change made
# Version 1.0
# a. Le Yu-- Create
# Version 1.1
# b. Le Yu-- Merge with Netgear code
# Version 1.3
# c. Le Yu-- Add stop method
# Version 1.4
# d. Le Yu-- Change the collect stats way
#################################################################################################### 


namespace eval IXIA {
    namespace export *
    
    package require registry

    proc GetEnvTcl { product } {       
        set productKey     "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
        if { [ catch {
                set versionKey     [ registry keys $productKey ]
        } err ] } {
                return ""
        }        
        
        #set latestKey      [ lindex $versionKey end ]
        set latestKey      [ lindex $versionKey 0 ]
        set mutliVKeyIndex [ lsearch $versionKey "Multiversion" ]
        if { $mutliVKeyIndex > 0 } {
           set latestKey   [ lindex $versionKey [ expr $mutliVKeyIndex - 2 ] ]
        }
        set installInfo    [ append productKey \\ $latestKey \\ InstallInfo ]            
        return             "[ registry get $installInfo  HOMEDIR ]/TclScripts/bin/ixiawish.tcl"   
    }    
    
    # IxOS is optional 
    set ixPath [ GetEnvTcl IxOS ]
    if { [file exists $ixPath] == 1 } {
        source [ GetEnvTcl IxOS ]
        package require IxTclHal
        package require Mpexpr
    }
    
    # Must make sure IxLoad is installed properly
    set ixPath [ GetEnvTcl IxLoad ]
    if { [file exists $ixPath] == 1 } {
        source $ixPath
    } else {
        error "IxLoad doesn't install properly on this system"
    }
    
    package require IxLoad
    package require statCollectorUtils
    
    variable NS                 statCollectorUtils
    variable Debug              0
    variable repository         ""
    variable testController     ""
    variable stats              [list]
    variable stats_info_list    {}
    variable SelectedStats      {}
    
    #--
    # Load the repository
    #--
    # Parameters:
    #       repPath: the repository file absolute path
    # Return:
    #       repository obj if got success
    #       raise error and return nil if failed
    #--
    proc loadRepository { repPath } {
        set tag "proc loadRepository [info script]"
        Deputs "----- TAG: $tag -----"
   
        if { ![ file exists $repPath ] } {
            error "Repository: $repPath file not found..."
        } 
        set IXIA::repository [ ::IxLoad new ixRepository -name $repPath ]
        Deputs "repository = $IXIA::repository "
        return $IXIA::repository
    }
   
    #--
    # Reboot port CPU
    #--
    # Parameters: 
    #       chasIndex: chassis index in chassis chain
    #       portList: port list to be rebooted
    #       reset: whether to reset to default factory configuration
    # Return:
    #        0 if got success
    #        raise error if failed
    #--
    proc reboot { chasIndex portList { reset 0 } { block 0 } } {
        set tag "proc reboot [info script]"
        Deputs "----- TAG: $tag -----"
        
        set chassisChain [ $IXIA::repository cget -chassisChain ]
        if { [ llength $chassisChain ] == 0 } {
            Deputs "There's no chassis added into chassis chain, please make sure add one like 192.168.0.111..."
            return
        }
        if { [ llength $chassisChain ] <= $chasIndex } {
            Deputs "Out of index for chassis chain(length:[llength $chassisChain])...$chasIndex "
            set chasIndex 0
        }
        set chassis      [ lindex [ $chassisChain getChassisNames ] $chasIndex ]
        Deputs "connect to chassis:$chassis"
        ixConnectToChassis $chassis
        Deputs "connecting done..."
        #-- create port group
        set grpId 1
        while { ![ portGroup canUse $grpId ] } {
            incr grpId
        }
        portGroup create $grpId
        #-- add port list
        foreach port $portList {
            Deputs "port:$port"
            if { [ regexp {[\/|\.]} $port spliter ] } {
                set portInfo [ split $port $spliter ]
                eval portGroup add $grpId $portInfo
                if { $reset } {
                    eval port setFactoryDefaults  $portInfo
                    eval port write $portInfo
                }
                #-- if run in a block way,
                #    un-comment following line and comment
                #    command for portGroup reset CPU
                if { $block } {
                    eval portCpu reset $portInfo
                }
            } else {
                Deputs "Wrong format of port...$port"
            }
        }
        #-- reset CPU
        if { !$block } {
           portGroup setCommand $grpId rebootLocalCPU
        }
        
        #-- delete port group
        portGroup destroy $grpId
        
        ixDisconnectFromChassis $chassis
        return 0
      
    }
   
    #--
    # Modify the repository
    #--
    # Parameters: |key, value|
    #       - chassis: chassis IP address or hostname
    #       - user   : login user
    # Return:
    #        0 if got success
    #        raise error if failed 
    #--  
    proc configRepository { args } {
        set tag "proc configRepository [info script]"
        Deputs "----- TAG: $tag -----"
       
        set activeTest [ getActiveTest ]
        # Param collection --      
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key---$value"
            switch -exact -- $key {
                -chassis {
                    set chassis $value
                }
                -user {
                    set user $value
                }
            }
        }
       
        if { [ info exists chassis ] } {
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            set chasList [$chassisChain getChassisNames]
            foreach chasName $chasList {
                # Removed all Chassises in current configuration, otherwise we may get
                # refresh error message in run 
                $chassisChain deleteChassisByName $chasName
            }
            
            # Add new Chassises into chassisChain
            foreach chas $chassis {            
                Deputs "add chas = $chas into the chassischain!"
                $chassisChain addChassis $chas
            } 
        }
       
        if { [ info exists user ] } {
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            $chassisChain setLoginName $user 
        }
        return 0
    }
    
    #--
    # Clear chassis chain in repository
    #--
    # Parameters: 
    #        chassisChain, chassis chain obj
    # Return:
    #        0 if got success
    #        raise error if failed 
    #--  
    proc clearChassisChain { chassisChain } {  
        set chassis [ $chassisChain getChassisNames ]
 
        foreach chas $chassis { 
            $chassisChain deleteChassisByName $chas
        }
        return 0 
    }
    
    #--
    # Get test object
    #--
    #Parameters:
    #        none
    # Return:
    #        Active Test object if got success
    #        raise error if failed 
    #--  
    proc getActiveTest {} {
        set tag "proc GetActiveTest [info script]"
        Deputs "----- TAG: $tag -----"
   
        set activeTest [ $IXIA::repository  cget -activeTest ]
        Deputs "active test name: $activeTest"
   
        return [ $IXIA::repository testList.getItem $activeTest ]
    }
    
    #--
    # Get Activity object by given name
    #--
    #Parameters:
    #       actName: activity name
    #Return:
    #       activity object if got success
    #       raise error if failed 
    #--
    proc getActivity { actName } {
        set tag "proc GetActivity [info script]-->find <$actName> "
        Deputs "----- TAG: $tag -----"
 
        set activeTest [ getActiveTest ]
    
        set clientCnt [ $activeTest clientCommunityList.indexCount ]    
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set actCnt [ $activeTest clientCommunityList($index).activityList.indexCount ]
            for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                set clientActName [ $activeTest clientCommunityList($index).activityList($actIndex).cget -name ]
                if { $clientActName == $actName } {
                    return [ $activeTest clientCommunityList($index).activityList.getItem $actIndex ]
                }
            }
        }
       
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set actCnt [ $activeTest serverCommunityList($index).activityList.indexCount ] 
            for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                set serverActName [ $activeTest serverCommunityList($index).activityList($actIndex).cget -name ]
                if { $serverActName == $actName } {
                    return [ $activeTest serverCommunityList($index).activityList.getItem $actIndex ]
                }
            }
        }   
        error "Activity not found..."
    }
         
    #--
    # Get DNSServerUrl in current rxf
    #--
    # Return:
    #        DNSServerUrl NAME if got success
    #        raise error if failed 
    #--
    proc getDNSServerUrl {} {
        set tag "proc getDNSServerUrl [info script] "
        Deputs "----- TAG: $tag -----"

        set activeTest [ getActiveTest ]
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
                set trafficName    [ $activeTest serverCommunityList($index).traffic.name ]
                set actCnt [ $activeTest serverCommunityList($index).activityList.indexCount ] 
                for { set actIndex 0 } { $actIndex < $actCnt } { incr actIndex } {
                        set serverActName \
                                [ $activeTest serverCommunityList($index).activityList($actIndex).cget -name ]
                        if { [ regexp {DNSServer} $serverActName ] } {
                                set port [ $activeTest \
                                        serverCommunityList($index).activityList($actIndex).agent.pm.advancedOptions.cget -listeningPort ]
                                return ${trafficName}_${serverActName}:$port
                        }
                }
        } 
        return None
    }
 
    #--
    # Get Network object by given name
    #--
    #Parameters:
    #      networkName: network name
    #Return:
    #        network object if got success
    #        raise error if failed
    #--
    proc getNetwork { networkName } {
        set tag "proc getNetwork [info script]"
        Deputs "----- TAG: $tag -----"
 
        set activeTest [ getActiveTest ]
        set clientCnt [ $activeTest clientCommunityList.indexCount ]    
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set clientNetName [ $activeTest clientCommunityList($index).network.name ]
            if { $networkName == $clientNetName } {
                return [ $activeTest clientCommunityList($index).network ]
            }
        }      
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set serverNetName [ $activeTest serverCommunityList($index).network.name ] 
            if { $networkName == $serverNetName } {
                return [ $activeTest serverCommunityList($index).network ]
            }
        }   
        error "Network not found..."
    }
    
    #--
    # Get Network Traffic by given name
    #--
    #Parameters:
    #      name: Network or Traffic name
    #Return:
    #        NetTraffic object if got success
    #        raise error if failed
    #--
    proc getNetTraffic { name } {
        set tag "proc getNetTraffic [info script]"
        Deputs "----- TAG: $tag -----"
 
        set activeTest [ getActiveTest ]
        set clientCnt [ $activeTest clientCommunityList.indexCount ]    
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set clientNetName [ $activeTest clientCommunityList($index).network.name ]
            if { $name == $clientNetName } {
                return [ $activeTest clientCommunityList($index) ]
            }
        }      
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set serverNetName [ $activeTest serverCommunityList($index).network.name ] 
            if { $name == $serverNetName } {
                return [ $activeTest serverCommunityList($index) ]
            }
        }
        
        for { set index 0 } { $index < $clientCnt } { incr index } {
            set clientTrafficName [ $activeTest clientCommunityList($index).traffic.name ]
            if { $name == $clientTrafficName } {
                return [ $activeTest clientCommunityList($index) ]
            }
        }      
        set serverCnt [ $activeTest serverCommunityList.indexCount ]
        for { set index 0 } { $index < $serverCnt } { incr index } {
            set serverTrafficName [ $activeTest serverCommunityList($index).traffic.name ] 
            if { $name == $serverTrafficName } {
                return [ $activeTest serverCommunityList($index) ]
            }
        } 
        error "NetTraffic not found..."
    }
    
    #--
    # Config Network param
    #--
    #Parameters:
    #      networkName: network name 
    #      args: |key, value|
    #         -auto_nego : auto negoniation ,can be true or false
    #         -speed     : when the auto_nego is false,set the speed for the port, can be "10M","100M"
    #         -port      : ports of chassis
    #         -media     :phy medium,can be "copper","fiber","auto"
    #         -gratuitous_arp: allow to receive and send arp response for free,true/false
    #         -gateway   : gateway ip
    #         -gatewayincrby: gateway increasment
    #         -netmask   : prefix
    #         -ipincrby  : ip increase step
    #         -ipcount   : ip count
    #         -ip        : ip address
    #         -vlan_id   : vlan id
    #         -vlancount :vlan count
    #         -vlanincrby: vlan increasment by
    #         -mac       : mac address
    #         -maccount  :mac count
    #         -macincrby : mac increase by
    #         -dns_domain: domain
    #         -dns_server: server ip 
    #         -ipsec_remote_gateway: ipsec remote gateway
    #         -ipsec_local_gateway : ipsec local gateway
    #         -enable    : enable network, true/false
    #
    #Return  :
    #          0 , if got success
    #          raise error if failed
    #--
    proc configNetwork { networkName args } {     
        set network [ getNetwork $networkName ]
        Deputs "network:$network"
        set tag "proc configNetwork [info script]"
        Deputs "----- TAG: $tag -----"
    
        # Param collection --
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key---$value"      
            switch -exact -- $key {
                -ipsec_local_gateway {
                    set ipsec_local_gateway $value
                }
                -ipsec_remote_gateway {
                    set ipsec_remote_gateway $value
                }
                -dns_server {
                    set dns_server $value
                }
                -dns_domain {
                    set dns_domain $value
                }
                -mac {
                    set mac $value
                }
                -maccount {
                    set maccount $value
                }
                -macincrby {
                    set macincrby $value
                }
                -vlan_id {
                    set vlan_id $value
                }
                -vlancount {
                    set vlancount $value
                }
                -vlanincrby {
                    set vlanincrby $value
                }
                -ip {
                    set ip $value
                }
                -ipcount {
                    set ipcount $value
                }
                -ipincrby {
                    set ipincrby $value
                }
                -netmask {
                    set netmask $value
                }
                -gateway {
                    set gateway $value
                }
                -gatewayincrby {
                    set gatewayincrby $value
                }
                -gratuitous_arp {
                    set gratuitous_arp $value
                }
                -media {
                    set phy $value
                    puts "celia phy = $value"
                }
                -port {
                    set portList $value
                }
                -speed {
                    set speed $value
                }
                -auto_nego {
                    set autoneg $value
                    puts "celia autoneg = $value"
                }
                -arp_response {
                    set arpresponse $value
                }
                -enable {
                    set netTraffic [ getNetTraffic $networkName ]
                    $netTraffic config -enable $value
                }
            }
        }      
          
        set ethernet_1 [ $network getL1Plugin ]
        set mac_vlan_1 [$ethernet_1 childrenList(0)]
        set ip_1 [$mac_vlan_1 childrenList(0) ]         
        set ip_r1 [$ip_1 rangeList(0)] 
              
        if {[info exists ip]} {                            
            if {[info exists ipcount]==0} {
                set ipcount 100
            }
            if {[info exists ipincrby]==0} {
                set ipincrby "0.0.0.1"
            }
            if {[info exists netmask]==0} {
                set netmask 24
            }
            if {[info exists gateway]==0} {
                set gateway "0.0.0.0"
            }
            if {[info exists gatewayincrby]==0} {
                set gatewayincrby  "0.0.0.0"
            }
            $ip_r1  config \
                -count                                   $ipcount \
                -enableGatewayArp                        false \
                -generateStatistics                      false \
                -autoCountEnabled                        false \
                -enabled                                 true \
                -autoMacGeneration                       true \
                -incrementBy                             $ipincrby \
                -prefix                                  $netmask \
                -gatewayIncrement                        $gatewayincrby \
                -gatewayIncrementMode                    "perSubnet" \
                -mss                                     1460 \
                -gatewayAddress                          $gateway \
                -ipAddress                               $ip \
                -ipType                                  "IPv4" 
        }
              
        if {[info exists mac]} {
            if {[info exists maccount]==0} {
                if {[info exists ipcount]==1} {
                    set maccount $ipcount
                } else {
                    set maccount  100
                }
            }
            if {[info exists macincrby]==0} {
                set macincrby  "00:00:00:00:00:01"
            }

            set mac_r1 [$ip_r1 getLowerRelatedRange "MacRange"]
            $ip_r1  config    -autoMacGeneration         false
            $mac_r1 config \
                -count                                   $maccount \
                -mac                                     $mac \
                -mtu                                     1500 \
                -enabled                                 true \
                -incrementBy                             $macincrby
        }
          
        if {[info exists vlan_id]} {
            if {[info exists vlanincrby]==0} {
                set vlanincrby  1
            }
            if {[info exists vlancount]==0} {
                set vlancount  4094
            }

            set vlan_r1 [$ip_r1 getLowerRelatedRange "VlanIdRange"]              
            $vlan_r1 config  \
                -incrementStep                           $vlanincrby \
                -innerIncrement                          1 \
                -firstId                                 $vlan_id \
                -uniqueCount                             $vlancount \
                -idIncrMode                              2 \
                -enabled                                 true \
                -innerFirstId                            1 \
                -innerIncrementStep                      1 \
                -priority                                1 \
                -increment                               1 \
                -innerUniqueCount                        4094 \
                -innerEnable                             false \
                -innerPriority                           1 
        } else {
            set vlan_r1 [$ip_r1 getLowerRelatedRange "VlanIdRange"]              
            $vlan_r1 config    -enabled                  false  
        }
          
        if {[info exists gratuitous_arp]} {
            Deputs "gratuitous_arp config"
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {
                set name [$network globalPlugins($i).name]
                if { [regexp {GratARP} $name total] } {
                    set gratarp [$network globalPlugins($i)]                  
                    $gratarp config -enabled $gratuitous_arp
                    break
                }
                set i [ expr $i + 1 ]
            }
            Deputs "gratuitous_arp config over"
        }
          
        if {[info exists dns_domain]} {            
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {
                set name [$network globalPlugins($i).name]
                if { [regexp {DNS} $name total] } {  
                    set dns1 [$network globalPlugins($i)]                  
                    $dns1 config -domain $dns_domain
                    $dns1 config -timeout 5 
                    break
                }
                set i [expr $i+1]
            }
        }
          
        if {[info exists dns_server]} {
            set cnt [$network globalPlugins.indexCount]
            set i 0
            while { $i <= $cnt } {               
                set name [$network globalPlugins($i).name]               
                if { [regexp {DNS} $name total] } {
                    set dns1 [$network globalPlugins($i)] 
                    $dns1 nameServerList.clear
                    set my_ixNetDnsNameServer [::IxLoad new ixNetDnsNameServer]
                    $dns1 nameServerList.appendItem -object $my_ixNetDnsNameServer
                    $my_ixNetDnsNameServer config -nameServer $dns_server
                    
                    break
                }
                set i [expr $i+1]               
            }
        }
          
        if {[info exists ipsec_local_gateway]} {
            set ipsec_1 [::IxLoad new ixNetIPSecPlugin]
            $ip_1 childrenList.clear
            $ip_1 childrenList.appendItem -object $ipsec_1
            $ipsec_1 childrenList.clear
            $ipsec_1 extensionList.clear
            $ipsec_1 rangeList.clear
    
            set ipsec_R1 [::IxLoad new ixNetIPSecRange]
            # ixNet objects needs to be added in the list before they are configured.
            $ipsec_1 rangeList.appendItem -object $ipsec_R1
            $ipsec_R1 config -enabled      true \
                            -emulatedSubnet $ipsec_local_gateway
                
            if { [info exists ipsec_remote_gateway] } {
                $ipsec_R1  config  -protectedSubnet  $ipsec_remote_gateway
            }
        }
          
        if { [ info exists phy ] } {
            puts "celia --config phy = $phy .."
            set ethernet_1 [ $network getL1Plugin ] 
            $ethernet_1 cardDualPhy.config -medium $phy
        }
        
        #delete by celia on version 1.1 start
        #if there indefend this statistic : configNetwork -media auto ; configNetwork .. (there is no -media),
        # the first configuration will be overlapped by the second configuration
        #else {
        #    puts "celia --auto config phy = copper.."
        #    set ethernet_1 [ $network getL1Plugin ] 
        #   $ethernet_1 cardDualPhy.config -medium copper
        #}
        ##delete by celia on version 1.1 end
          
        if {[info exists autoneg]} { 
            set ethernet_1 [ $network getL1Plugin ]
            if { $autoneg == "true" } {
                puts "celia --- autoneg is true! "
                $ethernet_1 config -autoNegotiate true
                $ethernet_1 config -advertise100Half true
                $ethernet_1 config -advertise100Full true
                $ethernet_1 config -advertise10Full true
                $ethernet_1 config -advertise10Half true
                $ethernet_1 config -advertise1000Full true 
            } elseif {$autoneg == "false" } {
                puts "celia --- autoneg is false! "
                $ethernet_1 config -autoNegotiate false
                if { [ info exists speed ] } {                 
                    if { [ regexp 10m $speed ] } {
                        $ethernet_1 config -advertise10Full true
                        $ethernet_1 config -advertise100Half false
                        $ethernet_1 config -advertise100Full false
                        $ethernet_1 config -advertise10Half false
                        $ethernet_1 config -advertise1000Full false
                        $ethernet_1 config -speed  "k10FD"
                    }
                    if { [ regexp 100m $speed ] } {
                        puts "celia --- speed = 100m ! "
                        $ethernet_1 config -advertise100Full true
                        $ethernet_1 config -advertise100Half false
                        $ethernet_1 config -advertise10Full false
                        $ethernet_1 config -advertise10Half false
                        $ethernet_1 config -advertise1000Full false
                        $ethernet_1 config -speed  "k100FD"
                    } 
                }
            }
        } 
        
        if { [ info exists portList ] } { 
            Deputs " info exists portList -<$portList> "
            
            set chassisChain [ $IXIA::repository cget -chassisChain ]
            set chasList [$chassisChain getChassisNames]
            
            $network portList.clear
            foreach port $portList {
                Deputs "port:$port"
                if { [ regexp {(.*)\/(\d+)\/(\d+)} $port result chassis cardId portId ] } {
                    if {[lsearch $chasList $chassis]!=-1} {
                        set chasId [expr [lsearch $chasList $chassis] + 1]
                    } else {
                        set chasId 1
                    }
                    $network portList.appendItem \
                        -chassisId $chasId \
                        -cardId $cardId \
                        -portId $portId
                } else {
                    Deputs "Wrong format of port...$port"
                }
            }
        }
        Deputs "configNetwork over"
        
        return 0
    }
    
    #get the activity rampuptime only when the timlinetype is basic mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          ramp up time , if got success
    #          raise error if failed
    #--
    proc getActivityRampupTime {actName args} {
        set tag "proc getActivityRampupTime [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set rampuptime [$timeline1 cget -rampUpTime]
        return $rampuptime
    }
    
    proc configActivitycustomPortMap {actName args} {
        set tag "proc getActivitycustomPortMap [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set desObj [$actObj cget -destinations]
        set mapObj [$desObj cget -customPortMap]
        set Ipv4mapObj [$mapObj cget -submapsIPv4]
        #set desRangList [$Ipv4mapObj cget -destinationRanges]
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -enable_id_list {
                    foreach id $value {
                        Deputs "enable destination ID $id"
                        set desportIndex [$Ipv4mapObj destinationRanges.find exact -id $id]
                        set desPortObj [$Ipv4mapObj destinationRanges.getItem $desportIndex]
                        $desPortObj config -enable 1
                    }
                        
                }
                -disable_id_list {
                    foreach id $value {
                        Deputs "disable destination ID $id"
                        set desportIndex [$Ipv4mapObj destinationRanges.find exact -id $id]
                        set desPortObj [$Ipv4mapObj destinationRanges.getItem $desportIndex]
                        $desPortObj config -enable 0
                    }
                }       
            }
        }
    }
    
    #--
    #get the activity timelineType  
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          timeline type , if got success
    #          raise error if failed
    #--
    proc getActivityTimelineType {actName args} {
        set tag "proc getActivityTimelineType [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set timelinetype [$timeline1 cget -timelineType]
        return $timelinetype
    }
    
    #--
    # getActivitySustainTime : get the activity Sustain time  only when the timlinetype is basic mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          Sustain time , if got success
    #          raise error if failed
    #--
    proc getActivitySustainTime {actName } {       
        set tag "proc getActivitySustainTime [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timeline1 [$actObj cget -timeline]
        set sustaintime [$timeline1 cget -sustainTime]
        return $sustaintime
    }
    
    #--
    # getAdvSeg0Duration : get the activity rampuptime only when the timlinetype is advance mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          ramp up time , if got success   
    #          -1, error if failed 
    #--
    proc getAdvSeg0Duration {actName} {
        set tag "proc getAdvSeg0Duration [info script]"
        Deputs "----- TAG: $tag -----"
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
        set linetype [$timelineObj cget -timelineType]
        if {$linetype == 1} {
            set advanceObj [$timelineObj cget -advancedIteration]
            set segment0Obj [$advanceObj segmentList.getItem 0]
            set duration [$segment0Obj cget -duration] 
            return $duration
       }
       Deputs " $actName linetype is 1!"
       return -1
    }
    
    #--
    # getAdvSeg1Duration : get the activity sustain time  only when the timlinetype is advance mode
    #--
    #Parameters:
    #       -- actName , activity name , such as "HTTPClient1" 
    #           
    #Return  :
    #          sustain time , if got success   
    #          -1, error if failed 
    #--
    proc getAdvSeg1Duration {actName} {
        set tag "proc getAdvSeg1Duration [info script]"
        Deputs "----- TAG: $tag -----"
       
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
        set linetype [$timelineObj cget -timelineType]
        if {$linetype == 1} {
            set advanceObj [$timelineObj cget -advancedIteration]
            set segment1Obj [$advanceObj segmentList.getItem 1]
            set duration [$segment1Obj cget -duration]
            return $duration
        }
        Deputs " $actName linetype is 1!"
        return -1
    }
   
    #--
    #config activity timeline
    #-- 
    #Parameters:
    #         -- actName , activity name , such as "HTTPClient1"
    #         -- args  |key, value|
    #           - rampupvalue   , ramp up value, only when timelinetype is 0,it will be available,
    #           - rampuptype    , value can be 0/1/2 ,meaning <users interval >,<max pending users >and <Smooth users/ interval >,only when timelinetype is 0,this will be available,
    #           - rampdowntime  , ramp down time,only when timelinetype is 0,it will be available, 
    #           - rampdownvalue , ramp down value,only when timelinetype is 0,it will be available,
    #           - iterations    , iterations ,only when timelinetype is 0,it will be available,
    #           - rampupinterval, ramp up interval ,only when timelinetype is 0,it will be available,
    #           - sustaintime   , sustaintime , only when timelinetype is 0,it will be available,
    #           - name ,timeline object name 
    #           - timelinetype  0 or 1 ,0 is basic mode,1 is advance mode
    #           - segment0duration , it is ramp up time ,only when timelinetype is 1,it will be available, 
    #           - segment1duration , it is sustain time ,only when timelinetype is 1,it will be available, 
    #           - segment2duration , it is ramp down ime ,only when timelinetype is 1,it will be available,  
    #Return  :
    #          0 , if got success   
    #          raise error if failed 
    #--
    proc configActivityTimeline { actName args } {
        set tag "proc configActivityTimeline [info script]"
        Deputs "----- TAG: $tag -----"
 
        set actObj [ getActivity $actName ]
        set timelineObj [$actObj cget -timeline]
  
        # Param collection --       
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -rampupvalue {
                    set rampUpValue $value
                    Deputs "rampUpValue is $value"
                    $timelineObj config -rampUpValue $value
                }
                -rampuptype {
                    set rampUpType $value
                    Deputs "rampUpType $value"
                    $timelineObj config -rampUpType $value
                }
                -offlinetime {
                    set offline $value
                    Deputs "offline $value"
                    $timelineObj config  -offlineTime $value
                }
                -rampdowntime {
                    set rampDownTime $value
                    Deputs "  rampDownTime $value"
                    #$timelineObj config   $value
                }
                -standbytime {
                    set standby $value
                    Deputs "standby $value"
                    $timelineObj config -standbyTime  $value
                }
                -rampdownvalue {
                    set rampDownValue $value
                    Deputs "timelineObj config  -rampDownTime $value"
                    $timelineObj config  -rampDownTime $value
                }
                -iterations {
                    set iterations $value
                    Deputs "timelineObj config -iterations  $value"
                    $timelineObj config -iterations  $value
                }
                -rampupinterval {
                    set rampUpInterval $value
                    Deputs "timelineObj config -rampUpInterval  $value"
                    $timelineObj config -rampUpInterval  $value
                }
                -sustaintime {
                    set sustain $value
                    Deputs "timelineObj config -sustainTime  $value"
                    $timelineObj config -sustainTime  $value
                }
                -name {
                    set name $value
                    Deputs "timelineObj config -name $value"
                    $timelineObj config -name $value
                }
                -timelinetype {
                    set type $value               
                    #config the timelineType ,0 is basic mode,1 is advance mode
                    Deputs "timelineObj config -timelineType $value "
                    $timelineObj config -timelineType $value
                   
                }
                -segment0duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment0Obj [$advanceObj segmentList.getItem 0]
                    #this is for advance mode, config the rampup time 
                    $segment0Obj config -duration  $value
                    Deputs "segment0Obj config -duration  $value "
                }
                -segment1duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment1Obj [$advanceObj segmentList.getItem 1]
                    #this is for advance mode ,config the duration time
                    $segment1Obj config -duration  $value               
                    Deputs "segment1Obj config -duration  $value "
                }
                -segment2duration {
                    $timelineObj config -timelineType 1
                    Deputs "timelineObj config -timelineType 1 "
                    set advanceObj [$timelineObj cget -advancedIteration]
                    set segment2Obj [$advanceObj segmentList.getItem 2]
                    #this is for advance mode ,config the duration time
                    $segment2Obj config -duration  $value               
                    Deputs "segment2Obj config -duration  $value "
                }            
            }
        }
        return 0
    }
    
   
   
    #--
    # Config Objective
    #--
    # Parameters :
    #       - actName  ,activity name , such as "HTTPClient1"
    #       - Args , |key, value|
    #         -- enableconstraint  , true or false
    #         -- constraintvalue   , constraint value,the minimum is 1
    #         -- userobjectivetype ,  objective type ,can be simulatedUsers,connectionRate,connectionAttemptRate,
    #                                 transactionRate ,concurrentSessions ,throughputKbps ,throughputMbps,
    #                                 throughputGbps
    #         -- userobjectivevalue,  objective value,
    #Return :
    #      0 if it got success
    #      raise error if it failed
    #--
    #    
    proc configObjective { actName args } {
        set tag "proc configObjective [info script]"
        Deputs "----- TAG: $tag -----"
 
        set actObj [ getActivity $actName ]
       
        # Param collection --         
        foreach { key value } $args {
            set key [string tolower $key]
            Deputs "config $key --$value"
            switch -exact -- $key {
                -enableconstraint {
                    set enable_constraint $value
                    $actObj config -enableConstraint $value
                       Deputs "$actObj config -enableConstraint $value"
                }
                -constraintvalue {
                    $actObj config -constraintValue $value
                    Deputs "$actObj config -constraintValue $value"
                }
                -userobjectivetype {
                    $actObj config -userObjectiveType $value
                    Deputs "$actObj config -userObjectiveType $value"
                }
                -userobjectivevalue {
                    $actObj config -userObjectiveValue $value
                    Deputs "$actObj config -userObjectiveValue $value"
                }
            }
        }
       
        if {[info exists enable_constraint] == 0} {
            $actObj config -enableConstraint false
        }
        return 0
    }
    
    #--
    # Save the repository
    #--
    # Args:
    #       -repPath: the repository file absolute path
    #       -overwrite: whether override the existing file, default is '1'
    proc save { repPath {overwrite 1}} {
        set tag "proc save [info script]"
        Deputs "----- TAG: $tag -----"
        return [ $IXIA::repository write -destination $repPath -overwrite $overwrite]
    }
    
    #--
    # apply the configuration in repository
    #--
    proc apply {} {
        set tag "proc apply [info script]"
        Deputs "----- TAG: $tag -----"
    
        set activeTest [ getActiveTest ]    
        $IXIA::testController applyConfig $activeTest
    }
    
    #--
    # run test
    #--
    proc run {} {
        set tag "proc run [info script]"
        Deputs "----- TAG: $tag -----"
        set IXIA::stats_info_list {}
        
        set chassisChain [ $IXIA::repository cget -chassisChain ]
        $chassisChain refresh
        set repName    [ $IXIA::repository cget -name ]
        set activeTest    [ getActiveTest ]
        set testName    [ $activeTest cget -name ]
        
        $IXIA::testController setResultDir "Result/${repName}/${testName}"
        $activeTest config \
            -enableNetworkDiagnostics                    false \
            -statsRequired                               true \
            -showNetworkDiagnosticsAfterRunStops         false \
            -showNetworkDiagnosticsFromApplyConfig       false \
            -enableForceOwnership                        true \
            -enableResetPorts                            true \
            -enableReleaseConfigAfterRun                 true
        
        set activeTest [ getActiveTest ]
        $activeTest clearGridStats
        
        $IXIA::testController run $activeTest -repository $IXIA::repository
    }
    
    #--
    # stop test
    # Parameters :
    #    none
    #--
    proc stop {} {
        set tag "proc stop [info script]"
        Deputs "----- TAG: $tag -----"
        $IXIA::testController stopRun
        
        # Wait for test really stopped
        waitForTestStop
        Deputs " proc  stop over "
    }
        
    #--
    # Wait for the test stopped
    # RETURN: if run successfully 1
    #           etherwise 0
    #--
    proc waitForTestStop {} {
        set tag "proc waitForTestStop [info script]"
        Deputs "----- TAG: $tag -----"
        vwait ::ixTestControllerMonitor
        Deputs "ixTestControllerMonitor = $::ixTestControllerMonitor"
        ${IXIA::NS}::StopCollector
        
        Deputs "  proc  waitForTestStop over  "
        return 1   
    }

    #--
    # Generate test report
    #--
    # Args:
    #       -deltailedReport: Whether to generate detailed report, default value is '1'
    #       -format: Which type of the report you want to generate, default is 'PDF;HTML'
    proc generateReport { {deltailedReport 1} {format "PDF;HTML"} } {
        set tag "proc generateReport [info script]"
        Deputs "----- TAG: $tag -----"
        $IXIA::testController generateReport -detailedReport $deltailedReport -format $format
    }
    
    #--
    # Select the stats for testing
    #--
    # Parameters: 
    #        statList: Protocol stats List
    #        interval: Stats subscribe interval 
    # Return:
    #        0 if got success
    #        raise error if failed
    #--
    proc selectStats { statList { interval 1 } } {
        IXIA::statsInit
        set IXIA::SelectedStats $statList
        set activeTest [ getActiveTest ]
        set test_server_handle [$IXIA::testController getTestServerHandle]
        ${IXIA::NS}::Initialize -testServerHandle $test_server_handle
        ${IXIA::NS}::ClearStats
        $activeTest clearGridStats
        
        set proIndexList [ list ]
        foreach stats $statList {
            Deputs "stats:$stats"

            if { [ info exists IXIA::StatsList($stats) ] } {
                lappend proIndexList $IXIA::StatsList($stats)
            } else {
                lappend proIndexList $stats
            }
        }
        Deputs "pro index list:$proIndexList"        
        set count 0
        foreach statItem $proIndexList {
            set caption         [format "Watch_Stat_%s" $count]
            set statSourceType  [lindex $statItem 0]
            set statName        [lindex $statItem 1]
            set aggregationType [lindex $statItem 2]
            Deputs "caption:$caption"
            Deputs "statSourceType:$statSourceType"
            Deputs "statName:$statName"
            Deputs "aggregationType:$aggregationType"

            if { [ catch {
                ${IXIA::NS}::AddStat \
                -caption            $caption \
                -statSourceType     $statSourceType \
                -statName           $statName \
                -aggregationType    $aggregationType \
                -filterList         {}
            } err ] } {
                Deputs "Add stats $statSourceType $statName error:$err"
            }
        }
 
        ${IXIA::NS}::StartCollector -command IXIA::collectStats -interval $interval
        incr count
    }
    
    ####################################################################################
    # Proc Name        : calculate the average of state                    
    # Parameters       :
    #                   - proIndexList :  the Protocol StatLists' start index and length  found in the global varibale protclListNg in stats.tcl
    # Parameter Example: { { {"http_client_throughput" 0 4} {"http_client_transactions"  4 1 } ...} }
    # Return Value     : average of the stats
    # Related Script   : Needed in IxRepository.tcl 
    # Edit Date        : 2011.02
    # Last Mod         :     
    # Scriptor         : celia chen
    #####################################################################################    
    proc statsCal { proIndexList  } {
        set tag "proc statsCal [info script]"
        Deputs "----- TAG: $tag -----"  
       
        set statslist $IXIA::stats_info_list
        Deputs "statslist:$statslist"
        set statslen [llength $statslist]
        set statscnt [llength [lindex $statslist 0 ]]                               
        Deputs "statslen = <$statslen> ,statscnt = <$statscnt>"
        
        set lastIndexofIndexList [ lindex [ lindex $proIndexList [expr [llength $proIndexList] - 1 ] ] 1]
        set lenxofIndexList      [ lindex [ lindex $proIndexList [expr [llength $proIndexList] - 1 ] ] 2]
        Deputs "lastIndexofIndexList:$lastIndexofIndexList"
        Deputs "lenxofIndexList:$lenxofIndexList"
        
        set lengthindex [expr $lastIndexofIndexList + $lenxofIndexList ]
        Deputs "lengthindex:$lengthindex"
        
        Deputs "statscnt is <$statscnt>, lengthindex of proIndexList is <$lengthindex>!"
     
          if {$lengthindex != $statscnt } { 
              Deputs " lengthindex != statscnt : $lengthindex != $statscnt "  
              Deputs "the protocol stats input to test does not match with the protocol in the the rxf file! "
              return 1     
          }

        set i 0
        set startIndex 0
        set startflag 0
        set endIndex 0
        set lastItem 0
        
        # begin modify 2011-08-03 xiesongyan
        #set nowItem 0
        foreach item $IXIA::stats_info_list {
        Deputs "item:$item"
            #set nowItem $item
            if {$startflag == 0} {
                  foreach element $item { 
                  Deputs "element:$element"
                     if { [lindex $element 1] != 0 && [lindex $element 1] != {} } {
                           set startIndex $i
                           set startflag 1
                        break
                     }               
                  }
            }
            #else {
            #   if { $lastItem == $nowItem } {               
            #      set endIndex [expr $i-1]
            #      break
            #   }
            #}
            #set lastItem $item
            incr i
        }
        
        Deputs "startIndex:$startIndex startflag:$startflag endIndex:$endIndex lastItem:$lastItem"
        
        set lastindex [expr $statslen - 1]
        while {1} {
            set lastItem  [lindex $statslist $lastindex]
            set nowindex [expr $lastindex - 1]
            set nowItem [lindex $statslist $nowindex]
            if {$nowItem != $lastItem} {
                break;
            }
            incr lastindex -1
        }
        set endIndex [expr $lastindex + 1]
        #set indexi [expr $i-1]        
        Deputs "startIndex:$startIndex endIndex:$endIndex"
        if { $startIndex == 0 && $endIndex == 1 } {
            set start [lindex $IXIA::stats_info_list $startIndex]
            set  resultValueList {}          
            foreach proIndexListi $proIndexList {
                set protcl     [lindex $proIndexListi 0]
                set resultValueList [linsert $resultValueList [llength $resultValueList] [list $protcl 0]]         
            }
              
            return $resultValueList
        }
        
        #if {$startIndex < $indexi } {
        #    set endIndex $indexi
        #}
        # begin modify 2011-08-03 xiesongyan
        
        set statsavglist {}
        set statsavg 0
        set sum 0
        set i 0
        set j [ expr $startIndex + 1 ]
        set this 0
        set indexCnt 0 
         
        # $statscnt
        while { $i < $statscnt } {
    
            if { $indexCnt < [llength $proIndexList] } {
                set protcl_stat [ lindex [lindex $proIndexList $indexCnt] 0 ]
            }
            # if latency,will not calculate the rate
            set cnt [expr $endIndex-$startIndex-1]
            
            if { [regexp {latency} $protcl_stat ] } {
                  
                set cnt [mpexpr $cnt+1]
                set j [expr $j-1]
                while { $j < $endIndex } {
                    set st_item [ lindex [ lindex [lindex $statslist $j] $i ] 1]
                    set sum  [mpexpr $st_item + $sum]
                    set j    [mpexpr $j+1]
                }
            
            } else {
                Deputs "there is normal stats in $protcl_stat"
                # calculate the rate of the stats,according to the interval value to collect stats
                while { $j < $endIndex } {
               
                    set lj [ mpexpr $j - 1]
                    set last [ lindex [ lindex $statslist $lj ] $i ]
                    set this [ lindex [ lindex $statslist $j ] 0 ]
                    set last [ lindex [ lindex [ lindex $statslist $lj ] $i ] 1 ]
                    set this [ lindex [ lindex [ lindex $statslist $j ] $i ] 1 ]
                    set rate [mpexpr $this - $last]
                    set sum  [mpexpr $rate + $sum]
                    set j    [mpexpr $j + 1 ]
                }
            }
            set sum [mpexpr $sum*1.0]
            set avg [mpexpr $sum/$cnt]
            set statsavg $avg
            #puts the result in the statavglist
            set statsavglist [linsert $statsavglist [llength $statsavglist] $statsavg]
            if { [expr $i+1] == [ lindex [lindex $proIndexList [expr $indexCnt + 1]] 1 ] } {
                
                set indexCnt [mpexpr $indexCnt + 1]
               }
            set i [expr $i+1]
            set j [ expr $startIndex + 1 ]
            set sum 0            
        }
        
        set resultValueList {}
        #calculate the total value for the state according to index in the proIndexList in stats.tcl
        foreach proIndexListi $proIndexList {
            set protcl     [lindex $proIndexListi 0]
            set startIndex [lindex $proIndexListi 1]
            set lenx       [lindex $proIndexListi 2]
            set i 0
            set sum 0
            while { $i < $lenx } {
                set statsavglisti [ lindex $statsavglist [expr $i + $startIndex] ]
                set sum [expr $sum + $statsavglisti]
                set i [expr $i + 1 ]
            }
            Deputs "append value is list $protcl $sum "
            set resultValueList [linsert $resultValueList [llength $resultValueList] [list $protcl $sum]]         
        }
        
        return $resultValueList  
        
    }
     
    ####################################################################################
    # Proc Name        : collect the protocol stats when running and put the data in global varibale stats_info_list and  call
    #                    function statsCal to calculate the average value
    #                    
    # Parameters       : args , is the value of Stats when running 
    # Parameter Example: statcollectorutils {timestamp 110000 stats {{kInt 166966415} {{kInt 166966415}}} {{{kInt 166966415}} {{kInt 1669664}}} ... ... }
    # Return Value     : none
    # Related Script   : Needed in IxRepository.tcl 
    # Edit Date        : 2011.02
    # Last Mod         :     
    # Scriptor         : celia chen
    #
    #####################################################################################    
    proc collectStats { args } {      
        set tag "proc collectStats [info script]"
        Deputs "----- TAG: $tag -----"
        Deputs "full stats info:$args"    
        set IXIA::stats_info_list [lindex [lindex $args 1] 3]
        Deputs "stats_info: $IXIA::stats_info_list"             
    }   
    
    ####################################################################################
    # Proc Name        : get the protocol instatntStats stats collected after running  
    #
    # Parameters       : none
    # Return Value     :   all original State value and average value 
    #
    # Related Script   :   Needed in IxRepository.tcl 
    # Edit Date        :   2011.02
    # Last Mod         :   2012.05 by Eric Yu
    # Scriptor         :   celia chen
    #
    #####################################################################################
    proc getInstantStats { proItem } {
        Deputs "in --------proc----getInstantStats-----------------"
        set statslist $IXIA::stats_info_list
        set statslen [llength $statslist]
        if { $statslen == 0 } {
            return ""
        }
        
        if { [ string is integer $proItem ] == 0 } {
            set proItem [ lsearch $IXIA::SelectedStats $proItem ]
            if { $proItem == "-1" } {
                return ""
            }
        } else {
            if { $proItem >= $staslen } {
                return ""
            }
        }
        
        set statsIndex [ lindex $statslist $proItem ]
        set statsVal [ lindex $statsIndex 1 ]
        
        return $statsVal
    }
      

    ####################################################################################
    # Proc Name        : get the protocol raw stats collected after running  
    #
    # Parameters       : none
    # Return Value     :   all original State value and average value 
    #
    # Related Script   :   Needed in IxRepository.tcl 
    # Edit Date        :   2012.May.2
    # Last Mod         :     
    # Scriptor         :   Eric Yu
    #
    #####################################################################################
    proc getStats {} {
        return $IXIA::stats_info_list
    }

    #-- connect to lib
    proc connect {} { 
        set IXIA::testController [::IxLoad new ixTestController -outputDir 1]
        ::IxLoad connect localhost
    }
    
    #-- disconnect to lib
    proc disconnect {} {
        $IXIA::testController releaseConfigWaitFinish
        ::IxLoad disconnect
    }
    
    #--
    # Debug puts
    #--
    proc Deputs { value } {
        if { $IXIA::Debug } {
            set timeVal  [ clock format [ clock seconds ] -format %D-%T ]
            set clickVal [ clock clicks ]
            puts "\[TIME:$timeVal\]$value"
        }
    }
    
    #--
    # Enable debug puts
    #--
    proc IxDebugOn { { log 0 } } {
        set IXIA::Debug 1
    } 
      
    #--
    # Disable debug puts
    #--
    proc IxDebugOff {} {
        set IXIA::Debug 0
    }
}

# -- Changes made on v1.2.a
set currDir [file dirname [info script]]

if { [ catch {
    source [file join $currDir "utils.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "stats.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "HTTP.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "RTSP.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "SIP.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "DNS.tcl"]
} err ] } {
    puts "load package fail...$err"
}
if { [ catch {
    source [file join $currDir "AppReplay.tcl"]
} err ] } {
    puts "load package fail...$err"
}
# -- Changes end
