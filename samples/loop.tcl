lappend ::auto_path [file dirname [file dirname [pwd]] ]

puts "Loading IXIA libraries"
package require IxRepository
#source {Z:\Ixia\Workspace\ixia-ixLoad-ixRepository-API\IxRepository.tcl}
set testName "loop"
set chassis "172.16.174.134"

puts "Connecting to Serveer..."
IXIA::connect

puts "Loading configuration file: [pwd]/configs/$testName.rxf"
IXIA::loadRepository "[pwd]/configs/$testName.rxf"

puts "Configure Chassis..."
IXIA::configRepository -chassis [list "$chassis"]

# ����4�����ö˿ڶ�Ӧ��ϵ
puts "Configure Network..."
IXIA::configNetwork Network1 -port [list "$chassis/1/1"] -enable true
IXIA::configNetwork Network2 -port [list "$chassis/2/1"] -enable true

# ����2����������
IXIA::configObjective HTTPClient1  -userObjectiveType simulatedUsers  \
                        -userObjectiveValue 100

# ����3������Sustain Time
IXIA::configActivityTimeline HTTPClient1 -sustaintime 111

# ���������ļ��Ա������ò����Ƿ���ȷ
IXIA::save [file join [pwd] Result/Configs/$testName.rxf]

# set statlist [list http_client_throughput \
        # http_client_transactions \
        # http_client_transactions_bytes_sent ]

# ����5������Sustain Time
#set statlist http_client_connection_rate
set statlist [list http_client_throughput]

IXIA::selectStats $statlist
IXIA::run
IXIA::startCapture

set loop 5
while { $loop > 0 } {
    set timeout 0
    while { 1 } {
        # -- check result every 5 sec
        after 5000 set wakeup 1
        #==========================================================================
        # YOU should customize your real statistics here
        set ret [ IXIA::getInstantStats http_client_throughput ]
        puts "loop:$loop, ret:$ret"
        
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
    incr loop -1
}
#IXIA::generateReport










