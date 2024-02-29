def_class Zwerg none gnome 0 {reproduces lives moves} {
	call scripts/misc/animclassinit.tcl	// anim members
	call scripts/classes/zwerg/z_anims.tcl	// class anims
	call scripts/misc/obj_attribs.tcl
	call scripts/misc/genattribs.tcl   ;# define attribs for all characters

	class_fightdist 1.0

	// states are:
	// idle - idle
	// task - idependent task
	// work_dispatch - workplace assigned
	// work_idle  - workplace assigned, no task
	// work_active - workplace assigend, executing task
	// work_breakable - workplace assigned, executing breakable task
	// sparetime	- sparetime

	obj_init {

		set info_string ""
		set logon 0
		set state_log 0
		set state_shell 0
		set event_log 0
		set workannounce_log 0
		set was_baby 0
		set is_campaign 0
		set is_tutorial 0
		set is_human 1
		set is_counterwiggle 0
		set myref [get_ref this]
		set gnome_initialized 0
		set gnome_gender "unset"
		set birthtime [expr {[gettime]-1200}]
		set_attrib this GnomeAge $birthtime
		set is_old 0
		set myhairs 0
		set myglasses 0
		set haircolor 0
		set hatcolor -1
		set info_string {}
		set clothes_changed 0

		set current_lock_obj 0
		set current_left_obj 0
		set current_workplace 0
		set last_workplace 0
		set current_worknum 0
		set current_worklist [list]
		set current_workdelay 0
		set current_worktask 0
		set current_workclass 0

		set current_tool_class 0
		set current_tool_item 0
		set current_lefttool_class 0
		set current_lefttool_item 0

		set current_weapon_out 0
		set current_weapon_item 0
		set current_shield_out 0
		set current_shield_item 0
		set died_in_fight 0							;# Zwerg ist im Kampf gestorben
		set is_dying 0								;# Zwerg stirbt
		set is_burning 0							;# Zwerg brennt
		set is_underwater 0							;# Zwerg ist unter Wasser
		set is_wearing_divingbell 0					;# Zwerg trägt eine Taucherglocke
		set is_wearing_divingbell_by_usercommand 0	;# Zwerg trägt Taucherglocke auf Befehl (= kein autom. Absetzen!)
		set out_of_water_timer 0					;# Zwerg ist soviel Zeit (events...) aus dem Wasser raus
		set MAX_AIR_UNDERWATER 15					;# Konstante: Luft für x Sekunden bevor Lebensabzug
		set remainingair $MAX_AIR_UNDERWATER		;# tatsächlich übrige Atemluft
		set love_potion_taken 0						;# Zwerg hat einen Liebestrank genommen
		set fertility_potion_taken 0				;# Zwerg hat einen Fruchtbarkeitstrank genommen
		set trap_mode 0								;# Zwerg ist in Falle
		set medusa_stoned 0							;# Zwerg ist versteinert

		set beam_backto 0

		set current_plan "work"
		set current_time_plan "sparetime"

		set current_occupation "idle"
		set current_wish_occupation "idle"

		set attack_behaviour "none"

		set idletimeout 0
		set prod_failurecount 0
		set current_digpos ""
		set current_digpose ""

		set last_disturb [gettime]
		set event_repeat 0
		set last_event ""
		set last_userevent_time 0
		set objghostlist 	 ""						;# Alphaobjekte, die gültig sind und nicht gelöscht werden sollen
		set putdownitemslist ""						;# wird im Putdown-Event gebraucht
		set idle_action_list ""
		set dig_versuche 4

		set logoff_code ""

    	set at_Hi 1.0
    	set at_Nu 1.0
    	set at_Al 1.0
    	set at_Mo 1.0

		set current_muetze_name 0
		set current_muetze_ref 0
		set muetzen_counter_start 7
		set muetzen_counter $muetzen_counter_start

		set clothing xx
        set ntNutrMessage -1 ;#newsTicker NutritionMeldung
        set ntHitMessage -1  ;#newsTicker HitpointsMeldung
        set ntAltMessage -1

		// Idle anims für Sequenzen (Statistenrollen)
		set seq_idle_anims [list]
		lappend seq_idle_anims {10 {stand_anim_a}}
		lappend seq_idle_anims {10 {stand_anim_b}}
		lappend seq_idle_anims {10 {stand_anim_c}}
		lappend seq_idle_anims {1 {spaehen}}
		lappend seq_idle_anims {1 {zeigen_rechts}}
		lappend seq_idle_anims {1 {strippe_ziehen}}
		// lappend seq_idle_anims {1 {handstand_start handstand_loop handstand_loop handstand_end}}
		lappend seq_idle_anims {1 {raeuspern}}
		lappend seq_idle_anims {3 {wippen}}
		lappend seq_idle_anims {1 {verlegen}}
		lappend seq_idle_anims {5 {warten}}
		lappend seq_idle_anims {3 {kratzen}}
		lappend seq_idle_anims {1 {kopf_kratzen}}
		lappend seq_idle_anims {2 {aufatmen}}
		lappend seq_idle_anims {1 {popo_waermen}}
		lappend seq_idle_anims {2 {hungrig}}
		lappend seq_idle_anims {w1 {kletterstand_anim}}
		lappend seq_idle_anims {3 {blicken_rechts_links}}

		// lappend seq_idle_anims {1 {kletterstand_anim}}
		call data/scripts/misc/seq_idle.tcl

		set tttsection_tocall "Zwerg"
		call scripts/misc/techtreetunes.tcl
		set sttsection_tocall "Zwerg"
		call scripts/misc/sparetimetunes.tcl

		auto_choose_workingtime this
		set_weapon_class this 0
		set_shield_class this 0

		set_texturevariation this [hf2i [random 4]] 0

		set_anim this mann.standard 0 $ANIM_LOOP					;// set standard anim
		set_objinfo . EinZwerg
		set_fogofwar this 14 8										;// uncover fog of war area
		set_autolight this 1
		set_collision this 1										;// turn on light at gnome position

		set_attrib this carrycap 1
		set_attrib this hitpoints 1

		call scripts/misc/genericfight.tcl							;// must be before z_procs (contains virtual functions)
		call scripts/classes/zwerg/z_events.tcl
		call scripts/classes/zwerg/z_procs.tcl		 				;// misc procs
		call scripts/classes/zwerg/z_dignwalk.tcl
		call scripts/classes/zwerg/z_faceanim.tcl
		call scripts/classes/zwerg/z_work_states.tcl
		call scripts/classes/zwerg/z_work_common.tcl
		call scripts/classes/zwerg/z_work_prod.tcl
		call scripts/classes/zwerg/z_work_prodfill.tcl
		call scripts/classes/zwerg/z_spare_main.tcl
		call scripts/classes/zwerg/z_spare_procs.tcl
		call scripts/classes/zwerg/z_spare_fun.tcl
		call scripts/classes/zwerg/z_spare_talk.tcl
		call scripts/classes/zwerg/z_spare_reprod.tcl
		call scripts/classes/zwerg/z_work_strike.tcl
		call scripts/classes/items/calls/takeitems.tcl

		state_reset this
		state_trigger this idle
		state_enable this

		timer_event this evt_timer0 -repeat 1 -interval 1 -userid 1 -attime 3
		timer_event this evt_zwerg_attribupdate -repeat -1 -interval 1 -userid 2
		timer_event this evt_zwerg_workannounce -repeat -1 -interval 1 -userid 3
		timer_event this evt_talkissue_update -repeat -1 -interval 5 -userid 4 -attime [expr {[gettime]+2}]
		timer_event this evt_sparewish_update -repeat -1 -interval 10 -userid 5 -attime [expr {[gettime]+3}]
	}

	call scripts/classes/items/calls/takeitems.tcl
	call scripts/classes/zwerg/z_events.tcl
	call scripts/classes/zwerg/z_methods.tcl
	call scripts/classes/zwerg/z_faceanim.tcl
	call scripts/classes/zwerg/z_work_states.tcl
	call scripts/classes/zwerg/z_work_prodfill.tcl
	call scripts/classes/zwerg/z_spare_main.tcl
	call scripts/classes/zwerg/z_spare_reprod.tcl
	call scripts/misc/genericfight.tcl
	call scripts/classes/zwerg/z_work_strike.tcl

	handle_event evt_timer0 {
		call_method this init
	}


	state trapped {
		if {$state_log} {log "[get_objname this] passing state code TRAPPED"}
		if {$trap_mode==0} {
			gnome_failed_work this
			tasklist_clear this
			hide_tools
			kill_all_ghosts
			set trap_mode 1
			if {$trap_type=="petrify"} {
				set_anim this medusa_dead 0 1
				state_disable this
				action this wait 0.6 {state_enable this}
			} else {
				state_disable this
				if {[get_attrib this atr_Hitpoints]>=0.01} {
					set_anim this trappedtostand 0 1
					action this wait 0.6 {state_enable this}
				} else {
					set_anim this gettrapped 0 1
					action this wait 1
				}
			}
			return
		}
		if {$trap_mode==1} {
			if {$trap_type=="petrify"} {
				set_anim this medusa_dead 6 0
				set_stoned_textures 1
				set_physic this 1
			} else {
				log "trappedtostand still [gettime] $trap_time"
				set_anim this trappedtostand 6 0
			}
			set trap_mode 2
			state_disable this
			action this wait $trap_time {state_enable this}
			return
		}
		if {$trap_mode==2} {
			log "trapped getup [gettime] $trap_time"
			set_stoned_textures 0
			set trap_mode 0
			state_trigger this idle
			if {$trap_type=="petrify"} {
				set_physic this 0
				state_disable this
				set_anim this medusa_survive 13 1
				action this wait 1.4 {state_enable this}
			} elseif {[get_attrib this atr_Hitpoints]>=0.01} {
				state_disable this
				set_anim this trappedtostand 7 1
				action this wait 1.0 {state_enable this}
			}
			return
		}
	}
	
	state_leave trapped {
		set_physic this 0
		set trap_mode 0
		//if {$trap_mode} {state_trigger this trapped}
	}

	state_leave idle {
		gnome_idle this 0
	}

	state_enter idle {
		set idletimeout 0
		gnome_idle this 1
	}

	state idle {
		if {$state_log} {log "[get_objname this] passing state code IDLE"}
		if {$state_shell} {print "[get_objname this] passing state code IDLE"}


		incr idletimeout
		if { $sparetime_current_place_ref > 0 } {
			prod_guest guestremove $sparetime_current_place_ref [get_ref this]
			set sparetime_current_place_ref 0
			set sparetime_current_place 0
		}
		if {!$died_in_fight} {

			if {$current_weapon_out != 0 || $current_shield_out != 0 } {
				weapon_putin
				shield_putin
				return
			}

	//		log "state:idle"
			if { [act_when_idle] } { return }
			if { [get_remaining_sparetime this] == 0.0 } {
	//			log "change to work"
				state_triggerfresh this work_dispatch
				return
			}
			if { $idletimeout > 5 } {
	//			log "idletimeout = $idletimeout"
				if { [get_remaining_sparetime this] > 0.0 } {
					log "change to sparetime----zwerg.tcl"
					state_enable this
					state_triggerfresh this sparetime_dispatch
					return
				} else {
					if {$sparetime_is_on} {sparetime_state_end}
					if {[get_gnomeposition this]&&[get_prodautoschedule this]} {walk_down_from_wall}
				}
			}
		}
		set_idle_anim
		state_disable this
		action this wait 1 { state_enable this }
	}

	state task {
		if {$state_log} {log "[get_objname this] passing state code TASK"}
		if {$state_shell} {print "[get_objname this] passing state code TASK"}
		if { [tasklist_cnt this] == 0 } {
			state_trigger this idle
		} else {
			set current_occupation "work"
			set command [tasklist_get this 0]
			tasklist_rem this 0
//			log "[get_objname this]: Task to do:'$command'"
			eval $command
		}
	}



	state_leave task {
		if {$state_log} {log "[get_objname this] leaving state TASK (state_leave code - unlock_item)"}
		if {$state_shell} {print "[get_objname this] leaving state TASK (state_leave code - unlock_item)"}
		unlock_item
	}

	handle_event evt_time_startwork {
//		log "Go to work!"
		set current_plan "work"
		set current_time_plan "work"
	}

	handle_event evt_time_startsparetime {
//		log "Go to sparetime!"
		set current_plan "sparetime"
		set current_time_plan "sparetime"
	}
}


