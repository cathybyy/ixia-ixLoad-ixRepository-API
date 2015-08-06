lappend ::auto_path {C:\Ixia\Workspace\ixia-ixLoad-ixRepository-API}

package require IxRepository

set restoreDir "Result/Configs"

IXIA::connect
IXIA::loadRepository "[pwd]/configs/HTTP.rxf"
IXIA::configNetwork Network1  -media copper  \
                        -auto_nego false  \
                        -speed 100m   \
                        -arp_response true 
IXIA::configNetwork Network1  -mac 00:01:01:01:01:01 \
                        -vlan_id 100 \
                        -ip 192.168.1.1 \
                        -ipcount 10 \
                        -ipincrby  0.0.0.1  \
                        -netmask 24  \
                        -gateway 192.168.1.10  \
                        -gratuitous_arp true  \
                        -dns_domain www.huawei.com  \
                        -dns_server 10.70.80.90 
IXIA::configHttpClientAgent HTTPClient1  -enableSsl true  \
                        -httpVersion 0  \
                        -maxPersistentRequests 0  \
                        -keepAlive true  \
                        -maxSessions 44  \
                        -esm 128  \
                        -maxPipeline 33 
IXIA::configObjective HTTPClient1  -userObjectiveType simulatedUsers  \
                        -userObjectiveValue 77  
IXIA::configActivityTimeline HTTPClient1  -segment0duration 11  \
                        -segment1duration 13  \
                        -segment2duration 111  \
                        -standbyTime 0 
IXIA::configObjective HTTPClient1  -enableconstraint true  \
                        -constraintvalue 1 
IXIA::configHttpClientAction HTTPClient1 0  -commandType GET \
                        -cmdName  GET_0   \
                        -destination http://10.70.80.90:90 \
                        -pageObject /1k.html  
IXIA::configHttpClientAction HTTPClient1 1  -commandType GET \
                        -cmdName  GET_1   \
                        -destination http://10.70.80.90:90 \
                        -pageObject /4k.html  

IXIA::configNetwork Network2  -media copper  \
                        -auto_nego false  \
                        -speed 100m  \
                        -arp_response true 
IXIA::configNetwork Network2  -mac 00:02:02:02:02:02 \
                        -vlan_id 100 \
                        -ip 192.168.1.10 \
                        -ipcount 1 \
                        -ipincrby 0.0.0.1  \
                        -netmask 24  \
                        -gateway 192.168.1.1  \
                        -gratuitous_arp true  \
                        -dns_domain www.huawei.com  \
                        -dns_server 10.70.80.90 
IXIA::configHttpServerAgent HTTPServer1  -httpPort 81  \
                        -acceptSslConnections true  
IXIA::configHttpServerWebPage HTTPServer1 0 -page /1k.html  \
                        -chunkSize 1024  
IXIA::configHttpServerWebPage HTTPServer1 1 -page /4k.html  \
                        -chunkSize 1024
IXIA::save [file join [pwd] $restoreDir/IxLoad-HTTP.rxf]
