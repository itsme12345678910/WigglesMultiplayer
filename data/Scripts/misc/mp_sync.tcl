# Multiplayer-Hilfen der Wiggles-Mod fuer Klassen-Scripts
#
# Wiggles gibt jedem Objekt einen eigenen Tcl-Interpreter. Diese Datei wird deshalb wie utility.tcl in
# jeder Klasse geladen, die sie braucht, und zwar im Klassenteil (Methode mp_push) und in obj_init
# (Prozeduren): call scripts/misc/mp_sync.tcl
#
# Rolle (aus data/mp_config.tcl, beim Start in ::env(MP_ROLE) abgelegt; env gilt fuer alle Interpreter):
#   ""      kein Multiplayer konfiguriert: alles verhaelt sich exakt wie im Grundspiel
#   host    wuerfelt Zufallsbewegungen selbst und schickt jedes Ergebnis an dasselbe Objekt beim Client
#   client  wuerfelt nie selbst, sondern nimmt den naechsten Wert des Hosts. Ist keiner angekommen,
#           gilt ein neutraler Standardwert, dann bewegt sich eben nichts zufaellig.
#
# Eine Zufallsstelle wird so umgestellt:  [irandom 14]  ->  [mp_irandom idleanim 0 14]
# (Schluessel der Stelle, Standardwert fuer den Client, Originalargumente von irandom)

if {[in_class_def]} {

	# Client: Zufallswert des Hosts fuer dieses Objekt entgegennehmen
	method mp_push {mp_key mp_value} {
		mp_queue_push $mp_key $mp_value
	}

} else {

	proc mp_role {} {
		if {[info exists ::env(MP_ROLE)]} {return $::env(MP_ROLE)}
		return ""
	}

	proc mp_active {} {
		expr {[mp_role] != ""}
	}

	proc mp_is_host {} {
		string equal [mp_role] host
	}

	proc mp_is_client {} {
		string equal [mp_role] client
	}

	# Schickt einen Tcl-Befehl ueber den WigglesServer an das andere Spiel. Dort laeuft er in catch, damit
	# ein fehlschlagender Befehl (z. B. fuer ein dort fehlendes Objekt) die folgenden nicht verhindert.
	# Kanaele gehoeren in Tcl dem Interpreter, der sie geoeffnet hat, deshalb haelt jeder
	# Objekt-Interpreter seine eigene Verbindung. Wirft nie einen Fehler; ohne Multiplayer passiert nichts.
	proc mp_send {command} {
		global mp_channel
		if {![mp_active]} {return}
		set message [list catch [string map {"\n" " " "\r" " "} $command]]
		if {[info exists mp_channel] && ![catch {puts $mp_channel $message; flush $mp_channel}]} {
			return
		}
		if {[info exists mp_channel]} {
			catch {close $mp_channel}
			unset mp_channel
		}
		if {[mp_connect]} {
			catch {puts $mp_channel $message; flush $mp_channel}
		}
	}

	# Oeffnet die Verbindung dieses Interpreters. Schlaegt das fehl, versucht es fuer alle Objekte erst
	# nach 10 Sekunden erneut, weil ein abgelehnter Verbindungsversuch das Spiel unter Windows rund eine
	# Sekunde anhaelt.
	proc mp_connect {} {
		global mp_channel
		if {[info exists ::env(MP_RETRY_AT)] && [clock seconds] < $::env(MP_RETRY_AT)} {return 0}
		if {[catch {socket $::env(MP_ADDRESS) $::env(MP_PORT)} channel]} {
			set ::env(MP_RETRY_AT) [expr {[clock seconds] + 10}]
			return 0
		}
		set mp_channel $channel
		return 1
	}

	# Host: Zufallswert einer Stelle an dasselbe Objekt beim Client schicken
	proc mp_give {key value} {
		if {[mp_is_host]} {
			mp_send [list call_method [get_ref this] mp_push $key $value]
		}
	}

	# Client: Werte des Hosts je Stelle sammeln. Mehr als 3 werden nicht gebraucht; laeuft der Client
	# hinterher, verfallen die aeltesten.
	proc mp_queue_push {key value} {
		global mp_queue
		lappend mp_queue($key) $value
		if {[llength $mp_queue($key)] > 3} {
			set mp_queue($key) [lrange $mp_queue($key) end-2 end]
		}
	}

	# Client: naechsten Wert des Hosts fuer eine Stelle holen, sonst default
	proc mp_take {key default} {
		global mp_queue
		if {![info exists mp_queue($key)] || [llength $mp_queue($key)] == 0} {return $default}
		set value [lindex $mp_queue($key) 0]
		set mp_queue($key) [lrange $mp_queue($key) 1 end]
		return $value
	}

	# Wie mp_take fuer eine Position {x y z}; liefert "" wenn keine gueltige da ist
	proc mp_take_pos {key} {
		set pos [mp_take $key ""]
		if {[llength $pos] != 3} {return ""}
		foreach coord $pos {
			if {![string is double -strict $coord]} {return ""}
		}
		return $pos
	}

	# Wie irandom, im Multiplayer aber nur vom Host gewuerfelt.
	# Werte ausserhalb des beim Client gueltigen Bereichs (z. B. andere Listenlaenge) werden verworfen.
	proc mp_irandom {key default args} {
		if {![mp_is_client]} {
			set value [eval irandom $args]
			mp_give $key $value
			return $value
		}
		set value [mp_take $key $default]
		if {![string is integer -strict $value]} {return $default}
		if {[llength $args] == 1} {
			if {$value < 0 || $value >= [lindex $args 0]} {return $default}
		} elseif {$value < [lindex $args 0] || $value > [lindex $args 1]} {
			return $default
		}
		return $value
	}

	# Wie [lindex $list [irandom [llength $list]]], im Multiplayer nur vom Host gewaehlt. Uebertragen wird
	# das Element selbst, damit es auch passt, wenn die Liste beim Client anders aussieht.
	proc mp_pick {key list default} {
		if {![mp_is_client]} {
			set value [lindex $list [irandom [llength $list]]]
			mp_give $key $value
			return $value
		}
		return [mp_take $key $default]
	}

	# Wie random (Kommazahl), im Multiplayer nur vom Host gewuerfelt
	proc mp_random {key default args} {
		if {![mp_is_client]} {
			set value [eval random $args]
			mp_give $key $value
			return $value
		}
		set value [mp_take $key $default]
		switch [llength $args] {
			0 {set low 0.0; set high 1.0}
			1 {set low 0.0; set high [lindex $args 0]}
			default {set low [lindex $args 0]; set high [lindex $args 1]}
		}
		if {![string is double -strict $value] || $value < $low || $value > $high} {return $default}
		return $value
	}

	# Wie expr rand(), im Multiplayer nur vom Host gewuerfelt
	proc mp_rand {key default} {
		if {![mp_is_client]} {
			set value [expr {rand()}]
			mp_give $key $value
			return $value
		}
		set value [mp_take $key $default]
		if {![string is double -strict $value] || $value < 0.0 || $value > 1.0} {return $default}
		return $value
	}

	# Allgemeine Zufallsentscheidung: script wird beim Host bzw. im Einzelspieler unveraendert im Aufrufer
	# ausgefuehrt und liefert den Wert; der Client bekommt den Wert des Hosts oder default
	proc mp_choose {key default script} {
		if {[mp_is_client]} {return [mp_take $key $default]}
		set value [uplevel 1 $script]
		mp_give $key $value
		return $value
	}

	# Host: zufaelliger erreichbarer Zielpunkt im Umkreis radius
	proc mp_random_place {radius} {
		get_place -center [get_pos this] -circle $radius -mindist 0.7 -random $radius -walldist 1
	}

	# Zielpunkt fuer eine Zufallsbewegung im Multiplayer. Ersetzt Laufaktionen mit "-randompath", deren Weg
	# die Engine intern wuerfelt und der sich deshalb nicht uebertragen laesst. Der Host waehlt den Punkt und
	# schickt ihn mit, der Client nimmt den des Hosts. Liefert "" wenn es keinen gibt.
	proc mp_random_target {key radius} {
		if {[mp_is_client]} {return [mp_take_pos $key]}
		set place [mp_random_place $radius]
		if {[lindex $place 0] < 1} {return ""}
		mp_give $key $place
		return $place
	}
}
