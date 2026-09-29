# Multiplayer-Start der Wiggles-Mod, aufgerufen von data/systeminit.tcl
#
# Liest data/mp_config.tcl. Ist dort keine Adresse eingetragen, passiert nichts und Wiggles laeuft wie
# das Grundspiel. Sonst werden die Einstellungen fuer alle Objekt-Interpreter in ::env abgelegt und das
# Spiel wartet, bis der eigene WigglesServer erreichbar ist. Der oeffnet seinen Port erst, wenn er mit
# dem Server des Mitspielers verbunden ist; so sieht der Spieler, dass die Verbindung steht.
#
# Danach meldet das Spiel "#MPREADY" und wartet auf "#MPGO". Der Server antwortet erst, wenn auch das
# Spiel des Mitspielers geladen hat (z. B. den Spielstand des Hosts), so starten beide gleichzeitig.

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
	set mp_go 0
	while {!$mp_go} {
		if {[catch {socket $mp_address $mp_port} mp_test_channel]} {
			load_info "Multiplayer ($mp_role): warte auf WigglesServer $mp_address:$mp_port (Versuch $mp_attempt)"
			incr mp_attempt
			after 1000
			continue
		}
		fconfigure $mp_test_channel -blocking 0 -translation lf
		load_info "Multiplayer ($mp_role): warte, bis der Mitspieler geladen hat"
		set mp_next_ready 0
		while {!$mp_go && ![eof $mp_test_channel]} {
			# regelmaessig wiederholen, falls eine Meldung verloren geht
			if {[clock seconds] >= $mp_next_ready} {
				if {[catch {puts $mp_test_channel "#MPREADY"; flush $mp_test_channel}]} {break}
				set mp_next_ready [expr {[clock seconds] + 2}]
			}
			while {[gets $mp_test_channel mp_line] >= 0} {
				if {[string equal $mp_line "#MPGO"]} {set mp_go 1}
			}
			after 100
		}
		catch {close $mp_test_channel}
	}
	load_info "Multiplayer ($mp_role): verbunden"
	log "Multiplayer ($mp_role): verbunden mit WigglesServer $mp_address:$mp_port"
}
