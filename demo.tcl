cd "e:/project/ixload hlapi"

source stats.tcl
source ixrepository.tcl

IXIA::connect

IXIA::loadRepository {d:\demoRep.rxf}

# set statlist [list http_client_throughput \
	# http_client_transactions \
	# http_client_transactions_bytes_sent ]
	
set statlist http_client_throughput
	
IXIA::selectStats $statlist

IXIA::run

set timeout 0
while { 1 } {

	# -- check result every 10 sec
	after 10000 set wakeup 1
#==========================================================================
# YOU should customize your real statistics here

	set ret [ IXIA::getInstantStats http_client_throughput ]

	puts "ret:$ret"

	# -- make a judgement whether to reach your result
	if { $ret != "" && $ret } {
		break
	}
#==========================================================================
	incr timeout

	if { $timeout > 5 } {
		break
	}
	vwait wakeup
	

}

# -- You can wait to stop or just stop manually
# -- If you choose to get final result, please use waitForTestStop and then get the result
# set waitx [IXIA::waitForTestStop]
IXIA::stop










