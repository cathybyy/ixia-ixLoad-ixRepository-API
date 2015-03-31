package provide IxAppReplay  1.0

# AppReplay.tcl--
#   This file implements the Tcl encapsulation of AppReplay emulation
#
# Copyright (c) Ixia technologies, Inc.


#       release version 1.0
#============
# Change made
#============
# Version 1.0.1.0
# a. Cathy-- Create
#       Procedure
#   #1.AppReplay_AppendCommand
#      actName    : e.g. AppReplayPeer1/AppReplayPeer2
#      commandname: e.g. "Custom Flow - TCP 1"/ "Custom Flow - UDP 2"
#      commandtype: e.g. "CustomFlowTCP" "CustomFlowUDP" "CustomFlowIP" "CustomFlowETH"
#      destination: e.g. "Traffic1_AppReplayPeer1"/"Traffic2_AppReplayPeer2"
#      capturefile: "C:\\Users\\vip\\Desktop\\tcptraffic.cap"
#   #2.AppReplay_ConfigCommand
#   #3.AppReplay_DeleteCommand
#   #4.AppReplay_ClearCommand



namespace eval IXIA {
   
   #--
   # AppReplay action - append command to command list
   #--
    proc AppReplay_AppendCommand { actName args } {
  
        set tag "proc AppReplay_AppendCommand [info script]"
        Deputs "----- TAG: $tag -----"
      
        set actObj [ getActivity $actName ]
        set commandList [list  "CustomFlowTCP" "CustomFlowUDP" "CustomFlowIP" "CustomFlowETH" ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -commandtype {                
                   set commandtype $value                      
                }          
                -destination {
                   set dest $value
                }
                -commandname {
                   set name $value
                }
                -capturefile {
                   set capturefile $value
                } 
                -loopcount {
                   set loopCnt $value
                }
            }
        }
      
        if { [info exists loopCnt] } {
		    $actObj agent.config \
	            -cmdListLoops             $loopCnt 
	    }
                
      
        if { [lsearch $commandList $commandtype ] >=0 } {
            if { [info exist dest]==0 } {
                error "no destination configured"
            }
            
            if { [info exist capturefile]==0 } {
                error "no capturefile configured"
            }
            
            if { [info exist name]==0 } {
                error "no commandname configured"
            }
      
            set appObj [ $actObj agent.pm.protocolFlows.appendItem \
               -filt_ResponderPort                      "" \
               -sessionSelectionLogic                   0 \
               -filt_InitiatorIP                        "" \
               -remotePeer                              $dest \
               -destination                             $dest \
               -cmdName                                 $name \
               -persistent_requests_count               1 \
               -commandType                             $commandtype \
               -overrideResponderPort                   false \
               -captureFile                             $capturefile \
               -max_persistent_requests                 1 \
               -filt_ResponderIP                        "" \
               -responderPort                           10000 \
               -filt_InitiatorPort                      ""  ]
          
        }      
		
    }
   
    proc AppReplay_ConfigCommand { actName args } {
 
        set tag "proc AppReplay_ConfigCommand [info script]"
        Deputs "----- TAG: $tag -----"
      
        set actObj [ getActivity $actName ]
        set commandList1 [list  "CustomFlowTCP" "CustomFlowUDP" "CustomFlowIP" "CustomFlowETH" ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -commandname {
                   set name $value
                }         
                -destination {
                   set dest $value
                }
                -capturefile {
                   set capturefile $value
                } 
                -loopcount {
                   set loopCnt $value
                }
            }
        }
      
        if { [info exists loopCnt] } {
		    $actObj agent.config \
	            -cmdListLoops             $loopCnt 
	    }
                          
        if {[info exists name]} {
            set appIndex [ $actObj agent.pm.protocolFlows.find exact -cmdName $name]
            set appObj [ $actObj agent.pm.protocolFlows($appIndex) ]
        } else {
            set appIndex [ expr [ $actObj agent.pm.protocolFlows.indexCount ] - 1 ]
            set appObj [ $actObj agent.pm.protocolFlows($appIndex) ]
        }
        if {[info exists dest ]} {
            $appObj config \
                -remotePeer                 $dest \
	            -destination                $dest 
	      
        }
        
        if {[info exists capturefile ]} {
            $appObj config \
	            -captureFile                $capturefile
	      
        }
        
		
    }
   
    proc AppReplay_DeleteCommand { actName args } {
      
        global cmdIndex
       
        set tag "proc AppReplay_DeleteCommand [info script]"
        Deputs "----- TAG: $tag -----"
      
        set actObj [ getActivity $actName ]
        set commandList1 [list  "CustomFlowTCP" "CustomFlowUDP" "CustomFlowIP" "CustomFlowETH" ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -commandname {
                   set name $value
                }          
            }
        }
      
                          
        if {[info exists name]} {
            set appIndex [ $actObj agent.pm.protocolFlows.find exact -cmdName $name]
            set appObj [ $actObj agent.pm.protocolFlows($appIndex) ]
        } else {
            error "No commandname is offered"
            
        }

        $actObj agent.pm.protocolFlows.deleteItem  $appIndex 
	
    }
   
    proc AppReplay_ClearCommand { actName  } {
      
        global cmdIndex
       
        set tag "proc AppReplay_ClearCommand [info script]"
        Deputs "----- TAG: $tag -----"
      
        set actObj [ getActivity $actName ]
       
        $actObj agent.pm.protocolFlows.clear
	
    }
}