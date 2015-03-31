package provide IxStats  1.2

# stats.tcl--
#   This file implements the Tcl encapsulation of stats
#
# Copyright (c) Ixia technologies, Inc.
#       package version 1.2
#       release version 1.4
#============
# Change made
#============
# Version 1.0.1.0
# a. Eric Yu-- Create
# Version 1.1.1.1
# b. Eric Yu-- Change the stats format
# Version 1.2.1.4
# c. Eric Yu-- Delete all method but init to adapt changes from IxRepository

namespace eval IXIA {
    namespace export *
    array set StatsList [list ]
    ####################################################################################
    # Proc Name        :   initialize the protocol statsList 
    # Parameters       :   none
    # Return Value     :   none 
    # Related Script   :   Needed in IxRepository.tcl  
    # Edit Date        :   2011.02
    # Last Mod         :   2012.09 by
    # Scriptor         :   celia chen
    #####################################################################################
    proc statsInit {} {  
       
        global StatsList        

		
		# == Customize your own statistics here
  	    set StatsList(http_client_throughput) 				[list "HTTP Client" "HTTP Bytes Received" "kSum"]
        set StatsList(http_client_transactions)             [list "HTTP Client" "HTTP Transactions" "kSum"]                                              
        set StatsList(http_client_transactions_bytes_sent)  [list "HTTP Client" "HTTP Bytes Sent" "kSum"]
		# ==

		# [list "http_client_latency"              [list "HTTP Client" "HTTP Connect Time (ms)" "kWeightedAverage"] ] \
		# [list "http_client_latency_ttfb"              [list "HTTP Client" "HTTP Time To First Byte (ms)" "kWeightedAverage"] ] \
		# [list "http_client_latency_ttlb"              [list "HTTP Client" "HTTP Time To Last Byte (ms)" "kWeightedAverage"] ] \
		# [list "http_client_tcp_conn_established"      [list "HTTP Client" "TCP Connections Established" "kSum"] ] \
		# [list "http_client_tcp_conn_established_stat" [list "HTTP Client" "TCP Connections in ESTABLISHED State" "kSum"] ] \
		# [list "http_client_tcp_retries" [list "HTTP Client" "TCP Retries" "kMax"] ] \
		# [list "http_server_request_successful"        [list "HTTP Server" "HTTP Requests Successful" "kSum"] ] \
		# [list "http_server_transactions"              [list "HTTP Server" "HTTP Requests Received" "kSum"] ] \
		# [list "http_server_request_failed"            [list "HTTP Server" "HTTP Requests Failed" "kSum"] ] \
		# [list "http_server_tcp_conn_established"      [list "HTTP Server" "TCP Connections Established" "kSum"] ] \
		# [list "http_server_tcp_conn_established_stat" [list "HTTP Server" "TCP Connections in ESTABLISHED State" "kSum"] ] \
		# [list "http_server_tcp_retries" [list "HTTP Server" "TCP Retries" "kSum"] ] \
		# [list "ftp_client_throughput"                 [list "FTP Client" "FTP Data Bytes Sent" "kSum"] \
													# [list "FTP Client" "FTP Data Bytes Received" "kSum" ] \
													# [list "FTP Client" "FTP Control Bytes Sent" "kSum"]  \
													# [list "FTP Client" "FTP Control Bytes Received" "kSum"] ] \
		# [list "ftp_client_latency_contrl"        [list "FTP Client" "FTP Control Connection Latency (ms)" "kWeightedAverage"] ] \
		# [list "ftp_client_latency_data"          [list "FTP Client" "FTP Data Connection Latency (Passive Mode) (ms)" "kWeightedAverage"] ] \
		# [list "ftp_client_transactions"          [list "FTP Client" "FTP Transactions" "kSum"] ] \
		# [list "ftp_client_download_successful"   [list "FTP Client" "FTP File Downloads Successful" "kSum"] ] \
		# [list "ftp_client_download_failed"       [list "FTP Client" "FTP File Downloads Failed" "kSum"] ] \
		# [list "ftp_server_throughput"            [list "FTP Server" "FTP Data Bytes Sent" "kSum"]  \
											   # [list "FTP Server" "FTP Data Bytes Received" "kSum"]  \
											   # [list "FTP Server" "FTP Control Bytes Sent" "kSum"]  \
											   # [list "FTP Server" "FTP Control Bytes Received" "kSum"] ] \
		# [list "ftp_server_latency_data"          [list "FTP Server" "FTP Data Connection Latency (Active Mode) (ms)" "kWeightedAverage"] ] \
		# [list "smtp_client_throughput"           [list "SMTP Client" "SMTP Total Bytes Sent" "kSum"]  \
											   # [list "SMTP Client" "SMTP Total Bytes Received" "kSum"] ] \
		# [list "smtp_client_transactions"         [list "SMTP Client" "SMTP Transactions" "kSum"] ] \
		# [list "smtp_client_mail_sent"            [list "SMTP Client" "SMTP Mails Sent" "kSum"] ] \
		# [list "smtp_server_throughput"           [list "SMTP Server" "SMTP Total Bytes Sent" "kSum"]  \
											   # [list "SMTP Server" "SMTP Total Bytes Received" "kSum"] ] \
		# [list "smtp_server_session_rec"        [list "SMTP Server" "SMTP Session Requests Received" "kSum"] ] \
		# [list "smtp_server_mail_rec"           [list "SMTP Server" "SMTP Mails Received" "kSum"] ] \
		# [list "imap_client_throughput"         [list "IMAP Client" "IMAP Total Bytes Sent and Received" "kSum"] ] \
		# [list "imap_client_transactions"       [list "IMAP Client" "IMAP Transactions" "kSum"] ] \
		# [list "imap_client_mail_rec"           [list "IMAP Client" "IMAP Total Mails Received" "kSum"] ] \
		# [list "imap_server_throughput"         [list "IMAP Server" "IMAP Total Bytes Sent and Received" "kSum"] ] \
		# [list "imap_server_session_rec"        [list "IMAP Server" "IMAP Session Requests Received" "kSum"] ] \
		# [list "imap_server_mail_sent"          [list "IMAP Server" "IMAP Total Mails Sent" "kSum"] ] \
		# [list "pop3_client_throughput"         [list "POP3 Client" "POP3 Total Bytes Sent" "kSum"]  \
											 # [list "POP3 Client" "POP3 Total Bytes Received" "kSum"] ] \
		# [list "pop3_client_transactions"       [list "POP3 Client" "POP3 Transactions" "kSum"] ] \
		# [list "pop3_client_mail_rec"           [list "POP3 Client" "POP3 Mails Received" "kSum"] ] \
		# [list "pop3_server_throughput"         [list "POP3 Server" "POP3 Total Bytes Sent" "kSum"]  \
											 # [list "POP3 Server" "POP3 Total Bytes Received" "kSum"] ] \
		# [list "pop3_server_session_rec"        [list "POP3 Server" "POP3 Session Requests Received" "kSum"] ] \
		# [list "pop3_server_mail_sent"          [list "POP3 Server" "POP3 Total Mails Sent" "kSum"] ] \

	
    } 

 }
 