package provide IxDNS  1.3
# DNS.tcl--
#   This file implements the Tcl encapsulation of HTTP emulation
#
# Copyright (c) Ixia technologies, Inc.
#       package version 1.0 
#============
# Change made
#============
# Version 1.0.1.0
# a. Eric-- Create
#       Procedure
#   #1.DNSClient_Config
# Version 1.1.1.4
#	#2. Add procedure DNSClient_ConfigAction
#	#3. Add procedure DNSServer_Config
#   #4. Add procedure DNSServer_ConfigRecord
# Version 1.2.1.5
#	#5. Add Zone list in DNSServer_ConfigRecord
#	#6. Add default Zone IXIA/Localhost
# Version 1.3.1.6
#	#7. Add THINK action in DNS Client

namespace eval IXIA {
	#--
	# Config DNS Activity
	#--
	#Parameters:
	#         -- actName , activity name , such as "DNSClient1"
	#         -- args ,  |key, value| , parameters of ixHttpCommand object  
	#            - loopcount  ,loop count
	#		  -- url, URL value, such as www.huawei.com
	#		  -- hostname, HOST NAME value, such as localhost
	#		  -- commandtype, DNS command value, 
	#			the available enumeration are a|ns|cname|soa|ptr|mx|aaaa|enum
	#		  -- cmdname, the name of command if you need one
	#Return:
	#         0 , if got success   
	#          raise error or turn 1 if failed
	#--
	#	
	proc DNSClient_ConfigAction { actName {clrflag 1} args } {
	
		set tag "proc DNSClient_ConfigAction [info script]"
		Deputs "----- TAG: $tag -----"
		
		Deputs " clrflag = $clrflag"
		set actObj [ getActivity $actName ]
		set host "localhost"
		set commandList1 [list  "A" "AAAA" "NS" "CNAME" "SOA" "PTR" "MX" "ENUM" ]
		set commandList2 [list "LOOPBEGINCOMMAND" "LOOPENDCOMMAND" "THINK"]
		if { $clrflag } {
			$actObj agent.pm.dnsConfig.dnsQueries.clear
		}

		foreach { key value } $args {
			Deputs "config -$key--$value"
			set key [string tolower $key]
			switch -exact -- $key {
				-commandtype -
				-type { 
				  set commandtype [ string toupper $value ]
				  #set commandtype $value
Deputs "command type:$commandtype"
				}
				-cmdname {
				   set cmdname  $value
				}
				-url { 
				   set url $value 
				}
				-loopcount {
					 set loopcount $value
				}
				-hostname -
				-host {
					set host $value
				}
				-duration {
					set duration $value
				}
			}
		}
		
		if { [ info exists commandtype ] == 0 } {
			return 0
		}
		
		if { [lsearch $commandList1 $commandtype ] >=0 } { 
			Deputs "config $commandtype start "
			
			if { [ info exists url ] == 0 } {
Deputs "get DNS Server URL..."
				set url [ getDNSServerUrl ] 
			}
Deputs "DNS server url: $url"
			set cmdObj [
			$actObj agent.pm.dnsConfig.dnsQueries.appendItem \
				-dnsServer $url \
				-commandType DnsQuery \
				-queryType $commandtype \
				-cmdName $cmdname \
				-hostName $host ]
Deputs "cmd obj:$cmdObj"

			Deputs "config $commandtype end "
		}

		if { [lsearch $commandList2 $commandtype ] >=0 } { 
			Deputs "config $commandtype start " 
			if { $commandtype == "LOOPBEGINCOMMAND" } {
				if { [info exists loopcount] == 0 } {
					set loopcount 5
				}
				$actObj agent.pm.dnsConfig.dnsQueries.appendItem \
					-commandType                             "LoopBeginCommand" \
					-LoopCount                               $loopcount \
					-cmdName                                 $cmdname
			} elseif { $commandtype == "THINK" } {
				if { [ info exists duration ] == 0 } {
					set duration 1000
				}
				$actObj agent.pm.dnsConfig.dnsQueries.appendItem \
					-commandType                             "THINK" \
					-minimumInterval                         $duration \
					-maximumInterval                         $duration \
					-cmdName                                 $cmdname					
			} else {
				$actObj agent.pm.dnsConfig.dnsQueries.appendItem \
					-commandType                             "LoopEndCommand" \
					-cmdName                                 $cmdname
			}
			Deputs "config $commandtype end "
			Deputs "loop end "
		}
		return 0
	}
	
	proc DNSServer_Config { actName args } {

		set tag "proc DNSServer_Config [info script]"
		Deputs "----- TAG: $tag -----"
		
		foreach { key value } $args {
			Deputs "config -$key--$value"
			set key [string tolower $key]
			switch -exact -- $key {
				-port {
					set port $value
				}
			}
		}
		
		set actObj [ getActivity $actName ]

		if { [ info exists port ] } {
		
			$actObj agent.pm.advancedOptions.config \
				-listeningPort  $port 
		}

		return 0
	}
	
	proc DNSServer_ConfigRecord { actName {clrflag 1} args } {
		set tag "proc DNSServer_ConfigRecord [info script]"
Deputs "----- TAG: $tag -----"
		
		foreach { key value } $args {
Deputs "config -$key--$value"
			set key [string tolower $key]
			switch -exact -- $key {
				-record -
				-type {
					set record [ string toupper $value ]
				}
				-host {
					set host $value
				}
				-address {
					set address $value
				}
				-zonename {
					set zonename $value
				}
			}
		}
		
		set actObj [ getActivity $actName ]
		
		if { $clrflag } {
Deputs "clear records..."
			$actObj agent.pm.zoneMgr.zoneChoices.clear
			$actObj	agent.pm.zoneConfig.zoneList.clear
			# =======================================================================
			# Pre-defined zone choices
			$actObj agent.pm.zoneMgr.zoneChoices.appendItem \
				-id                                      "Zone" \
				-predefine                               true \
				-serial                                  1234 \
				-expire                                  8888 \
				-name                                    "localhost" \
				-masterServer                            "ixia-dns-tester" 

			$actObj agent.pm.zoneMgr.zoneChoices(0).resourceRecordList.clear

			$actObj agent.pm.zoneMgr.zoneChoices(0).resourceRecordList.appendItem \
				-id                                      "A" \
				-hostName                                "localhost" \
				-address                                 "127.0.0.1" 

			$actObj agent.pm.zoneMgr.zoneChoices(0).resourceRecordList.appendItem \
				-id                                      "A" \
				-hostName                                "host1" \
				-address                                 "198.18.0.1" 

			$actObj agent.pm.zoneMgr.zoneChoices(0).resourceRecordList.appendItem \
				-id                                      "NS" \
				-nameServer                              "198.18.0.2" \
				-zoneName                                "localhost" 

			$actObj agent.pm.zoneMgr.zoneChoices.appendItem \
				-id                                      "Zone" \
				-predefine                               true \
				-serial                                  1234 \
				-expire                                  8888 \
				-name                                    "ixiacom.com" \
				-masterServer                            "ixia-dns-tester" 

			$actObj agent.pm.zoneMgr.zoneChoices(1).resourceRecordList.clear

			$actObj agent.pm.zoneMgr.zoneChoices(1).resourceRecordList.appendItem \
				-id                                      "A" \
				-hostName                                "puppy1" \
				-address                                 "198.18.1.100" 

			$actObj agent.pm.zoneMgr.zoneChoices(1).resourceRecordList.appendItem \
				-id                                      "A" \
				-hostName                                "drowzee" \
				-address                                 "198.18.1.200" 

			$actObj agent.pm.zoneMgr.zoneChoices(1).resourceRecordList.appendItem \
				-id                                      "CNAME" \
				-name                                    "testName" \
				-realName                                "realName" 

			$actObj agent.pm.zoneMgr.zoneChoices(1).resourceRecordList.appendItem \
				-id                                      "NS" \
				-nameServer                              "198.18.0.2" \
				-zoneName                                "ixiacom.com" 
			# =======================================================================
			
		}
		
		if { [ info exists zonename ] } {
			set zoneObj [ $actObj agent.pm.zoneMgr.zoneChoices.appendItem \
				-id                                      "Zone" \
				-predefine                               false \
				-serial                                  1234 \
				-expire                                  8888 \
				-name                                    $zonename \
				-masterServer                            "ixia-dns-tester" ]
			$zoneObj resourceRecordList.clear
			$actObj agent.pm.zoneConfig.zoneList.appendItem -name $zonename
		} else {
			set zoneIndex [ expr [ $actObj agent.pm.zoneMgr.zoneChoices.indexCount ] - 1 ]
			set zoneObj [ $actObj agent.pm.zoneMgr.zoneChoices($zoneIndex) ]
		}
Deputs "add customized records..."
		if { [ info exists record ] } {
Deputs "record:$record"
			set recordObj [ \
			$zoneObj resourceRecordList.appendItem \
				-id $record ]
		}
		
		if { [ info exists host ] } {
			if { [ info exists recordObj ] } {
				switch $record {
					A -
					PTR {
						$recordObj config -hostName $host
					}
					NS {
Deputs "NS Record...zoneName: $host"
						$recordObj config -zoneName $host						
					}
				}
			}
		}
		
		if { [ info exists address ] } {
			if { [ info exists recordObj ] } {
				switch $record {
					A {
						$recordObj config -address $address
					}
					PTR {
						$recordObj config -ipAddress $address
					}					
					NS {
Deputs "NS Record...nameServer: $address"
						$recordObj config -nameServer $address						
					}
				}
			}
		}
		
		return 0
	}
	

}
