// ---------------------------------------------------------------------
// z_events.tcl
//
// Zwerg event handlers
// ---------------------------------------------------------------------


if {[in_class_def]} {

	def_event evt_timer0
	def_event evt_system_gamestart
	def_event evt_zwerg_birth
	def_event evt_zwerg_birth_forced
	def_event evt_zwerg_workannounce

	def_event evt_time_startwork
	def_event evt_time_startsparetime

	def_event evt_task_workprod
	def_event evt_task_prodattack
	def_event evt_task_workprod_prefer
	def_event evt_task_pickup
	def_event mp_evt_task_pickup
	def_event evt_task_convert
	def_event evt_task_putdown
	def_event evt_task_dropall
	def_event evt_task_buildup
	def_event evt_task_walk
	def_event mp_evt_task_walk
	def_event evt_task_harvest
	def_event evt_task_mine
	def_event evt_task_dig
	def_event evt_task_guard
	def_event evt_task_attack
	def_event evt_task_defend
	def_event evt_task_open_box
	def_event mp_evt_task_open_box
	def_event evt_task_switch
	def_event evt_task_useitem
	def_event mp_evt_task_useitem
	def_event evt_task_snapitem
	def_event evt_task_objaction
	def_event evt_task_kidnap
	def_event evt_task_bombe

	def_event evt_zwerg_attribupdate
	def_event evt_talkissue_update
	def_event evt_sparewish_update
	def_event evt_zwerg_die
	def_event evt_burnend
	def_event evt_cloakend
	def_event evt_cloakend_warning
	def_event evt_invulnerableend
	def_event evt_invulnerableend_warning

	def_event evt_autoprod_pickup
	def_event evt_autoprod_pickup_store
	def_event evt_autoprod_bringprod
	def_event evt_autoprod_transferprod
	def_event evt_autoprod_workat
	def_event evt_autoprod_harvest
	def_event evt_autoprod_mine_new
	def_event evt_autoprod_walk
	def_event evt_autoprod_pack
	def_event evt_autoprod_buildup
	def_event evt_autoprod_unpack
	def_event evt_autoprod_dig

	def_event evt_zwerg_greet
	def_event evt_zwerg_break
	def_event evt_wiggolympics
	def_event evt_paralympics

	def_event evt_change_muetze

	def_event evt_task_buildingconquer


	handle_event evt_system_gamestart {
		if {[get_cloaked this]} {
			set_rendermaterial this additiveonly
		}
	}


	handle_event evt_task_walk {
		evt_task_walk_proc
	}

	handle_event mp_evt_task_walk {
		mp_evt_task_walk_proc
	}

	handle_event evt_task_guard {
		evt_task_guard_proc
	}


	handle_event evt_burnend {
		evt_burnend_proc
	}


	// Unsichtbarkeitstrank endet
	handle_event evt_cloakend {
		call_method this set_invisibility 0 0
	}


	// Unsichtbarkeitstrank endet in wenigen Sekunden
	handle_event evt_cloakend_warning {
		if {![get_cloaked this]} {
			return
		}
		timer_event this evt_cloakend -repeat 1 -interval 1 -userid 3 -attime [expr {[gettime] + 20}]
	}


	// Unverwundbarkeitstrank endet
	handle_event evt_invulnerableend {
		call_method this set_invulnerability 0 0
	}


	// Unverwundbarkeitstrank endet in wenigen Sekunden
	handle_event evt_invulnerableend_warning {
		if {![get_invulnerable this]} {
			return
		}
		timer_event this evt_invulnerableend -repeat 1 -interval 1 -userid 4 -attime [expr {[gettime] + 5}]
	}


	handle_event evt_task_pickup {
		evt_task_pickup_proc
	}
	
	handle_event mp_evt_task_pickup {
		mp_evt_task_pickup_proc
	}

	handle_event evt_task_convert {
		evt_task_convert_proc
	}

	handle_event evt_task_useitem {
		evt_task_useitem_proc
	}

	handle_event mp_evt_task_useitem {
		mp_evt_task_useitem_proc
	}

	handle_event evt_task_objaction {
		evt_task_objaction_proc
	}

	handle_event evt_task_kidnap {
		evt_task_kidnap_proc
	}

	handle_event evt_task_bombe {
		evt_task_bombe_proc
	}

	handle_event evt_task_snapitem {
		evt_task_snapitem_proc
	}

	handle_event  evt_task_open_box {
		evt_task_open_box_proc
	}

	handle_event  mp_evt_task_open_box {
		mp_evt_task_open_box_proc
	}

	handle_event evt_task_putdown {
		evt_task_putdown_proc
	}

	handle_event evt_task_dropall {
		evt_task_dropall_proc
	}

	handle_event evt_task_buildup {
		evt_task_buildup_proc
	}


	handle_event evt_task_harvest {
		evt_task_harvest_proc
	}


	handle_event evt_task_mine {
		evt_task_mine_proc
	}


	handle_event evt_task_switch {
		evt_task_switch_proc
	}


	handle_event evt_task_dig {
		evt_task_dig_proc
	}


	handle_event evt_task_workprod {
		evt_task_workprod_proc
	}


	handle_event evt_task_prodattack {
		evt_task_prodattack_proc
	}


	handle_event evt_task_workprod_prefer {
		evt_task_workprod_prefer_proc
	}


	handle_event evt_autoprod_workat {
		evt_autoprod_workat_proc
	}


	handle_event evt_autoprod_pickup {
		evt_autoprod_pickup_proc
	}


	handle_event evt_autoprod_pickup_store {
		evt_autoprod_pickup_store_proc
	}

	handle_event evt_autoprod_pack {
		evt_autoprod_pack_proc

	}


	handle_event evt_autoprod_buildup {
		evt_autoprod_buildup_proc
	}


	handle_event evt_autoprod_unpack {
		evt_autoprod_unpack_proc
	}


	handle_event evt_autoprod_bringprod {
		evt_autoprod_bringprod_proc
	}


	handle_event evt_autoprod_transferprod {
		evt_autoprod_transferprod_proc
	}


	handle_event evt_autoprod_harvest {
		evt_autoprod_harvest_proc
	}


	handle_event evt_autoprod_mine_new {
		evt_autoprod_mine_new_proc
	}


	handle_event evt_autoprod_walk {
		evt_autoprod_walk_proc
	}


	handle_event evt_autoprod_dig {
		evt_autoprod_dig_proc
	}


	handle_event evt_task_attack {
		evt_task_attack_proc
	}


	handle_event evt_task_defend {
		evt_task_defend_proc
	}


	handle_event evt_zwerg_workannounce {
		evt_zwerg_workannounce_proc
	}


	handle_event evt_zwerg_greet {
		evt_zwerg_greet_proc
	}


	handle_event evt_zwerg_attribupdate {
		evt_zwerg_attribupdate_proc
	}

	handle_event evt_talkissue_update {
		event_talkissue_update
		// zu finden in z_spare_talk.tcl
	}

	handle_event evt_sparewish_update {
		event_sparewish_update
		// zu finden in z_spare_main.tcl
	}

	handle_event evt_zwerg_die {
		evt_zwerg_die_proc
	}


	handle_event evt_zwerg_break {
		evt_zwerg_break_proc
	}

	handle_event evt_wiggolympics {
		set mystate [state_get this]
		if {$mystate!="work_dispatch"&&$mystate!="work_auto"&&$mystate!="fight_dispatch"} {
			evt_wiggolympics_proc
		}
	}

	handle_event evt_paralympics {
		set parlympcs 1
	}

	handle_event evt_change_muetze {
		evt_change_muetze_proc
	}

	handle_event evt_task_buildingconquer {
		evt_task_buildingconquer_proc
	}

} else {


	// Laufen : vom User ausgelöst
	// -pos1	= Zielposition
	proc send_update {} {
		puts $destSocket "ZwergIstHier!"
		flush $destSocket
	}

	proc do_update {} {
	after 10 {
		update
		print "Es geht!"
		do_update
		}
	}

	proc evt_task_walk_proc {} {
	
		generate_mp_command "evt_task_walk" this "-pos1"
		
		mp_evt_task_walk_proc
	}
	
	proc mp_evt_task_walk_proc {} {
		
		global event_log current_plan
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_WALK"
		}

		set evtpos [event_get this -pos1]

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "walk \{$evtpos\}"
		if {[lindex $last_event 0]=="walk"&&[vector_dist3d $evtpos [lindex $last_event 1]]<3} {set event_repeat 1}
		set last_event $this_event

		notify_userevent

		tasklist_add this "walk_pos \{$evtpos\}"

		state_triggerfresh this task
		set_objworkicons this
		prod_gnome_state this walk "$evtpos"
	}



	// Bewachen : vom Wachhaus ausgelöst

	proc evt_task_guard_proc {} {
		global event_log current_plan

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_GUARD"
		}

		notify_autoevent

		stop_prod
		set_objworkicons this
		state_triggerfresh this task
	}



	// Zwerg hört auf zu brennen : vom Attrib-Update-Event ausgelöst

	proc evt_burnend_proc {} {
		global event_log is_burning

		if {$event_log} {
			log "[get_objname this] getting event EVT_BURNEND"
		}

		if {$is_burning == 0} {
			return
		}

		set is_burning 0
		set_particlesource this 4 0
		free_particlesource this 4
	}


	// Gegenstand aufheben : vom User ausgelöst
	// -subject1	= Obj-ID des aufzuhebenden Items

	proc evt_task_pickup_proc {} {
	
		generate_mp_command "evt_task_pickup" this "-subject1" "-pos1"
	
		mp_evt_task_pickup_proc
	}
	
	proc mp_evt_task_pickup_proc {} {
	
		global current_plan
		global last_event last_userevent_time event_repeat

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "pickup $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set res [pickup $evtitem]
		if {$res == "false"} {
			gnome_failed_work this
		}

		state_triggerfresh this task
		set_objworkicons this arrow_up [get_objclass $evtitem]
		prod_gnome_state this pickup $evtitem
	}




	proc evt_task_convert_proc {} {
		global current_plan last_event event_repeat last_userevent_time

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "convert $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set res [convert $evtitem]
		if {$res == "false"} {
			gnome_failed_work this
		}

		state_triggerfresh this task
		set_objworkicons this arrow_up [get_objclass $evtitem]
		prod_gnome_state this convert $evtitem
	}



	// ruft show_info auf einem Item auf
	// -subject1	= Obj-ID des Items

	proc evt_task_showinfo_proc {} {
		global event_log
		global last_event event_repeat

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_SHOWINFO"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "showinfo $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event

		if { ![inv_check this $evtitem] } {
			if {[get_gnomeposition $evtitem]} {
				tasklist_add this "walk_pos \{[get_pos $evtitem]\}"
			} else {
				tasklist_add this "walk_near_item $evtitem 0.6 0.2"
			}
		}

		tasklist_add this "show_info \{$evtitem\}"

		state_triggerfresh this task
		set_objworkicons this question [get_objclass $evtitem]
	}



	// Benutzten von Items (Heiltränke usw.) : vom User ausgelöst
	// -subject1 	= Obj-ID des zu benutzenden Objektes

	proc evt_task_useitem_proc {} {
	
		generate_mp_command "evt_task_useitem" this "-subject1" "-pos1"
	
		mp_evt_task_useitem_proc
	}

	proc mp_evt_task_useitem_proc {} {
	
		global event_log
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_USEITEM"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod
		state_triggerfresh this task

		set this_event "use $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		if {[inv_find_obj this $evtitem] < 0} {
			pickup $evtitem
		}

		tasklist_add this "use_item $evtitem"

		set_objworkicons this [get_objclass $evtitem]
	}


	// Benutzten von Objekten in der Welt (vor allem Questitem etc.) : vom User ausgelöst
	// -subject1 	= Obj-ID des zu benutzenden Objektes

	proc evt_task_objaction_proc {} {
		global event_log
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_OBJACTION"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod
		state_triggerfresh this task

		set this_event "objaction $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set standoffdist [call_method $evtitem get_standoff_dist]
		if {$standoffdist >= 0} {
			walk_near_item $evtitem $standoffdist
		}
		tasklist_add this "objaction_item $evtitem"

		set_objworkicons this question
		prod_gnome_state this walk [get_pos $evtitem]
	}


	proc evt_task_kidnap_proc {} {
		global event_log
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_KIDNAP"
		}

		set evtitem [event_get this -subject1]
		if {![obj_valid $evtitem]} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod
		state_triggerfresh this task

		tasklist_add this "walk_near_item $evtitem 1.2 0.4"
		tasklist_add this "rotate_towards $evtitem"
		tasklist_add this "kidnap $evtitem"

		set this_event "kidnap $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set_objworkicons this question
		prod_gnome_state this walk [get_pos $evtitem]
	}


	proc evt_task_bombe_proc {} {
		global last_event event_repeat last_userevent_time event_log

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_BOMBE"
		}

		set evtitem [event_get this -subject1]
		if {![obj_valid $evtitem]} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod
		state_triggerfresh this task

		tasklist_add this "handle_bomb $evtitem"

		set this_event "bombe $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set_objworkicons this question
		prod_gnome_state this walk [get_pos $evtitem]
	}


	// Item ist von der Plazierungsroutine an ein anderes Item gesnapt worden : vom User ausgelöst
	// (z.B. snappen Bilder an ihre Haken an der Wand)
	// -subject1 	= Obj-ID des plazierten Items
	// -subject2	= Obj-ID des Items, an das gesnapt worden ist

	proc evt_task_snapitem_proc {} {
		global event_log
		global last_event event_repeat

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_SNAPITEM"
		}

		set placeditem [event_get this -subject1]
		if {[obj_valid $placeditem] == 0} {
			return
		}
		if {[inv_find_obj this $placeditem] < 0} {
			return
		}
		set hostitem [event_get this -subject2]
		if {[obj_valid $hostitem] == 0} {
			return
		}

		// grundsätzlich nicht zulassen, wenn host schon ein Objekt hat
		if {[call_method $hostitem get_snapped_obj] != -1} {
			return
		}

//		log "EVENT: [get_objname $placeditem] snapped on [get_objname $hostitem]"

		gnome_failed_work this
		tasklist_clear this
		set_ghostlist $placeditem
		kill_old_ghosts
		stop_prod
		state_triggerfresh this task

		call_method $hostitem snapping_action [get_ref this] $placeditem

		set this_event "snap $placeditem to $hostitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set_objworkicons this [get_objclass $placeditem]
		prod_gnome_state this walk [get_pos $hostitem]
	}



	// öffnen von Schatztonnen, Kisten etc... : vom User ausgelöst
	// -subject1	= Obj-ID der Box

	proc evt_task_open_box_proc {} {
	
		generate_mp_command "evt_task_open_box" this "-subject1" "-pos1"
	
		mp_evt_task_open_box_proc
	}


	proc mp_evt_task_open_box_proc {} {
	
		global event_log current_plan
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_OPEN_BOX"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "open $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		state_triggerfresh this task
		tasklist_add this "open_box \{$evtitem\}"
		set_objworkicons this Axt [get_objclass $evtitem]
		prod_gnome_state this walk [get_pos $evtitem]
	}


	// Ablegen von Gegenständen : von User ausgelöst
	// -subject1	= Item, das abgelegt werden soll
	// -pos1		= Position, an der abgelegt werden soll (nur bei bestimmten Items)
	// -text1		= weitere Parameter

	proc evt_task_putdown_proc {} {
		global event_log current_plan last_event last_userevent_time putdownitemslist

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_PUTDOWN"
		}

		set evtitem [event_get this -subject1]
		if {![obj_valid $evtitem]} {
			return
		}
		set evtpos  [event_get this -pos1]
		if {[llength $evtpos] != 3  ||  [lindex $evtpos 0] <= 0  ||  [lindex $evtpos 2] > 15} {
			log "putdown: invalid position $evtpos"
			// Position ist ungültig
			set evtpos 0
		}

		set evttext [event_get this -text1]

		set this_event "putdown $evtitem \{$evtpos\}"
		if {$this_event==$last_event} {set event_repeat 1}

		// nur wenn letztes event kein putdown war oder Zwerg nicht mehr beim Task ist oder der Befehl "sofort" lautet

		if {[string first putdown $last_event] != 0  ||  [state_get this] != "task"  ||  $evtpos == 0} {
			gnome_failed_work this
			tasklist_clear this
			set_ghostlist $evtitem
			kill_old_ghosts
			stop_prod
			state_triggerfresh this task
			prod_gnome_state this putdown $evtitem
			set putdownitemslist ""

		} else {

			// andernfalls überprüfen wir, ob das item vielleicht schon zum Ablegen vorgesehen ist...

			if {[lsearch $putdownitemslist $evtitem] >= 0} {
				set i 0
				set s [tasklist_get this $i]
				while {$s != ""} {
					if {[string first "putdown_tasklist $evtitem" $s] == 0} {
						// wir haben das putdown - Kommando gefunden; die Aktion läßt sich also noch rückgängig machen
						tasklist_rem this $i
						set i -1
						break
					}

					incr i
					set s [tasklist_get this $i]
				}

				// putdown nicht gefunden; Ablege-Aktion läuft also schon!
				// --> alle Aktionen vor dem ersten "putdown" in der Tasklist löschen und walk-Action abbrechen
				if {$i != -1} {
					set i 0
					set s [tasklist_get this $i]
					while {$s != ""} {
						if {[string first "putdown_tasklist" $s] == 0} {
							break
						}
						tasklist_rem this $i
						set s [tasklist_get this $i]
					}
					action this wait 0.1
					state_enable this
				}
			}
		}

		set last_event $this_event
		notify_userevent

		tasklist_add this "putdown_tasklist $evtitem \{$evtpos\}"		;// mit dieser Zeile wird oben verglichen - Vorsicht bei Änderung!
		lappend putdownitemslist $evtitem
	}



	// Alle Gegenstände abwerfen : vom User ausgelöst

	proc evt_task_dropall_proc {} {
		global event_log current_plan
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_DROPALL"
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "dropall"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		state_triggerfresh this task

		set invlist [inv_list this]
		if {[llength $invlist] == 0} {
			tasklist_add this "play_anim dontknow"
		} else {
			tasklist_add this "play_anim [putdown_anim]"
			tasklist_add this "beamto_world_all"
			set_objworkicons this arrow_down
			prod_gnome_state this putdown [lindex $invlist 0]
		}
	}



	// Aufbauen einer Produktionsstätte : vom User ausgelöst
	// -subject1	= Obj-ID der aufzubauenden PS
	// -evtpos		= Position, an der aufgebaut werden soll

	proc evt_task_buildup_proc {} {
	
		generate_mp_command "evt_task_buildup" this "-subject1" "-pos1"
	
		global event_log current_plan current_workclass
		global last_event last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_BUILDUP"
		}

		set evtitem [event_get this -subject1]
		set evtpos [event_get this -pos1]
		set wpos [vector_add $evtpos {0 0 2}]

		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		set_ghostlist $evtitem
		kill_old_ghosts
		stop_prod
		state_triggerfresh this task

		set last_event ""
		notify_userevent

		if [string match "*[get_objtype $evtitem]*" "box production energy protection elevator"] {
			tasklist_add this "send_gnomes_outofplacement $evtitem"
			tasklist_add this "walk_pos \{$wpos\}"
		}

		set_objworkicons this arrow_up [get_objclass $evtitem]
		prod_change_muetze service
		prod_gnome_state this unpack $evtitem "$evtpos"

		tasklist_add this "unpack_pos_unfixed $evtitem \{$evtpos\} 0"
	}


	// Pilz fällen: von User ausgelöst
	// - subject 	= obj-ID des Pilzes

	proc evt_task_harvest_proc {} {
	
		generate_mp_command "evt_task_harvest" this "-subject1" "-pos1"

		global event_log current_workplace current_plan current_workclass
		global last_event event_repeat current_tool_class last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_HARVEST"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts

		if {$current_tool_class=="Axt"} {
			stop_prod 0
		} else {
			stop_prod
		}
		state_triggerfresh this task
		prod_change_muetze wood

		set this_event "harvest $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		harvest $evtitem

		set_objworkicons this Axt [get_objclass $evtitem]
		state_triggerfresh this work_dispatch

		prod_gnome_state this harvest $evtitem
	}


	// Teile aus einem großen Erzbroken rausschlagen : vom User ausgelöst
	// -subject1	= Obj-ID des Brockens

	proc evt_task_mine_proc {} {
		global event_log current_workplace
		global last_event event_repeat current_tool_class last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_MINE"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts

		if {$current_tool_class=="Spitzhacke"} {
			stop_prod 0
		} else {
			stop_prod
		}
		state_triggerfresh this task

		set this_event "mine $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		prod_change_muetze stone
		tasklist_add this "mine \{$evtitem\} 30"

		set_objworkicons this Spitzhacke [string map {brocken ""} [get_objclass $evtitem]]
		state_triggerfresh this work_dispatch

		prod_gnome_state this harvest $evtitem
	}



	// Schalter drücken : vom User ausgelöst
	// -subject1	: Obj-ID des Schalters

	proc evt_task_switch_proc {} {
		global event_log
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_SWITCH"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "switch $evtitem"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		tasklist_add this "switch_item \{$evtitem\}"

		state_triggerfresh this task
		set_objworkicons this [get_switcher_icon $evtitem] Schalter
	}



	// Graben : vom User ausgelöst
	// -pos1	= Grabeposition

	proc evt_task_dig_proc {} {
	
		generate_mp_command "evt_task_dig" this "-pos1"
	
		global event_log current_plan current_workplace current_digpos
		global last_event event_repeat current_tool_class last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_DIG"
		}

		set evtpos [event_get this -pos1]

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts

		if {$current_tool_class=="Spitzhacke"} {
			stop_prod 0
		} else {
			stop_prod
		}

		set this_event "dig \{$evtpos\}"
		if {[lindex $last_event 0]=="dig"&&[vector_dist $evtpos [lindex $last_event 1]]<3} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set current_plan "work"
		set current_workplace "dig"
		set current_digpos $evtpos

		tasklist_add this "dig_starttask \{$evtpos\}"
		prod_change_muetze stone

		state_triggerfresh this work_dispatch
		set_objworkicons this Spitzhacke

		prod_gnome_state this dig "$evtpos"
	}


	proc evt_task_workprod_proc {} {
		global event_log current_workplace current_plan
		global last_event
		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_WORKPROD"
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		notify_autoevent

		set current_workplace [event_get this -subject1]
		if {[get_owner $current_workplace] == [get_owner this]} {
			stop_prod
//			set current_plan "work"
			state_triggerfresh this work_idle
			set_objworkicons this Hammer [get_objclass $current_workplace]
			start_prod $current_workplace
		} else {
			log "EVENT_TASK_WORKPROD: enemy..."
		}
		set last_event ""
	}


	// Gegner angreifen : vom User ausgelöst
	// -subject1	= Gegner

	proc evt_task_prodattack_proc {} {
	
		generate_mp_command "evt_task_prodattack" this "-subject1" "-pos1"
	
		global event_log attack_item approach attack_behaviour current_plan
		global last_event event_repeat last_userevent_time

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_PRODATTACK"
		}

		set attack_item [event_get this -subject1]
		if {[obj_valid $attack_item] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set this_event "prodattack $attack_item"
		if {$this_event==$last_event} {set event_repeat 1}
		set last_event $this_event
		notify_userevent

		set current_plan "work"
		set approach 1
		set attack_behaviour "offensive"

		call_method this set_invisibility 0 0
		fight_startfight
		set_objworkicons this
		prod_gnome_state this fight $attack_item
	}


	proc evt_task_workprod_prefer_proc {} {
		global event_log current_workplace
		if {$event_log} {log "[get_objname this] getting event EVT_AUTOPROD_WORKPROD_PREFFER"}
		prod_gnome_preferred_workplace this [event_get this -subject1]
	}

	proc evt_autoprod_workat_proc {} {
	
		generate_mp_command "evt_autoprod_workat" this "-text1" "-subject1"
	
		global event_log current_workclass current_workplace current_workclass current_worktask
		global last_event

		if {$event_log} {log "[get_objname this] getting event EVT_AUTOPROD_WORKAT - Workplace = [event_get this -subject1]"}
		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_worktask "work"
		set current_workplace [event_get this -subject1]
		set current_workclass [event_get this -text1]
		if {[string compare -length 2 $current_workclass "Bp"] == 0 } {
			set wert "erfinden"
		} else {
				if {[string compare -length 8 $current_workclass "Bewachen"] == 0 } {
					set wert Bewachen
				} else {
						set wert $current_workclass
						}
			}
		switch $wert {
			"erfinden" {set_objworkicons this question [get_objclass $current_workplace]}
			"Bewachen" 	{set_objworkicons this  [get_objclass $current_workplace] $current_workclass}
			default		{set_objworkicons this [get_objclass $current_workplace] Hammer $current_workclass}
		}

		if {$current_workclass != 0} {
	//		log "EVT_AUTOPROD_WORKAT: Class = $current_workclass"
			if {$wert == "erfinden" } {
				set cat erfinden
			} else {
				set cat [get_class_category $current_workclass]
			}
				prod_change_muetze $cat
		}

		state_triggerfresh this work_auto
	}



	// Gegenstand aufheben : vom System ausgelöst
	// -subject1	= Obj-ID des Gegenstandes

	proc evt_autoprod_pickup_proc {} {
		
		generate_mp_command "evt_autoprod_pickup" this "-subject1" "-text1"
		
		global event_log current_plan current_workplace current_worktask current_workclass current_workitem
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_PICKUP"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_workplace 0
		set current_worktask "pickupitem"
		set current_workclass [event_get this -text1]
		set current_workitem $evtitem

		set_objworkicons this arrow_up $current_workclass
		state_triggerfresh this work_auto
	}



	// Gegenstand aus dem Lager aufheben : vom System ausgelöst
	// -subject1 	= Obj-ID des Gegenstandes

	proc evt_autoprod_pickup_store_proc {} {
		global event_log current_plan current_workplace current_worktask current_workclass current_workitem
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_PICKUP_STORE"
		}

		set evtitem [event_get this -subject1]
		if {[obj_valid $evtitem] == 0} {
			return
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent
		set last_event ""

		set current_plan "work"
		set current_workplace 0
		set current_worktask "pickupitem"
		set current_workclass [event_get this -text1]
		set current_workitem $evtitem

		set_objworkicons this arrow_up $current_workclass
		state_triggerfresh this work_auto
	}



	proc evt_autoprod_pack_proc {} {
	
		generate_mp_command "evt_autoprod_pack" this "-subject1" "-text1"
	
		global event_log current_plan current_workplace current_worktask current_workclass
		global last_event
		if {$event_log} {log "[get_objname this] getting event EVT_AUTOPROD_PACK"}
		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent
		set last_event ""
		set current_plan "work"
		set current_workplace [event_get this -subject1]
		set current_worktask "pack"
		set current_workclass 0
		set_objworkicons this arrow_down [get_objclass $current_workplace]
		state_triggerfresh this work_auto
	}


	proc evt_autoprod_buildup_proc {} {
		global event_log current_plan current_workplace current_worktask current_workclass last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_BUILDUP"
		}

		set eventitem [event_get this -subject1]
		if {[obj_valid $eventitem] == 0} {
			return
		}

		tasklist_clear this
//		set_ghostlist $eventitem
//		kill_old_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_workplace $eventitem
		set current_worktask "buildup"

		set current_workclass 0
		set_objworkicons this arrow_up [get_objclass $current_workplace]

//		log "CURRENT_WORKCLASS = $current_workclass"
		prod_change_muetze service

		state_triggerfresh this work_auto
	}


	proc evt_autoprod_unpack_proc {} {
	
		generate_mp_command "evt_autoprod_unpack" this "-subject1" "-text1" "-pos1"
	
		global event_log current_plan current_workplace current_worktask current_workpos current_worknum current_workclass
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_UNPACK"
		}

		set eventitem [event_get this -subject1]
		if {[obj_valid $eventitem] == 0} {
			return
		}

		tasklist_clear this
//		set_ghostlist $eventitem
//		kill_old_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_workplace $eventitem
		log "Hitpoints von $eventitem : [get_attrib $eventitem atr_Hitpoints]"
		if {[get_attrib $eventitem atr_Hitpoints] < 0.99} {
			log "Zwerg soll zur Reparatur von $eventitem  gehen"
			set current_worktask "repair"
			set_objworkicons this Hammer [get_objclass $current_workplace]
		} else {
			set current_worktask "unpack"
			set_objworkicons this arrow_up [get_objclass $current_workplace]
		}
		set current_workpos [event_get this -pos1]
		set current_worknum [event_get this -num1]
		set current_workclass 0


//     	log "CURRENT_WORKCLASS = $current_workclass"
		prod_change_muetze service

		state_triggerfresh this work_auto
	}


	proc evt_autoprod_bringprod_proc {} {
		global event_log current_plan current_workplace current_worktask current_workclass last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_BRINGPROD"
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_workplace [event_get this -subject1]
		set current_worktask "bringprod"
		set current_workclass [event_get this -text1]

		set_objworkicons this $current_workclass arrow_right [get_objclass $current_workplace]
		state_triggerfresh this work_auto
	}


	// Zwerg bringt Gegenstand aus seinem Inventar in die Produktionsstätte : vom System ausgelöst
	// -subject1	= ID Produktionsstätte
	// -subject2	= ID Gegenstand

	proc evt_autoprod_transferprod_proc {} {
	
		generate_mp_command "evt_autoprod_transferprod" this "-subject1" "-subject2" "-text1"
	
		global event_log current_plan current_workplace current_worktask current_workclass current_workitem
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_TRANSFERPROD"
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent
		set last_event ""

		set current_plan "work"
		set workitem [event_get this -subject2]
		set workplace [event_get this -subject1]

		if {![obj_valid $workitem]} {
			return
		}
		if {[inv_find_obj this $workitem] < 0} {
			gnome_failed_work this
			return
		}
		if {![obj_valid $workplace]} {
			return
		}

		set current_workitem $workitem
		set current_workplace $workplace


		set current_worktask "transferprod"
		set current_workclass [event_get this -text1]

		set_objworkicons this $current_workclass arrow_right [get_objclass $current_workplace]
		state_triggerfresh this work_auto
	}


	// Pilz fällen: von KI ausgelöst
	// - subject 	= obj-ID des Pilzes

	proc evt_autoprod_harvest_proc {} {

		generate_mp_command "evt_autoprod_harvest" this "-subject1" "-text1"

		set objref [event_get this -subject1]

		if {[obj_valid $objref] == 0 } {
			return
		}

		if {[get_objclass $objref]!="Pilz"} {
			evt_autoprod_mine_new_proc
			return
		}

		global event_log current_plan current_workplace current_worktask current_workclass
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_HARVEST"
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_worktask "harvest"
		set current_workclass [event_get this -text1]
		prod_change_muetze wood

		harvest $objref
		set_objworkicons this Axt [get_objclass $objref]

		state_triggerfresh this work_dispatch
	}


	// Stücke aus einem Erzbrocken herausschlagen : vom System ausgelöst
	// -subject1	= Obj-ID des Brockens

	proc evt_autoprod_mine_new_proc {} {
		global event_log current_plan current_workplace current_worktask current_workclass
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_MINE_NEW"
		}

		set obj_ref [event_get this -subject1]
		if {[obj_valid $obj_ref] == 0} {
			return
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent
		set last_event ""

		set current_plan "work"
		set current_workplace 0
		set current_worktask "mine"
		set current_workclass [event_get this -text1]

		tasklist_add this "mine \{$obj_ref\} 3"
		set_objworkicons this Spitzhacke [get_objclass $obj_ref]
		state_triggerfresh this work_dispatch
	}


	proc generate_mp_command {type objjj args} {
		#Send Multiplayer Data
		set destSocket $::env(SERVER_SOCKET)
		set message "set_event "
		append message [event_get $objjj -origin]
		append message " mp_"
		append message $type
		append message " -target "
		append message [event_get $objjj -origin]
		foreach va $args {
			append message " "
			append message $va
			append message " {"
			append message [event_get $objjj $va]
			append message "}"
		}
		puts $destSocket $message
		flush $destSocket
	}

	// An Position laufen : vom System ausgelöst
	// -pos1	= Zielposition

	proc evt_autoprod_walk_proc {} {

		generate_mp_command "evt_autoprod_walk" this "-pos1"

		global event_log current_plan current_workplace current_worktask current_workclass
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_WALK"
		}

		set evtpos [event_get this -pos1]
		if { $evtpos == 0 } {
			return
		}

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent
		set last_event ""

		set current_plan "work"
		set current_workplace 0
		set current_worktask "walk"
		set current_workclass 0

		tasklist_add this "walk_pos \{$evtpos\}"
		set_objworkicons this
		state_triggerfresh this work_dispatch
		
	}



	// Graben : vom System ausgelöst
	// -pos1	: Grabeposition

	proc evt_autoprod_dig_proc {} {
	
		generate_mp_command "evt_autoprod_dig" this "-pos1"
	
		global event_log current_plan current_workplace current_worktask current_digpos
		global last_event

		if {$event_log} {
			log "[get_objname this] getting event EVT_AUTOPROD_DIG"
		}

		set evtpos [event_get this -pos1]

		tasklist_clear this
//		kill_all_ghosts
		stop_prod
		notify_autoevent

		set last_event ""
		set current_plan "work"
		set current_workplace "dig"
		set current_worktask "dig"
		set current_digpos $evtpos

		prod_change_muetze stone

		state_triggerfresh this work_auto
		set_objworkicons this Spitzhacke
	}



	// Angriff : vom User oder von AI ausgelöst
	// -subject1	: Angriffsziel
	// -text1		: == "userevent", wenn vom User ausgelöst

	proc evt_task_attack_proc {} {
	
		generate_mp_command "evt_task_attack" this "-subject1" "-pos1" "-text1"
	
		global event_log attack_item approach attack_behaviour userevent current_plan
		global last_event event_repeat last_userevent_time

		if {[state_get this]=="trapped"} {return}

		if {$event_log} {
			log "[get_objname this] getting event EVT_TASK_ATTACK"
		}

		set attack_item [event_get this -subject1]
		if {[obj_valid $attack_item] == 0} {
			return
		}

		set textpar [event_get this -text1]
		set userevent 0
		if { $textpar == "userevent" } {
			set userevent 1
		}

		if {$userevent} {
			if { [state_get this] == "fight_dispatch" } {
				notify_userevent
				set newitem [event_get this -subject1]
				if { $attack_item == $newitem } {
					if { [vector_dist3d [get_pos this] [get_pos $newitem]] < 3 } {
						//Skip
						log "Skip atkevent"
						return
					}
				}
			}
			set ziel [get_objclass [event_get this -subject1]]

                      //Krake
			if {$ziel == "Krake"} {
				if {[lindex [get_best_weapon this 1] 0] == -1} {
					tasklist_add this "play_anim leftright"
					tasklist_add this "play_anim dontknow"
					return
				}
			}
		} else {
			if {[expr {[gettime] - $last_userevent_time}] < 15} {
				log "IGNORING evt_task_attack because of recent userevent"
				// weniger als 15 Sekunden seit letztem Userbefehl vergangen - automatischen Angriff unterbinden!
				return
			}
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set current_plan "work"
		set attack_item [event_get this -subject1]

		set this_event "attack $attack_item"

		if {$this_event==$last_event} {
			set event_repeat 1
		}

		set last_event $this_event

		set attack_behaviour "offensive"
		set approach 1
		call_method this set_invisibility 0 0
		fight_startfight $userevent
		prod_gnome_state this fight $attack_item
		set_objworkicons this
	}


	proc evt_task_defend_proc {} {
		global event_log current_plan attack_item attack_behaviour approach last_userevent_time

		if {$event_log} {log "[get_objname this] getting event EVT_TASK_DEFEND"}

		if {[state_get this]=="trapped"} {return}

		//if {[expr {[gettime] - $last_userevent_time}] < 15} {
			if { [get_walkresult this] == 2 && [get_last_eventtype] == "user" } {
				log "IGNORING evt_task_defend because i'm walking !!! (get_walkresult:[get_walkresult this])"
				// weniger als 15 Sekunden seit letztem Userbefehl vergangen - automatischen Angriff unterbinden!
				return
			}
		//}

		if { [state_get this] == "fight_dispatch" } {
            if { [obj_valid $attack_item] } {
            	set CT [get_class_type [get_objclass $attack_item]]
            	// Bei Zwergen und Monstern darf das attack_item nicht gewechselt werden
            	if { $CT == "gnome" } { return }
            	if { $CT == "monster" } { return }
            }
			//return
		}

		//log "[get_objname this] Defend !"

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod

		set current_plan "work"
		set attack_item [event_get this -subject1]
		set attack_behaviour "offensive"
		set approach 0
		call_method this set_invisibility 0 0
		fight_startfight
		prod_gnome_state this fight $attack_item
		set_objworkicons this
	}


	proc evt_zwerg_workannounce_proc {} {
		global current_workplace workannounce_log
		if {$current_workplace != 0} {
			prod_assignworker this $current_workplace
			if {$workannounce_log} {log "[get_objname this] confirming prod_assignworker"}
		} else {
			if {$workannounce_log} {log "[get_objname this] denying prod_assignworker"}
		}
	}



	// Zwerg grüßt einen anderen Zwerg : vom System ausgelöst
	// -subject1	= der zu grüßende Zwerg

	proc evt_zwerg_greet_proc {} {
		global event_log

		if {$event_log} {
			log "[get_objname this] getting event EVT_ZWERG_GREET"
		}

//    	set othergnome [event_get this -subject1]
		tasklist_addfront this "play_anim talkm"
	}



	// Update der Statuswerte des Zwergen : in regelmäßigen Abständen ausgelöst
	proc evt_zwerg_attribupdate_proc {} {
		global is_burning is_sleeping is_old
		global is_underwater is_wearing_divingbell is_wearing_divingbell_by_usercommand remainingair MAX_AIR_UNDERWATER out_of_water_timer
		global at_Hi at_Nu at_Al at_Mo trap_mode spt_fun_items
		global current_common_mood current_occupation
		global spt_disappointment auto_fanim_state
		global ntNutrMessage ntHitMessage ntAltMessage
		// nur fuer Timeline:
		global tll_fl_common tll_fl_hunger tll_fl_tired

		// Effekte von Lava und Schwefel

		set feet [vector_add [get_pos this] {0 -0.1 0}]
		set mouth [vector_add [get_pos this] [get_linkpos this 10]]
		if {[isunderwater $feet]} {
			if { [get_ftype [get_posx this] [expr {[get_posy this] - 0.1}]]>2} {
				add_attrib this atr_Hitpoints -0.05 			;# Lava
			}
			sparetime_react_towater
		}

		set is_underwater [isunderwater $mouth]


		if {$is_burning} {
			if {[isunderwater [vector_add [get_pos this] {0 -0.3 0}]]} {
				timer_event this evt_burnend -repeat 1 -interval 1 -userid 0 -attime [expr {[gettime] + 0.1}]
			}
		}

		if {$is_burning} {
			add_attrib this atr_Hitpoints -0.1
		}

		// Unterwassereffekte: Atemluft, Taucherglocke und Ertrinken

		if {$is_wearing_divingbell} {
			if {[inv_find this Taucherglocke] == -1} {
				set is_wearing_divingbell 0									;// möglicherweise abgelegt o.ä.
			}
		}

		if {$is_underwater} {
			if { [get_ftype [get_posx this] [expr {[get_posy this] - 0.1}]]==2} {
				add_attrib this atr_Hitpoints -0.02			;# Schwefel
			} else {
				set out_of_water_timer 0
				if {!$is_wearing_divingbell} {
					if {[inv_find this Taucherglocke] != -1} {					;// Taucherglocke automatisch anlegen
						wear_divingbell 0
					}

					if {$remainingair <= 0} {
						add_attrib this atr_Hitpoints -0.025
						set remainingair 0
					} else {
						set remainingair [expr {$remainingair -1}]
					}
				}
			}
		} else {
				set  remainingair $MAX_AIR_UNDERWATER
				if {$is_wearing_divingbell  &&  $is_wearing_divingbell_by_usercommand == 0} {
					incr out_of_water_timer
					if {$out_of_water_timer > 7} {
						remove_divingbell 0
					}
				}
		}


		if { [get_attrib this atr_Hitpoints] < 0.01 } {
			set_event this evt_zwerg_die -target this
			log "[get_objname this] send to death"
			return
		}

	// occupations: idle work spare sleep eat fun

	////Attributvariablen initialisieren
		set at_Hi [get_attrib this atr_Hitpoints]
		set at_Nu [get_attrib this atr_Nutrition]
		set at_Al [get_attrib this atr_Alertness]
		set at_Mo [get_attrib this atr_Mood]
		set sub_Hi 0 ; set sub_Nu 0 ; set sub_Al 0 ; set sub_Mo 0

	////Gesichtsanimation anpassen
		if {$at_Mo<0.4||$at_Nu<0.2||$at_Al<0.1||$at_Hi<0.5} {
			set current_common_mood "bad"
		} elseif {$at_Mo<0.8||$at_Nu<0.4||$at_Al<0.2||$at_Hi<0.8} {
			set current_common_mood "normal"
		} else {
			set current_common_mood "good"
		}
		if {$is_sleeping} {
			append current_common_mood "_sleep"
		} elseif {$at_Al<0.3} {
			append current_common_mood "_tired"
		} elseif {$at_Al<0.6} {
			append current_common_mood "_dizzy"
		} elseif {$at_Al<0.8} {
			append current_common_mood "_normal"
		} else {
			append current_common_mood "_awake"
		}
		if {$auto_fanim_state} {
			set_fanim_feeling $current_common_mood
			random_fanim_sequence
		}

	////Lebenspunkt- und Stimmungsverluste durch Hunger und Müdigkeit
		if {$at_Nu<0.2} {
			set sub_Hi [expr {($at_Nu - 0.2) * 0.004}]
		}
		if {$at_Al<0.1} {
			fincr sub_Hi [expr {($at_Al - 0.1) * 0.002}]
		}
		if {$at_Nu>0.2&&$at_Al>0.1} {
			set sub_Hi [expr {([hmin $at_Nu 0.6] - 0.2) * 0.0006 + ([hmin $at_Al 0.5] - 0.1) * 0.0004}]
		}
		if { $at_Nu < 0.4 } {
			set sub_Mo [expr {$sub_Mo + ([hmax $at_Nu 0.2] - 0.4) * 0.0006} ]
			fincr tll_fl_hunger [expr {([hmax $at_Nu 0.2] - 0.4) * -0.0006} ]
		}
		if { $at_Al < 0.4 } {
			set sub_Mo [expr {$sub_Mo + ([hmax $at_Al 0.2] - 0.4) * 0.0003} ]
			fincr tll_fl_tired [expr {([hmax $at_Al 0.2] - 0.4) * -0.0003} ]
		}

	////Altersschwäche
		set current_age [calc_age]
		if {$current_age>24*1800-300} {
			if {$ntAltMessage == -1} {
				set id [newsticker new [get_owner this] -text "[get_objname this] [lmsg istsehralt]" -time [expr {3 * 60}]]
				set ref [get_ref this]
				newsticker change $id -click "newsticker delete $id;
										if {\[obj_valid $ref\]} {
												if {\[get_objclass $ref\] == \"Zwerg\"  ||  \[get_objclass $ref\] == \"Baby\"} {
												set x \[get_posx $ref\];
												set y \[get_posy $ref\];
												set_view \$x \[expr \$y -1\] 0 -0.35 0
											}
										}"
                set ntAltMessage $id
			}
		}
		if {$current_age>24*1800} {
			fincr sub_Hi -0.01
			set is_old 3
		} elseif {$current_age>22*1800} {
			fincr sub_Al -0.0001
			fincr sub_Nu  0.0001
		}

	////allgemeine Verluste, Unterscheidung work - idle
		if { $current_occupation == "work" } {
			fincr sub_Al -0.00022
			fincr sub_Nu -0.00025
			fincr sub_Mo -0.00012
			fincr tll_fl_common 0.0002
		} else {
			fincr sub_Al -0.00017
			fincr sub_Nu -0.000195
			fincr sub_Mo -0.00004
			fincr tll_fl_common 0.00005
		}

	//	if { [string first [state_get this] "reprodsparetime_dispatch"]==-1} {
			fincr sub_Mo $spt_disappointment
			fun_log " losing $spt_disappointment secondly"
	//	}

	////jetzt aktualisieren
	//	log "[get_objname this]: $current_occupation -> $sub_Hi $sub_Nu $sub_Al $sub_Mo $sub_Fi"
	if {$trap_mode==0} {
		if { $spt_fun_items } { set sub_Mo [expr {$sub_Mo*0.5}] }
		if { ![im_a_human] } {
			set sub_Nu [expr {$sub_Nu*0.5}]
			set sub_Al [expr {$sub_Al*0.5}]
			set sub_Mo [expr {$sub_Mo*0.5}]
		}
		add_attrib this atr_Hitpoints $sub_Hi
		add_attrib this atr_Nutrition $sub_Nu
		add_attrib this atr_Alertness $sub_Al
		add_attrib this atr_Mood $sub_Mo
	}

	// Meldungen im Newsticker anzeigen
	if {[net localid] == [get_owner this]} {
		if {[get_attrib this atr_Nutrition] < 0.2} {
			//Zwerg ist sehr hungrig
			//falls NutritionMeldung noch nicht angezeigt wurde -> ausgeben
				if {$ntNutrMessage == -1} {
					//meldung ausgeben
					set id [newsticker new [get_owner this] -text "[get_objname this] [lmsg istsehrhungrig]" -time [expr {3 * 60}]]
					set ref [get_ref this]
					newsticker change $id -click "newsticker delete $id;
											if {\[obj_valid $ref\]} {
													if {\[get_objclass $ref\] == \"Zwerg\"  ||  \[get_objclass $ref\] == \"Baby\"} {
													//call_method $ref set_NTmessage nutrition -1
													set x \[get_posx $ref\];
													set y \[get_posy $ref\];
													set_view \$x \[expr \$y -1\] 0 -0.35 0
												}
											}"

					set ntNutrMessage $id
				}
			} else {
				//falls die NutritionMeldung angezeigt wurde, lösche sie
				if {$ntNutrMessage != -1} {newsticker delete $ntNutrMessage; set ntNutrMessage -1}
			}
		}

		///////////////
		if {[net localid] == [get_owner this]} {
			if {[get_attrib this atr_Hitpoints] < 0.5} {
				//Zwerg ist fast tot
				//falls HitpointsMeldung noch nicht angezeigt wurde -> ausgeben
				if {$ntHitMessage == -1} {
					//meldung ausgeben
					set id [newsticker new [get_owner this] -text "[get_objname this] [lmsg istfasttot]" -time [expr {3 * 60}]]
					set ref [get_ref this]
					newsticker change $id -click "newsticker delete $id;
											if {\[obj_valid $ref\]} {
												if {\[get_objclass $ref\] == \"Zwerg\"  ||  \[get_objclass $ref\] == \"Baby\"} {
													//call_method $ref set_NTmessage hitpoints -1
													set x \[get_posx $ref\];
													set y \[get_posy $ref\];
													set_view \$x \[expr \$y -1\] 0 -0.35 0
												}
											}"
					set ntHitMessage $id
				}
			} else {
				//falls die HitpointsMeldung angezeigt wurde, lösche sie
				if {$ntHitMessage != -1} {newsticker delete $ntHitMessage; set ntHitMessage -1}
			}
		}
		///////////////////////

	////Warnicons setzen
		if { $at_Nu+$sub_Nu<0.3 } {set_objicon this -1 1 6 5}
		if { $at_Al+$sub_Al<0.3 } {set_objicon this -1 1 5 5}
		if { $at_Mo+$sub_Mo<0.3 } {set_objicon this -1 1 7 5}
	}



	// Zwerg stirbt : vom Attrib-Update-Event ausgelöst

	proc evt_zwerg_die_proc {} {
		global birthtime is_dying gnome_gender is_underwater clan myhairs myglasses
		global ntHitMessage ntNutrMessage is_old ntAltMessage

		if { $is_dying && $is_dying < 10 } {
			incr is_dying
			return
		}

		set is_dying 1
		set pos [get_pos this]
		set age [expr {[gettime]-$birthtime}]

		hide_tools
		kill_all_ghosts
		stop_prod
		state_trigger this
		state_disable this
		state_trigger this

		foreach atr "atr_Hitpoints atr_Nutrition atr_Alertness atr_Mood [get_expattrib]" {
			log "Gnome dies: $atr: [get_attrib this $atr]"
		}
		log "Gnome dies: tasklist [tasklist_list this]"
		log "Gnome dies: state [state_get this] ([state_getenablecnt this])"
		log "Gnome dies: worktime [get_worktime this]"


		set attribs [list]
		foreach attribut [get_expattrib] {
			lappend attribs [get_attrib this $attribut]
		}

		// Voodoohaare loeschen

		if {$myhairs} {catch {del $myhairs}}

		// Brian_Brille loeschen

		if {$myglasses} {catch {del $myglasses}}

		// Mütze zurücklassen, für mögliche Wiederbelebung

		set cap [new Zipfelmuetze]
		call_method $cap set_parameters $gnome_gender [get_objname this] [get_worktime this] [get_attrib this atr_ExpMax] $attribs $age $clan
        set gnome_dead_on_wall 0
        if {[get_gnomeposition this]} {
        	set gnome_dead_on_wall 1
        }
		// Todesanzeige im Newsticker aufgeben

		if {[net localid] == [get_owner this]} {
			if {$ntHitMessage != -1} {newsticker delete $ntHitMessage}
			if {$ntNutrMessage != -1} {newsticker delete $ntNutrMessage}
			if {$ntAltMessage != -1} {newsticker delete $ntAltMessage}
			set msg istgestorben
			if {$is_old == 3} {set msg istvonaltergestorben}
			set id [newsticker new [get_owner this] -text "[get_objname this] [lmsg $msg]" -time [expr {3 * 60}]]
			newsticker change $id -click "newsticker delete $id; set_view [get_posx this] [expr {[get_posy this] -1}] 0 -0.35 0"
		}

		// Aggressivity veraendern

		if {[obj_query this -type {monster gnome} -owner enemy -range 8 -limit 1]} {
			if {[im_in_campaign]} {
				time_line_log ""
				time_line_log "--------[clock format [clock seconds] -format "%d-%m-%y %X"]---------"
				set vorher [get_owner_attrib 0 PlayerAggressivity]
				if {[im_a_human]} {
					add_owner_attrib 0 PlayerAggressivity -0.01
					set nachher [get_owner_attrib 0 PlayerAggressivity]
					time_line_log "Eigener Zwerg [get_objname this] gestorben: -0.01 $vorher -> $nachher"
				} else {
					add_owner_attrib 0 PlayerAggressivity 0.005
					set nachher [get_owner_attrib 0 PlayerAggressivity]
					time_line_log "Feindlichen Zwerg [get_objname this] getötet: +0.005 $vorher -> $nachher"
				}
			}
		}

		// schöne Todesanimation abspielen

		if {[get_diedinfight this] || [state_get this] == "trapped" } {		;// im Kampf gestorben - Animation läuft bereits
			log "Gnome died in fight."
			action this wait 3.0 "
				destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall}
			" " destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall} "
		} elseif {[get_gnomeposition this] == 1} {
			action this anim diewall "
					destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall}
				" " destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}];if {$gnome_dead_on_wall} {call_method $cap from_wall} "
		} elseif {$is_underwater == 1} {				;// Zwerg ist offenbar ertrunken
			log "Gnome drowned."
			if {[get_gnomeposition this] == 1} {
				action this anim swimwalldrown "
					destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall}
				" " destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall} "
			} else {
				action this anim swimdrown "
					destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall}
				" " destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall} "
			}

		} else {										;// sonst mehr oder minder natürlicher Tod
			log "Gnome died in a natural way."
			action this anim die "
				destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall}
			" " destroy; set_pos $cap [vector_add $pos {0.0 -0.2 0.0}]; if {$gnome_dead_on_wall} {call_method $cap from_wall} "
		}
		//Mütze soll runterfallen
		//if {$gnome_dead_on_wall} {call_method $cap from_wall}
	}


	// Zwerg hört auf, mit was immer er eben getan hat

	proc evt_zwerg_break_proc {} {
		global event_log

		if {$event_log} {
			log "[get_objname this] getting event EVT_ZWERG_BREAK"
		}

		gnome_failed_work this
		tasklist_clear this
		hide_tools
		kill_all_ghosts
		stop_prod

		tasklist_add this "log \"[get_objname this] breaked by evt_zwerg_break\""
		state_triggerfresh this task
	}

	proc evt_wiggolympics_proc {} {
		global event_log gnome_gender

		if {$event_log} {
			log "[get_objname this] getting event EVT_WIGGOLYMPICS"
		}

		gnome_failed_work this
		tasklist_clear this
		hide_tools
		kill_all_ghosts
		stop_prod

		set points [event_get this -num1]

		if {$points!=10.0} {
			set varia [irandom 3]
			set points [expr {(int($points*2)+$varia-1)*0.5}]
			set points [hmax 6.0 [hmin $points 9.5]]
		}
		set points [string range [string map {"." ""} $points] 0 1]
		if {[string length $points]==1} {append points 0}
		log "[get_objname this] gives GRS-points: $points"

		if {$gnome_gender=="female"} {
			tasklist_add this "rotate_toangle 5.0"
		} else {
			tasklist_add this "rotate_tofront"
		}
		tasklist_add this "change_tool Wigglepoints 0 0"
		tasklist_add this "call_method \$current_tool_item set_points $points;play_anim swordupstart"
		tasklist_add this "play_anim sworduploop"
		tasklist_add this "play_anim sworduploop"
		tasklist_add this "play_anim sworduploop"
		tasklist_add this "play_anim swordupend"
		tasklist_add this "change_tool 0 0 0"

		state_triggerfresh this task

	}

	proc evt_change_muetze_proc {} {
	
		generate_mp_command "evt_change_muetze" this "-text1"
		
		global event_log
		//Parameter: objref der Produktionstätte, classe des hergestelltes Produktes

		tasklist_clear this
		kill_all_ghosts
		stop_prod
		hide_tools


		//------Hauptteil--(erwartet current_workclassals text1)------
		set category [event_get this -text1]
		if {$event_log} {log "EVT_CHANGE_MUETZE: Category = $category"}
		if {$category != 0} {
			if {[string compare -length 2 $category "Bp"] == 0 } {
				set category "erfinden"
			} else {
				switch $category {
					"dig" {}
					"transport" {}
					"pack" {}
					"unpack" {}
					"harvest" {}
					default {set category [get_class_category $category]}
				}
			}
			prod_change_muetze $category
		}
		state_triggerfresh this task
	}

	//  Gebäude übernehmen --> vom User ausgelöst
	//	subject1 - produktionstättenreferenz

	proc evt_task_buildingconquer_proc {} {
		global event_log current_plan current_workplace current_worktask current_workpos current_worknum current_workclass
		global last_event

		set s1 [event_get this -subject1]
		if {[obj_valid $s1] == 0} {
			return
		}

		gnome_failed_work this
		tasklist_clear this
		kill_all_ghosts
		stop_prod
		hide_tools
		notify_userevent

		set current_plan "work"
		conquer $s1

        set_objworkicons this
		prod_gnome_state this fight $s1
		state_triggerfresh this work_dispatch
	}


}

