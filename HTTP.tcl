package provide IxHTTP  1.0
# HTTP.tcl--
#   This file implements the Tcl encapsulation of HTTP emulation
#
# Copyright (c) Ixia technologies, Inc.
#       package version 1.0 
#============
# Change made
#============
# Version 1.0.1.0
# a. Celia-- Create
#       Procedure
#   #1.configHttpClientAction
#   #2.configHttpClientAgent
#   #3.configHttpServerAgent
#   #4.configHttpServerWebPage

namespace eval IXIA {
   #--
   # Config HttpClientAction
   #--
   #Parameters:
   #         -- actName , activity name , such as "HTTPClient1"
   #         -- clrflag , flag to clear the action List, if it is 1, then clear the action list
   #         -- args ,  |key, value| , parameters of ixHttpCommand object  
   #           - commandtype , Command type, can be one of "GET","DELETE","HEAD","POST","PUT".
   #           - cmdname     , Command Name 
   #           - pageobject  , page object , such as /1k.html  
   #           - destination , destination ,web address ,such as http://10.70.80.90:90
   #           - loopcount  ,loop count
   #           - thinkinterval ,think interval 
   #Return:
   #         0 , if got success   
   #         raise error or turn 1 if failed
   #--
   #    
   proc configHttpClientAction { actName {clrflag 1} args} {
      set tag "proc configHttpClientAction [info script]"
      Deputs "----- TAG: $tag -----"
      Deputs " clrflag = $clrflag"
      set actObj [ getActivity $actName ]
      set commandList1 [list  "GET" "DELETE" "HEAD" "POST"  "PUT"]
      set commandList2 [list "LoopBeginCommand" "THINK" "LoopEndCommand"]
         if { $clrflag } {
            $actObj agent.actionList.clear
         }

         foreach { key value } $args {
            Deputs "config -$key--$value"
            set key [string tolower $key]
            switch -exact -- $key {
               -commandtype { 
                  set commandtype $value 
               }
               -cmdname {
                  set cmdname  $value
               }
               -pageobject {
                  set pageobj $value
               }
               -destination { 
                  set destination $value 
               }
               -loopcount {
                  set loopcount $value
               }
               -thinkinterval {
                  set thinkinterval $value
               }
            }
         }
         if { [lsearch $commandList1 $commandtype ] >=0 } { 
            # my_ixHttpCommand is for version above 5.60
            Deputs "config $commandtype start "
            set my_ixHttpCommand [::IxLoad new ixHttpCommand]
            $my_ixHttpCommand  config  -commandType $commandtype 
            $my_ixHttpCommand  config  -cmdName $cmdname
            
            if { [info exists pageobj] } {
               $my_ixHttpCommand  config  -pageObject $pageobj
            }
            if { [info exists destination ] } {
               $my_ixHttpCommand  config  -destination $destination
            }  
            $actObj agent.actionList.appendItem -object $my_ixHttpCommand
            Deputs "config $commandtype end "
         }

         if { $commandtype == "LoopBeginCommand" } {
            Deputs "config $commandtype start " 
            set my_ixLoopBeginCommand [::IxLoad new ixLoopBeginCommand]
            if { [info exists loopcount] == 0 } {
               set loopcount 5
            }
            $my_ixLoopBeginCommand config \
               -commandType                             $commandtype \
               -LoopCount                               $loopcount \
               -cmdName                                 $cmdname 

            $actObj agent.actionList.appendItem -object $my_ixLoopBeginCommand 
            Deputs "config $commandtype end "
         }
         Deputs "begin end"
         if { $commandtype == "THINK" } {
            Deputs "config $commandtype start "
            set my_ixThinkCommand [::IxLoad new ixThinkCommand]
            if { [info exists thinkinterval] ==0 } { 
               set thinkinterval 1000
            }
            $my_ixThinkCommand config \
               -commandType                             $commandtype \
               -minimumInterval                         $thinkinterval \
               -maximumInterval                         $thinkinterval \
               -cmdName                                 $cmdname 
            $actObj agent.actionList.appendItem -object $my_ixThinkCommand
            Deputs "config $commandtype end "
         }
         Deputs "think end"
         if { $commandtype == "LoopEndCommand" } {
            Deputs "config $commandtype start "
            set my_ixLoopEndCommand [::IxLoad new ixLoopEndCommand]
            $my_ixLoopEndCommand config \
               -commandType                             $commandtype \
               -cmdName                                 $cmdname 
   
            $actObj agent.actionList.appendItem -object $my_ixLoopEndCommand
            Deputs "config $commandtype end "
         }
         Deputs "loop end end "
         
      return 0
   }
   
    
   #--
   # Config HttpClientAgent
   #--
   #Parameters: 
   #         -- actName , activity name , such as "HTTPClient1"
   #         -- args  |key, value|
   #            - enablessl   ,enable ssl or not , true or false
   #            - certificate ,certification of ssl
   #            - privateKey ,ssl private key
   #            - httpversion ,http version, can be  0 or 1 
   #            - maxpersistentrequests, Transaction/TCP, default 0
   #            - keepalive   ,true or false
   #            - maxsessions ,TCP/User,default 1
   #            - esm         ,effective Send MSS ,default 64
   #            - maxpipeline ,max pipe line,default 1
   #            - enablecookie ,enable cookie or not, true or false  
   #            - 
   #Return  :
   #          0 , if got success   
   #          raise error if failed   
   #--
   #
   proc configHttpClientAgent { actName args } {
      set tag "proc configHttpClientAgent [info script]"
      Deputs "----- TAG: $tag -----"
      set actObj [ getActivity $actName ]
      foreach { key value } $args {
         Deputs "config $key --$value"
         set key [string tolower $key]
         switch -exact -- $key {
             -enablessl {
               set enablessl $value
               Deputs "actObj agent.config  -enableSsl $enablessl"
               $actObj agent.config  -enableSsl $enablessl 
            }
            -certificate {
               set certificate $value
               Deputs "actObj agent.config  -certificate $certificate"
               $actObj agent.config  -certificate $certificate 
            }
            -privatekey {
               set privateKey $value
               Deputs "actObj agent.config  -privateKey $privateKey"
               $actObj agent.config  -privateKey $privateKey 
            }
            -enablecookie {
               set enableCookieSupport $value
               Deputs "actObj agent.config  -enableCookieSupport $enableCookieSupport"
               $actObj agent.config  -enableCookieSupport $enableCookieSupport 
            }
             -httpversion {
               set httpversion $value
               Deputs "actObj agent.config -httpVersion $httpversion"
               $actObj agent.config -httpVersion $httpversion
            }
             -maxpersistentrequests {
               set maxpersistentrequests $value
               Deputs "actObj agent.config -maxPersistentRequests $value"
               $actObj agent.config -maxPersistentRequests $value
            }
             -keepalive {
               set keepalive $value
               Deputs "actObj agent.config -keepAlive $keepalive"
               $actObj agent.config -keepAlive $keepalive
            }
             -maxsessions {
               set maxsessions $value
               Deputs "actObj agent.config -maxSessions $maxsessions"
               $actObj agent.config -maxSessions $maxsessions
            }
             -esm {
               set esm $value
               Deputs "actObj agent.config -esm  $value  -enableEsm  true"
               $actObj agent.config -esm  $value  -enableEsm  true
            }
             -maxpipeline {
               set maxpipeline $value
               Deputs "actObj agent.config -maxPipeline $value"
               $actObj agent.config -maxPipeline $value
            }
         }
      }
      #set enableEsm default value
      if {[info exists esm] == 0} {
         $actObj agent.config -esm  $value  -enableEsm  false
      }
      return 0 
   }
    #--
   # configHttpServerAgent
   #--
   #Parameters:
   #         -- actName , activity name , such as "HTTPServer1"
   #         -- args  |key, value|
   #            - httpport              ,server port,default 80
   #            - acceptsslconnections  ,enable ssl or not , ture or false
   #            - certificate ,certification of ssl
   #            - privateKey ,ssl private key
   #Return  :
   #          0 , if got success   
   #          raise error if failed 
   #--
   #
   proc configHttpServerAgent {actName args} {
      set tag "proc configHttpClientAgent [info script]"
      Deputs "----- TAG: $tag -----"
      set actObj [ getActivity $actName ]
      foreach { key value } $args {
         Deputs "config $key---$value"
         set key [string tolower $key]
         switch -exact -- $key {
             -httpport {
               Deputs "actObj agent.config  -httpPort $value"
               $actObj agent.config  -httpPort $value
            }
            -certificate {
               set certificate $value
               Deputs "actObj agent.config  -certificate $certificate"
               $actObj agent.config  -certificate $certificate 
            }
            -privatekey {
               set privateKey $value
               Deputs "actObj agent.config  -privateKey $privateKey"
               $actObj agent.config  -privateKey $privateKey 
            }
            -acceptsslconnections {
               set acceptsslconnections $value
               Deputs "actObj agent.config  -acceptSslConnections $acceptsslconnections"
               $actObj agent.config  -acceptSslConnections $acceptsslconnections
            }            
         }
      }
         return 0 
   }
   
   #--
   # configHttpServerWebPage
   #--
   #Parameters:
   #         -- actName , activity name , such as "HTTPServer1"
   #         -- clrflag ,flag to clear the webPage List, if it is 0, then clear the webPage list
   #         -- args , |key, value| , parameters of PageObject
   #            - page      ,page name ,such as "/1k.html"
   #            - payloadSize ,page size,default 1024
   #Return  :
   #          0 , if got success   
   #          raise error if failed       
   #--
   #
   proc configHttpServerWebPage {actName {clrflag 1} args} {
      set tag "proc configHttpServerWebPage [info script]"
      Deputs "----- TAG: $tag -----"

      set actObj [ getActivity $actName ]
      Deputs " clrflag = $clrflag"
      if { $clrflag == 0} {
         $actObj agent.webPageList.clear
      }
      set my_PageObject1 [::IxLoad new PageObject]
      foreach { key value } $args {
         set key [string tolower $key]
         switch -exact -- $key {
            -page {
               Deputs "my_PageObject1  config  -page $value"
               $my_PageObject1  config  -page $value
            }
            -payloadsize {
               Deputs "my_PageObject1  config  -payloadSize $value"
               $my_PageObject1  config  -payloadSize $value
            }
         }
       }
      $actObj agent.webPageList.appendItem -object $my_PageObject1
      return 0 
   }
}
