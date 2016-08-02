lappend ::auto_path [file dirname [pwd]]

puts "Loading IXIA libraries"
#package require IxRepository
source {C:\Ixia\Workspace\ixia-ixLoad-ixRepository-API\IxRepository.tcl}

puts "Connecting to Serveer..."
IXIA::connect

puts "Loading configuration file: [pwd]/configs/HTTP.rxf"
IXIA::loadRepository "[pwd]/configs/HTTP.rxf"

puts "Configure Chassis..."
IXIA::configRepository -chassis [list "172.16.174.133"]

puts "Configure Network..."
IXIA::configNetwork Network1 -port [list "172.16.174.133/1/1"]
IXIA::configNetwork Network2 -port [list "172.16.174.133/2/1"]

#IXIA::save [file join [pwd] Result/Configs/PortMapping-HTTP.rxf]

# set statlist [list http_client_throughput \
        # http_client_transactions \
        # http_client_transactions_bytes_sent ]
    
set statlist http_client_throughput

IXIA::selectStats $statlist
IXIA::run

set timeout 0
while { 1 } {
    # -- check result every 5 sec
    after 5000 set wakeup 1
    #==========================================================================
    # YOU should customize your real statistics here
    
    set ret [ IXIA::getInstantStats http_client_throughput ]
    
    puts "ret:$ret"
    
    # -- make a judgement whether to reach your result
    if { $ret != "" && $ret } {
        vwait wakeup
        break
    }
    #==========================================================================
    incr timeout
    if { $timeout > 60 } {
        break
    }
    vwait wakeup
}

# -- You can wait to stop or just stop manually
# -- If you choose to get final result, please use waitForTestStop and then get the result
#set waitx [IXIA::waitForTestStop]
IXIA::stop
IXIA::generateReport










