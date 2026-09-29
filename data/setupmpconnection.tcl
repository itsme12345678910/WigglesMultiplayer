# Multiplayer-Start der Wiggles-Mod, aufgerufen von data/systeminit.tcl
#
# Liest data/mp_config.tcl. Ist dort keine Adresse eingetragen, passiert nichts und Wiggles laeuft wie
# das Grundspiel. Sonst werden die Einstellungen fuer alle Objekt-Interpreter in ::env abgelegt und das
# Spiel wartet, bis der eigene WigglesServer erreichbar ist. Der oeffnet seinen Port erst, wenn er mit
# dem Server des Mitspielers verbunden ist; so sieht der Spieler, dass die Verbindung steht.

call ./data/mp_config.tcl

if {$mp_address != ""} {
	set mp_role [string tolower $mp_role]
	if {$mp_role != "host" && $mp_role != "client"} {
		log "Multiplayer: unbekannte Rolle '$mp_role' in data/mp_config.tcl, verwende host"
		set mp_role host
	}
	set ::env(MP_ROLE) $mp_role
	set ::env(MP_ADDRESS) $mp_address
	set ::env(MP_PORT) $mp_port

	set mp_attempt 1
	while {[catch {socket $mp_address $mp_port} mp_test_channel]} {
		load_info "Multiplayer ($mp_role): warte auf WigglesServer $mp_address:$mp_port (Versuch $mp_attempt)"
		incr mp_attempt
		after 1000
	}
	close $mp_test_channel
	load_info "Multiplayer ($mp_role): verbunden"
	log "Multiplayer ($mp_role): verbunden mit WigglesServer $mp_address:$mp_port"
}
