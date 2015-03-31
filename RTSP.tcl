package provide IxRTSP  1.1

# RTSP.tcl--
#   This file implements the Tcl encapsulation of RTSP emulation
#
# Copyright (c) Ixia technologies, Inc.

#       package version 1.1
#       release version 1.0
#============
# Change made
#============
# Version 1.0.1.0
# a. Eric-- Create
#       Procedure
#   #1.RTSP_AppendCommand
#   #2.RTSP_ClearCommand
#   #3.RTSP_DeleteCommand
#   #4.RTSP_Config
# Version 1.1.1.0
# b. Eric-- Append
#       Procedure
#   #5.RTSP_AppendPresentation
#   #6.RTSP_ClearHeader
#   #7.RTSP_ClearPresentation
#   #8.RTSP_ConfigHeader
#   #9.RTSP_DeletePresentation
#   #10.RTSP_PRESENT_StreamInit

namespace eval IXIA {
   
   set ::cmdIndex   1

   set ::_PRESENT_VOICE      ""
   set ::_PRESENT_MP3_64K    ""
   set ::_PRESENT_MP3_128K   ""
   set ::_PRESENT_MPEG2      ""
   set ::_PRESENT_MPEG4      ""
   set ::_PRESENT_MPEG_MP3   ""
   #--
   # RTSP action - append command to command list
   #--
   proc RTSP_AppendCommand { actName args } {
      
      global cmdIndex
       
      set tag "proc RTSP_AppendCommand [info script]"
      Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      
      set appendParam [ list ]
      
      foreach { key value } $args {
         set key [string tolower $key]
         switch -exact -- $key {
            -type {                
               set actType $value
                  if { $value == "KeepAlive" } {
                        set actType  "\{KeepAlive\}"
                        Deputs "set actType  \{KeepAlive\} "
                     } 
                  if {  $value == "PlayMedia" } {
                     set actType  "\{PlayMedia\}"
                     Deputs "set actType  \{PlayMedia\} "
                     }
                  
            }
            -media {
               set media $value
            }
            -destination {
               set dest $value
            }
            -arguments {
               set arguments $value
            }
            -cmdname {
               set name $value
            }
            -index {
               set index $value
            }
            -loopcount {
               set loopCnt $value
            }
         }
      }
      
      set name "$actType $cmdIndex"
Deputs "name:$name"
      incr cmdIndex
Deputs "cmdIndex:$cmdIndex"
         #add by celia on version 1.1 start to add loopbegin and loopend start
         if { $actType == "LoopBeginCommand"  } {
            set my_ixLoopBeginCommand [::IxLoad new ixLoopBeginCommand]
            $my_ixLoopBeginCommand config \
                    -commandType                             "LoopBeginCommand" \
                    -LoopCount                               5 \
                    -cmdName                                 "Loop Begin 38" 
            
            $actObj agent.commandList.appendItem -object $my_ixLoopBeginCommand
             if { [ info exists loopCnt ] } {
                  catch {
                     $my_ixLoopBeginCommand config -LoopCount $loopCnt
                  }
             } 
         } elseif { $actType == "LoopEndCommand"  } {
               set my_ixLoopEndCommand [::IxLoad new ixLoopEndCommand]
               $my_ixLoopEndCommand config \
                    -commandType                             "LoopEndCommand" \
                    -cmdName                                 $name 
            
             $actObj agent.commandList.appendItem -object $my_ixLoopEndCommand
        
         #add by celia on version 1.1 start to add loopbegin and loopend end
         } else { 
                  set my_ixRtspCommand [::IxLoad new ixRtspCommand]
                  
                  $my_ixRtspCommand config \
                     -commandType $actType \
                     -cmdName $name
                      Deputs Step10
                  if { [ info exists arguments ] } {
                     catch {
                        $my_ixRtspCommand config -arguments $arguments
                     }
                  }
                      Deputs Step20
                  if { [ info exists media ] } {
                     catch {
                        $my_ixRtspCommand config -media   $media
                     }
                  }
                    Deputs Step30
                  if { [ info exists dest ] } {
                     catch {
            Deputs Step31
                        $my_ixRtspCommand config -destination $dest
            Deputs Step32
                     }
                  }
            Deputs Step40 
                  
                  $actObj agent.commandList.appendItem -object $my_ixRtspCommand
            Deputs Step60
         }
   }
   
   #--
   # RTSP action - append presentation to presentation list
   #--
   proc RTSP_AppendPresentation { actName args } {
       
      set tag "proc RTSP_AppendPresentation [info script]"
Deputs "----- TAG: $tag -----"
      
      global _PRESENT_VOICE
      global _PRESENT_MP3_64K
      global _PRESENT_MP3_128K
      global _PRESENT_MPEG2
      global _PRESENT_MPEG4
      global _PRESENT_MPEG_MP3
      
      set duration 30
      
      set actObj [ getActivity $actName ]
      
      if {  ( $_PRESENT_VOICE == "" ) ||
            ( $_PRESENT_MP3_64K == "" ) ||
            ( $_PRESENT_MP3_128K == "" ) ||
            ( $_PRESENT_MPEG2 == "" ) ||
            ( $_PRESENT_MPEG4 == "" ) ||
            ( $_PRESENT_MPEG_MP3 == "" ) } {
         RTSP_PRESENT_StreamInit
      }
      
      
      foreach { key value } $args {
         set key [string tolower $key]
         switch -exact -- $key {
            -duration {
               set duration $value
            }
            -path {
               set path $value
            }
            -content {
               set content $value
            }
         }
      }
         
      set my_PresentationItem [::IxLoad new PresentationItem]
   
      if { [ info exists duration ] } {
         catch {
            $my_PresentationItem config -duration $duration
         }
      }
      if { [ info exists path ] } {
         catch {
            $my_ixRtspCommand config -path   "\"$path\""
         }
      }
      if { [ info exists content ] } {
         if { [ info exists ::_PRESENT_[string toupper $content] ] == 0 } {
            error "Wrong value of -content when add presentation, which should be one of \
                     \n\t _PRESENT_VOICE \
                     \n\t_PRESENT_MP3_64K \
                     \n\t_PRESENT_MP3_128K \
                     \n\t_PRESENT_MPEG2 \
                     \n\t_PRESENT_MPEG4 \
                     \n\t_PRESENT_MPEG4_MP3"
         } 
         catch {
            $my_ixRtspCommand config -content $IXIA::_PRESENT_[string toupper $content]
         }
      }

      $actObj agent.presentationList.appendItem -object $my_PresentationItem
   }
   
   #--
   # RTSP action - clear command list
   #--
   proc RTSP_ClearCommand { actName } {
      set tag "proc RTSP_ClearCommand [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      $actObj agent.commandList.clear
      
   }
   #--
   # RTSP action - clear header list
   #--
   proc RTSP_ClearHeader { actName } {
      set tag "proc RTSP_ClearHeader [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      $actObj agent.headerList.clear
      
   }
   #--
   # RTSP action - clear presnetation list
   #--
   proc RTSP_ClearPresentation { actName } {
      set tag "proc RTSP_ClearPresentation [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      $actObj agent.presentationList.clear
      
   }
   #--
   # RTSP configuration
   #--
   proc RTSP_Config { actName args } {
      set tag "proc RTSP_Config [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      
      foreach { key value } $args {
         set key [string tolower $key]
         switch -exact -- $key {
            -transport {
               set transport $value
            }
            -port {
               set port $value
            }
            -timeout {
               set timeout $value
            }
         }
      }
      
      if { [ info exists transport ] } {
         if { [ regexp -nocase {TCP|UDP} $transport ] == 0 } {
            error "Wrong value of -transport, which should be one of UDP|TCP..."
         }
         set transport [ string totitle $transport ]
         $actObj agent.config -rtpTransport $::RTSP_Client(kRtpTransport$transport)
      }
      
      if { [ info exists port ] } {
         $actObj agent.config -port $port
      }
      
      
      if { [ info exists timeout ] } {
         $actObj agent.config -commandTimeout $timeout
      }
   }
   #--
   # RTSP Header configuration
   #--
   proc RTSP_ConfigHeader { actName args } {
      set tag "proc RTSP_ConfigHeader [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      
      foreach { key value } $args {
         set key [string tolower $key]
         switch -exact -- $key {
            -name {
               lappend headName $value
            }
            -value {
               lappend headValue $value
            }
         }
      }
      
      if { [ info exists headName ] == 0 || [ info exists headValue ] == 0 } {
         
         error "Madatory parameter missed...\"-name\" or \"-value\""
      } else {
         set my_RtspHeaders [::IxLoad new RtspHeaders]
         $my_RtspHeaders list.clear
      }
      
      
      set index       0
      set flagNameEnd 0
      set flagValEnd  0
      set name [ lindex $headName 0 ]
      set val  [ lindex $headValue 0 ]
      while { 1 } {
         if { $index == [ expr [ llength $headName ] - 1 ] } {
            set name [ lindex $headName [ expr $index % [llength $headName ] ] ]
            set flagNameEnd 1
         } else {
            set name [ lindex $headName $index ]
         }
         if { $index == [ expr [ llength $headValue ] - 1 ] } {
            set val  [ lindex $headValue [ expr $index % [llength $headValue ] ] ]
            set flagValEnd 1
         } else {
            set val  [ lindex $headValue $index ]
         }
         
         if { $flagNameEnd && $flagValEnd } {
            break
         }
         
         set User_Agent [::IxLoad new RtspHeader]
         $User_Agent config \
                 -name                                    $name \
                 -value                                   $val 
         $my_RtspHeaders list.appendItem -object $User_Agent
         
         incr index
      }
      
      $actObj agent.config -rtspHeaders $my_RtspHeaders 
      
   }
   
   #--
   # RTSP action - delete command item
   #--
   proc RTSP_DeleteCommand { actName index } {
      set tag "proc RTSP_DeleteCommand [info script]"
Deputs "----- TAG: $tag -----"

      global cmdIndex
      
      set actObj [ getActivity $actName ]
Deputs "actObj:$actObj"
      $actObj agent.commandList.deleteItem $index
      
      set cmdIndex 1

   }
   
   #--
   # RTSP action - delete presentation item
   #--
   proc RTSP_DeletePresentation { actName index } {
      set tag "proc RTSP_DeletePresentation [info script]"
Deputs "----- TAG: $tag -----"
      
      set actObj [ getActivity $actName ]
      $actObj agent.presentationList.deleteItem $index
      
   }
   
   #--
   # RTSP Presentation Stream initilization
   #--
   proc RTSP_PRESENT_StreamInit {} {
      set tag "proc RTSP_PRESENT_StreamInit [info script]"
Deputs "----- TAG: $tag -----"
      
      global _PRESENT_VOICE 
      global _PRESENT_MP3_64K
      global _PRESENT_MP3_128K
      global _PRESENT_MPEG2   
      global _PRESENT_MPEG4   
      global _PRESENT_MPEG4_MP3
      
      #========
      #-- VOICE
      set Voice__1016_ [::IxLoad new Content]
      $Voice__1016_ streamList.clear
      
      set my_Stream [::IxLoad new Stream]
      $my_Stream config \
              -clockRate                               "Audio 8 bit (8000 Hz)" \
              -dataRate                                0.48 \
              -packetization                           200 
      
      $Voice__1016_ streamList.appendItem -object $my_Stream
      
      $Voice__1016_ config \
              -name                                    "Voice (1016)"
      set _PRESENT_VOICE $Voice__1016_
      
      #========
      #-- MP3_128K
      set MP3_128kbit [::IxLoad new Content]
      $MP3_128kbit streamList.clear
      
      set my_Stream1 [::IxLoad new Stream]
      $my_Stream1 config \
              -clockRate                               "Audio MP3 (90000 Hz)" \
              -dataRate                                128.0 \
              -packetization                           20 
      
      $MP3_128kbit streamList.appendItem -object $my_Stream1
      
      $MP3_128kbit config \
              -name                                    "MP3/128kbit" 
      set _PRESENT_MP3_128K $MP3_128kbit
      
      #========
      #-- MPEG2
      set MPEG_2 [::IxLoad new Content]
      $MPEG_2 streamList.clear
      
      set my_Stream2 [::IxLoad new Stream]
      $my_Stream2 config \
              -clockRate                               "Video (90000 Hz)" \
              -dataRate                                4000.0 \
              -packetization                           2 
      
      $MPEG_2 streamList.appendItem -object $my_Stream2
      
      $MPEG_2 config \
              -name                                    "MPEG-2" 
      set _PRESENT_MPEG2 $MPEG_2

      #========
      #-- MPEG4
      set MPEG_4 [::IxLoad new Content]
      $MPEG_4 streamList.clear
      
      set my_Stream3 [::IxLoad new Stream]
      $my_Stream3 config \
              -clockRate                               "Video (90000 Hz)" \
              -dataRate                                300.0 \
              -packetization                           20 
      
      $MPEG_4 streamList.appendItem -object $my_Stream3
      
      $MPEG_4 config \
              -name                                    "MPEG-4"
      set _PRESENT_MPEG4 $MPEG_4
      
      #========
      #-- MP3_64K
      set MP3_64kbit [::IxLoad new Content]
      $MP3_64kbit streamList.clear
      
      set my_Stream4 [::IxLoad new Stream]
      $my_Stream4 config \
              -clockRate                               "Audio MP3 (90000 Hz)" \
              -dataRate                                64.0 \
              -packetization                           20 
      
      $MP3_64kbit streamList.appendItem -object $my_Stream4
      
      $MP3_64kbit config \
              -name                                    "MP3/64kbit" 
      set _PRESENT_MP3_64K $MP3_64kbit
      
      #========
      #-- MPEG4_MP3
      set MPEG_4_MP3 [::IxLoad new Content]
      $MPEG_4_MP3 streamList.clear
      
      set my_Stream6 [::IxLoad new Stream]
      $my_Stream6 config \
              -clockRate                               "Audio MP3 (90000 Hz)" \
              -dataRate                                128.0 \
              -packetization                           20 
      
      $MPEG_4_MP3 streamList.appendItem -object $my_Stream6
      
      set my_Stream7 [::IxLoad new Stream]
      $my_Stream7 config \
              -clockRate                               "Video (90000 Hz)" \
              -dataRate                                300.0 \
              -packetization                           20 
      
      $MPEG_4_MP3 streamList.appendItem -object $my_Stream7
      
      $MPEG_4_MP3 config \
              -name                                    "MPEG-4/MP3" 
      
      set _PRESENT_MPEG4_MP3 $MPEG_4_MP3
      
      
   }
}