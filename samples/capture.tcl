lappend ::auto_path [file dirname [pwd]]

puts "Loading IXIA libraries"
package require IxRepository
#source {C:\Ixia\Workspace\ixia-ixLoad-ixRepository-API\IxRepository.tcl}

puts "Connecting to Serveer..."
IXIA::connect

puts "Loading configuration file: [pwd]/configs/HTTP.rxf"
IXIA::loadRepository "[pwd]/configs/HTTP.rxf"

puts "Configure Chassis..."
set chassis "172.16.174.134"
IXIA::configRepository -chassis [list "$chassis"]

puts "Configure Network..."
IXIA::configNetwork Network1 -port [list "$chassis/1/1"]
IXIA::configNetwork Network2 -port [list "$chassis/3/1"]

#IXIA::save [file join [pwd] Result/Configs/PortMapping-HTTP.rxf]

# set statlist [list http_client_throughput \
        # http_client_transactions \
        # http_client_transactions_bytes_sent ]
    
set statlist http_client_throughput

IXIA::selectStats $statlist
IXIA::run
#IXIA::save [file join [pwd] Result/Configs/PortMapping-HTTP.rxf]
IXIA::startHalCapture

set timeout 0
while { 1 } {
    # -- check result every 2 sec
    after 2000 set wakeup 1
    #==========================================================================
    # YOU should customize your real statistics here
    
    set ret [ IXIA::getInstantStats http_client_throughput ]
    puts "ret:$ret"
    
    #if { $ret != "" } {
    #    IXIA::startHalCapture
    #}
    # -- make a judgement whether to reach your result
    if { $ret != "" && $ret > 0 } {
        break
    }
    #==========================================================================
    incr timeout
    if { $timeout > 120 } {
        break
    }
    vwait wakeup
}
IXIA::stopHalCapture
after 2000
IXIA::saveHalCapture -prefix ixia1
after 2000

# Save capture again
IXIA::startHalCapture
after 2000
IXIA::stopHalCapture
after 2000
IXIA::saveHalCapture -prefix ixia2
after 2000

IXIA::startHalCapture
after 2000
IXIA::stopHalCapture
after 2000
IXIA::saveHalCapture -prefix ixia3
# -- You can wait to stop or just stop manually
# -- If you choose to get final result, please use waitForTestStop and then get the result
#set waitx [IXIA::waitForTestStop]
IXIA::stop
#IXIA::generateReport










