package provide IxSIP  1.0

# RTSP.tcl--
#   This file implements the Tcl encapsulation of RTSP emulation
#
# Copyright (c) Ixia technologies, Inc.

#       package version 1.0
#       release version 1.0
#============
# Change made
#============
# Version 1.0.1.0
# a. Eric-- Create
#       Procedure


namespace eval IXIA {
    
    #--
    # SIP sip column configuration
    #--
    proc SIP_Config { actName args } {
        
        set tag "proc SIP_ConfigExecution [info script]"
Deputs "----- TAG: $tag -----"
    
        set actObj [ getActivity $actName ]
        
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -port {
                    set port $value
                }
           }
        }
        
        if { [ info exists port ] } {
            $actObj agent.pm.signalingSettings.config -port $port
        }
        
    }
    
    #--
    # SIP sip column [ use external server ] configuration
    #--
    proc SIP_ConfigExtServer { actName args } {
        
        set tag "proc SIP_ConfigExtServer [info script]"
Deputs "----- TAG: $tag -----"
        
        set actObj [ getActivity $actName ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
                -address {
                    set address $value
                }
                -port {
                    set port $value
                }
                -domain {
                    set domain $value
                }
                -regaddr {
                    set regaddr $value
                }
                -autoreg {
                    set autoreg $value
                }
                -enable {
                    set enable $value
                }
            }
        }
        
        if { [ info exists enable ] } {
            $actObj agent.pm.signalingSettings.config -useServer $enable
        }
        
        if { [ info exists autoreg ] } {
            $actObj agent.pm.signalingSettings.config -autoRegister $autoreg
        }
        
        if { [ info exists address ] } {
            $actObj agent.pm.signalingSettings.config -srvAddr $address
        }
        
        if { [ info exists port ] } {
            $actObj agent.pm.signalingSettings.config -port $port
        }
        
        if { [ info exists domain ] } {
            $actObj agent.pm.signalingSettings.config -srvDomain $domain
        }
        
        if { [ info exists regaddr ] } {
            $actObj agent.pm.signalingSettings.config -registrarSrv true
            $actObj agent.pm.signalingSettings.config -overrideRegistrarAddress $regaddr
        }
    }
    

    #--
    # SIP Execution column configuration
    #--
    proc SIP_ConfigExecution { actName args } {
        
        set tag "proc SIP_ConfigExecution [info script]"
Deputs "----- TAG: $tag -----"
        
        set actObj [ getActivity $actName ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
               -loopcount {
                  set loopCnt $value
               }
           }
        }
        
        if { [ info exists loopCnt ] } {
            $actObj agent.pm.executionSettings.config -loopCount $loopCnt
        }
    }
    

    #--
    # SIP Dial Plan column configuration
    #--
    proc SIP_ConfigDialPlan { actName args } {
        
        set tag "proc SIP_ConfigDialPlan [info script]"
Deputs "----- TAG: $tag -----"
        
        set actObj [ getActivity $actName ]

        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
               -destip {
                  set destip $value
               }
           }
        }
        
        if { [ info exists destip ] } {
            $actObj agent.pm.dialPlan.config -symDestStr $destip
        }
    }
    #--
    # SIP commands configuration
    #--
    #parameters:
    #        - actName, activity name 
    #        - args
    #            -- cmdtype ,command type
    #            -- cmdname ,command name
    #            -- thinkinterval  ,think interval
    #            -- symdestination , symdestination
    #
    #Return :
    #       0 , if save successfully
    #       raise  error  if  failed
    #--
    proc SIP_AppendCommand { actName args } {
      set tag "proc SIP_AppendCommand [info script]"
     Deputs "----- TAG: $tag --actName = $actName ---"
        
        set actObj [ getActivity $actName ]
        foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
               -cmdtype {
                  set cmdtype $value
               }
               -cmdname {
                  set cmdname $value
                }
               -thinkinterval {
                  set thinkinterval $value
               }
               -symdestination {
                  set symdestination $value
               }
           }
        }
        
        
        Deputs "cmdtype = $cmdtype, cmdname = $cmdname "
        if { [ info exists symdestination ] } {
            
              $actObj agent.pm.scenarios.appendItem  \
                -commandType                $cmdtype \
                -cmdName                     $cmdname \
                -symDestination                     $symdestination
                 
        } elseif { [ info exists thinkinterval ] } {
            
              $actObj agent.pm.scenarios.appendItem  \
                -commandType                $cmdtype \
                -cmdName                     $cmdname  \
                -minimumInterval               $thinkinterval \
                -maximumInterval               $thinkinterval \
             
        } else { 
             $actObj agent.pm.scenarios.appendItem  \
                -commandType                $cmdtype \
                -cmdName                     $cmdname \
        } 
        
    }
    #--
    # Clear SIP commands configuration
    #--
    #parameters:
    #        - actName, activity name   
    #Return :
    #       0 , if save successfully
    #       raise  error  if  failed
    #--
    proc SIP_ClearCommand {actName } {
    
      set tag "proc SIP_ClearCommand [info script]"
     Deputs "----- TAG: $tag --actName = $actName ---"
      
      set actObj [ getActivity $actName ] 
      $actObj agent.pm.scenarios.clear
      return 0
    }
    
    #--
    # Config SIP Sever Agent configuration
    #--
    #parameters:
    #        - actName, activity name 
    #        - args
    #            -- tcpport ,tcp port,default 5060
    #            -- udpport ,udp port,default 5060 
    #
    #Return :
    #       0 , if save successfully
    #       raise  error  if  failed
    #--
    proc SIP_ConfigServerAgent { actName args } {
    
      set tag "proc SIP_ConfigServerAgent [info script]"
      Deputs "----- TAG: $tag -----"
        
         set actObj [ getActivity $actName ]  
         foreach { key value } $args {
            set key [string tolower $key]
            switch -exact -- $key {
               -tcpport {
                  set tcpport $value
               }
               -udpport {
                  set udpport $value
                }
           }
        }
        #config the udp_port
        if { [ info exists tcpport ] } {
           $actObj agent.pm.generalSettings.config    -nUdpPort      $tcpport        
        }
        #config the tcpport
        if { [ info exists udpport ] } {
             $actObj agent.pm.generalSettings.config     -nTcpPort       $udpport
        }
        return 0
    }

}