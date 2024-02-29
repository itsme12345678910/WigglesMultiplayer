set mode "host"
set server_port 5592
set client_address 127.0.0.1 
set client_port 5591

#loadLEG lib/mkThreads12/mkThreads12.dll #192.168.178.25

#Server auf $server_port erstellen
#set server_thread [thread create]
#thread eval $server_thread { 
socket -server incoming $server_port 

#Custom Tcl Command: Update alle 200ms -> neue Commands vom Server Socket
updateLEG

#Mit dem Server auf der Gegenseite verbinden
# 192.168.178.25 5592
set destSocket [socket $client_address $client_port]   
set ::env(SERVER_SOCKET) $destSocket

proc incoming {sock addr port} {
		fileevent $sock readable [list Echo $sock]
	}
	
proc Echo {sock} {       
		if {[eof $sock] || [catch {gets $sock line}]} {
		close $sock
		print "Close $echo(addr,$sock)"
		unset echo(addr,$sock)
		} else {
		print $line
		set rv [eval $line]
		#Send Mulitplayer Data
		set destSocket $::env(SERVER_SOCKET)
		puts $destSocket $rv
		flush $destSocket
		update
		}
	}