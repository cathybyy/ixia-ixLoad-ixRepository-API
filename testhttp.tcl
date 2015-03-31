cd {E:\ixia_project\ixload\ixload_code\huawei_auto\code}
source "ixrepository.tcl"
source "stats.tcl"
namespace import IXIA::*
connect
loadRepository "C:/http.rxf"
IXIA::configNetwork Network1  -media copper  \
                        -auto_nego false  \
                        -speed 100m   \
                        -arp_response true 
configNetwork Network1  -mac 00:01:01:01:01:01 -vlan_id 100 -ip 192.168.1.1 -ipcount 10 \
                       -ipincrby  0.0.0.1  -netmask 24  -gateway 192.168.1.10  -gratuitous_arp true  -dns_domain www.huawei.com  -dns_server 10.70.80.90 
configHttpClientAgent HTTPClient1  -enableSsl true  -httpVersion 0  -maxPersistentRequests 0  -keepAlive true  -maxSessions 44  -esm 128  -maxPipeline 33 
configObjective HTTPClient1  -userObjectiveType simulatedUsers  -userObjectiveValue 77  
configActivityTimeline HTTPClient1  -segment0duration 11  -segment1duration 13  -segment2duration 111  -standbyTime 0 
configObjective HTTPClient1  -enableconstraint true  -constraintvalue 1 
 configHttpClientAction HTTPClient1 0  -commandType GET -cmdName  GET_0   -destination http://10.70.80.90:90 -pageObject /1k.html  
 configHttpClientAction HTTPClient1 1  -commandType GET -cmdName  GET_1   -destination http://10.70.80.90:90 -pageObject /4k.html  
save {c:\Network1.rxf} 
configNetwork Network2  -media copper  -auto_nego false  -speed 100m  -arp_response true 
configNetwork Network2  -mac 00:01:01:01:01:01 -vlan_id 100 -ip 192.168.1.1 -ipcount 1 -ipincrby 0.0.0.0  -netmask 24  -gateway 192.168.1.10  -gratuitous_arp true  -dns_domain www.huawei.com  -dns_server 10.70.80.90 
 configHttpServerAgent HTTPServer1  -httpPort 81  -acceptSslConnections true  
 configHttpServerWebPage HTTPServer1 0 -page /1k.html  -chunkSize 1024  
 configHttpServerWebPage HTTPServer1 1 -page /4k.html  -chunkSize 1024  
save {c:\Network2.rxf} 

#source "ixrepository.tcl"
#source "stats.tcl"
#namespace import IXIA::*
#connect
#loadRepository "C:/http.rxf"
#configNetwork Network1  -media copper  -auto_nego false  -speed 100m  -arp_response true 
#save {c:\Networ1.rxf} 
#configNetwork Network1  -mac 00:01:01:01:01:01 -vlan_id 100 -ip 192.168.1.1 -ipcount 10 -ipincrby  0.0.0.1  -netmask 24  -gateway 192.168.1.10  -gratuitous_arp true  -dns_domain www.huawei.com  -dns_server 10.70.80.90 
#configHttpClientAgent HTTPClient1  -enableSsl true  -httpVersion 0  -maxPersistentRequests 0  -keepAlive true  -maxSessions 1  -esm 64  -maxPipeline 1 
# configObjective HTTPClient1  -userObjectiveType simulatedUsers  -userObjectiveValue 100  
#save {c:\Network2.rxf} 
#configActivityTimeline HTTPClient1  -segment0duration 10  -segment1duration 10  -segment2duration 10  -standbyTime 0 
#configObjective HTTPClient1  -enableconstraint true  -constraintvalue 1 
#save {c:\Network3.rxf} 
#configHttpClientAction HTTPClient1 0  -commandType GET -cmdName  GET_0   -destination http://10.70.80.90:90 -pageObject /1k.html  
#configHttpClientAction HTTPClient1 1  -commandType GET -cmdName  GET_1   -destination http://10.70.80.90:90 -pageObject /4k.html  
#save {c:\Network4.rxf} 
#configNetwork Network2  -media copper  -auto_nego false  -speed 100m  -arp_response true 
#configNetwork Network2  -mac 00:01:01:01:01:01 -vlan_id 100 -ip 192.168.1.1 -ipcount 1 -ipincrby '0.0.0.0'  -netmask 24  -gateway 192.168.1.10  -gratuitous_arp true  -dns_domain www.huawei.com  -dns_server 10.70.80.90 
#save {c:\Network5.rxf} 
#configHttpServerAgent HTTPServer1  -httpPort 80  -acceptSslConnections true  
#configHttpServerWebPage HTTPServer1 0 -page /1k.html  -chunkSize 1024  
#configHttpServerWebPage HTTPServer1 1 -page /4k.html  -chunkSize 1024  
#save {c:\Network6.rxf} 
