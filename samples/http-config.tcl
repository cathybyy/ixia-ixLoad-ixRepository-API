lappend ::auto_path [file dirname [pwd]]

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
                        -maxPipeline 33 \
                        -certificate "-----BEGIN CERTIFICATE-----
                                        MIICoTCCAkagAwIBAgIBAjAKBggqhkjOPQQDAjCBmTELMAkGA1UEBhMCVVMxCzAJ
                                        BgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMSIwIAYDVQQKDBlJbnNpZGUgU2Vj
                                        dXJlIENvcnBvcmF0aW9uMQ0wCwYDVQQLDARUZXN0MTgwNgYDVQQDDC9NYXRyaXhT
                                        U0wgU2FtcGxlIENBIChFbGxpcHRpYyBjdXJ2ZSBwcmltZTI1NnYxKTAeFw0xMzAy
                                        MTExODUzNTJaFw0xNjAyMTExODUzNTJaMIGbMQswCQYDVQQGEwJVUzELMAkGA1UE
                                        CAwCV0ExEDAOBgNVBAcMB1NlYXR0bGUxIjAgBgNVBAoMGUluc2lkZSBTZWN1cmUg
                                        Q29ycG9yYXRpb24xDTALBgNVBAsMBFRlc3QxOjA4BgNVBAMMMU1hdHJpeFNTTCBT
                                        YW1wbGUgQ2VydCAoRWxsaXB0aWMgY3VydmUgcHJpbWUyNTZ2MSkwWTATBgcqhkjO
                                        PQIBBggqhkjOPQMBBwNCAARfrWICQki6++KI2H+5cssorsOKHsMOnH16pLV/2r1G
                                        WrmVOeBEUXG647NA8lT9I4Sy6iqEo0/XsAi6boDD698vo3sweTAJBgNVHRMEAjAA
                                        MCwGCWCGSAGG+EIBDQQfFh1PcGVuU1NMIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAd
                                        BgNVHQ4EFgQUH4B1U63JfesJeCargBgJHGjUuIMwHwYDVR0jBBgwFoAUaQ76Rz5t
                                        QPkpf/dvZoa4ejS7JeswCgYIKoZIzj0EAwIDSQAwRgIhAPGs/h8Taf+87UwryAIv
                                        wr0lvXmom4Y3Q2eT/i5gmNveAiEA66bj18zgAP9qqH3yZj5w6EfmqkoKiaSrCBTV
                                        o22GI+E=
                                        -----END CERTIFICATE-----
                                        "\
                        -privateKey "-----BEGIN EC PARAMETERS-----
                                        BggqhkjOPQMBBw==
                                        -----END EC PARAMETERS-----
                                        -----BEGIN EC PRIVATE KEY-----
                                        MHcCAQEEIFzpicWxU6ACPJC+OipzsggWw+281dZnJhBO7HkoD7/LoAoGCCqGSM49
                                        AwEHoUQDQgAEX61iAkJIuvviiNh/uXLLKK7Dih7DDpx9eqS1f9q9Rlq5lTngRFFx
                                        uuOzQPJU/SOEsuoqhKNP17AIum6Aw+vfLw==
                                        -----END EC PRIVATE KEY-----
                                        "\
                        -enablCookie true
                                        
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
                        -certificate "-----BEGIN CERTIFICATE-----
                                        MIICoTCCAkagAwIBAgIBAjAKBggqhkjOPQQDAjCBmTELMAkGA1UEBhMCVVMxCzAJ
                                        BgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMSIwIAYDVQQKDBlJbnNpZGUgU2Vj
                                        dXJlIENvcnBvcmF0aW9uMQ0wCwYDVQQLDARUZXN0MTgwNgYDVQQDDC9NYXRyaXhT
                                        U0wgU2FtcGxlIENBIChFbGxpcHRpYyBjdXJ2ZSBwcmltZTI1NnYxKTAeFw0xMzAy
                                        MTExODUzNTJaFw0xNjAyMTExODUzNTJaMIGbMQswCQYDVQQGEwJVUzELMAkGA1UE
                                        CAwCV0ExEDAOBgNVBAcMB1NlYXR0bGUxIjAgBgNVBAoMGUluc2lkZSBTZWN1cmUg
                                        Q29ycG9yYXRpb24xDTALBgNVBAsMBFRlc3QxOjA4BgNVBAMMMU1hdHJpeFNTTCBT
                                        YW1wbGUgQ2VydCAoRWxsaXB0aWMgY3VydmUgcHJpbWUyNTZ2MSkwWTATBgcqhkjO
                                        PQIBBggqhkjOPQMBBwNCAARfrWICQki6++KI2H+5cssorsOKHsMOnH16pLV/2r1G
                                        WrmVOeBEUXG647NA8lT9I4Sy6iqEo0/XsAi6boDD698vo3sweTAJBgNVHRMEAjAA
                                        MCwGCWCGSAGG+EIBDQQfFh1PcGVuU1NMIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAd
                                        BgNVHQ4EFgQUH4B1U63JfesJeCargBgJHGjUuIMwHwYDVR0jBBgwFoAUaQ76Rz5t
                                        QPkpf/dvZoa4ejS7JeswCgYIKoZIzj0EAwIDSQAwRgIhAPGs/h8Taf+87UwryAIv
                                        wr0lvXmom4Y3Q2eT/i5gmNveAiEA66bj18zgAP9qqH3yZj5w6EfmqkoKiaSrCBTV
                                        o22GI+E=
                                        -----END CERTIFICATE-----
                                        "\
                        -privateKey "-----BEGIN EC PARAMETERS-----
                                        BggqhkjOPQMBBw==
                                        -----END EC PARAMETERS-----
                                        -----BEGIN EC PRIVATE KEY-----
                                        MHcCAQEEIFzpicWxU6ACPJC+OipzsggWw+281dZnJhBO7HkoD7/LoAoGCCqGSM49
                                        AwEHoUQDQgAEX61iAkJIuvviiNh/uXLLKK7Dih7DDpx9eqS1f9q9Rlq5lTngRFFx
                                        uuOzQPJU/SOEsuoqhKNP17AIum6Aw+vfLw==
                                        -----END EC PRIVATE KEY-----
                                        "\
                        -acceptSslConnections true  
IXIA::configHttpServerWebPage HTTPServer1 0 -page /1k.html  \
                        -payloadsize 1024  
IXIA::configHttpServerWebPage HTTPServer1 1 -page /4k.html  \
                        -chunkSize 1024
IXIA::save [file join [pwd] $restoreDir/IxLoad-HTTP.rxf]
