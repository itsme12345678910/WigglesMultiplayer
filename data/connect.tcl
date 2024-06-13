set client_address 192.168.0.53

set client_port 5592

#Mit dem Server auf der Gegenseite verbinden
# 192.168.178.25 5592
set destSocket [socket $client_address $client_port]   
set ::env(SERVER_SOCKET) $destSocket