set mode "host"
set server_port 5592

#loadLEG lib/mkThreads12/mkThreads12.dll #192.168.178.25

#Server auf $server_port erstellen
#set server_thread [thread create]
#thread eval $server_thread { 
socket -server incoming $server_port 

#sleep 20000

#Custom Tcl Command: Update alle 200ms -> neue Commands vom Server Socket
updateLEG

call ./data/connect.tcl

proc incoming {sock addr port} {
		fileevent $sock readable [list Echo $sock]
	}
	
proc Echo {sock} {       
		if {[eof $sock] || [catch {gets $sock line}]} {
		} else {
		print $line
		set rv [eval $line]
		}
	}