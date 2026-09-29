def_class Riesenhamster none monster 1 {} {
	call scripts/misc/animclassinit.tcl
	call scripts/classes/characters/rh_globals.tcl
	
	class_fightdist 1.3

	obj_init {
		set scan_range 15.0

		set died_in_fight 0
		set is_dying 0
		set is_in_wheel 0

		set current_weapon_out 0
		set current_weapon_item 0
		set current_shield_out 0
		set current_shield_item 0

		set attack_behaviour "none"
		set attack_item 0
		set current_fightmode 0
		set walk_timeout 0

		set_anim this riesenhamster.standanim 0 $ANIM_LOOP			;# set standard anim
		set_collision this 1										;# turn on light at gnome position

		timer_event this evt_timer_init -repeat 0 -userid 0 -attime [expr {[gettime] + 0.5}]

		call scripts/classes/characters/rh_procs.tcl				;// misc procs
		call scripts/misc/genericfight.tcl
	}

	call scripts/misc/genericfight.tcl
	call scripts/classes/characters/rh_methods.tcl


	def_event evt_timer_init
	handle_event evt_timer_init {
		set_attrib this atr_Hitpoints 1.0
		
		if {!$is_in_wheel} {
			state_triggerfresh this idle
			state_enable this
			set_hoverable this 1
		}
	}

	def_event evt_riesenhamster_die
	handle_event evt_riesenhamster_die {
		if { $is_dying } {return}
		set is_dying 1
		state_trigger this
		state_disable this
		state_trigger this
		if { [get_diedinfight this] == 0 } {
			action this anim die  { call_method [get_ref this] destroy } { call_method [get_ref this] destroy }
		} else {
			action this wait 5    { call_method [get_ref this] destroy } { call_method [get_ref this] destroy }
		}
	}

	def_event evt_task_defend
	handle_event evt_task_defend {
		tasklist_clear this
		set attack_item [event_get this -subject1]
		set attack_behaviour "offensive"
		set approach 0
		fight_startfight
	}

	state trapped {
		if {$trap_mode==0} {
			set trap_mode 1
			play_anim $trap_anim
			return
		}
		if {$trap_mode==1} {
			set trap_mode 2
			state_disable this
			action this wait $trap_time {state_enable this}
			return
		}
		if {$trap_mode==2} {
			state_trigger this idle
			return
		}
	}

	state idle {
		global is_in_wheel

		if {$is_in_wheel} {
			state_disable this
			return
		}

		if { [isunderwater [vector_add [get_pos this] {0 -1.5 0}]] } {
			add_attrib this atr_Hitpoints  -0.1
		}

		if { [get_attrib this atr_Hitpoints] < 0.01 } {
			set_event this evt_riesenhamster_die -target this
		}

		if { [tasklist_cnt this] > 0 } {
			set command [tasklist_get this 0]
			tasklist_rem this 0
			#log "Riesenhamster:Task to do:'$command'"
			eval $command
			return
		}

		set findres [find_enemy]
		if {$findres} {
			return
		 }

		set_idle_anim	;#set idle anim

		set rnd [random]
		if { $rnd < 0.4 } {					;# 80%-rumlaufen 20%-filler
			tasklist_add this "walk_random [expr {4 + [irandom 3]}]"
		} elseif { $rnd < 0.8 } {
			tasklist_add this "run_random [expr {4 + [irandom 3]}]"
		} else {
			set rnd [hf2i [random 3]]
			switch $rnd {
				0 {tasklist_add this "sleeping [irandom 2 6]"}
				1 {tasklist_add this "waiting  [irandom 5 10]"}
				2 {tasklist_add this "cleaning [irandom 1 3]"}
			}
		}

	} ;// state idle
} ;// def_class
