//hamster.tcl
def_class Hamster food material 0 {reproduces lives moves} {
	call scripts/misc/animclassinit.tcl

	set_class_anim standstill 	hamster.stand_anim
	set_class_anim turnleft 	hamster.drehen_links_90
	set_class_anim turnright 	hamster.drehen_rechts_90
	set_class_anim turn180left 	hamster.drehen_links_90
	set_class_anim turn180right	hamster.drehen_rechts_90

	set_class_anim walkstart 	hamster.laufen_start
	set_class_anim walkloop 	hamster.laufen_loop
	set_class_anim walkstop 	hamster.laufen_end

	set_class_anim hoppelstart 	hamster.hoppeln_start
	set_class_anim hoppelloop 	hamster.hoppeln_loop
	set_class_anim hoppelstop 	hamster.hoppeln_end

	set_class_anim galopstart 	hamster.galopp_start
	set_class_anim galoploop 	hamster.galopp_loop
	set_class_anim galopstop 	hamster.galopp_end

	set_class_anim ridestill 	hamster.reiten_stand

	set_class_anim sleepstart 	hamster.schlafen_start
	set_class_anim sleeploop 	hamster.schlafen_loop
	set_class_anim sleepstop 	hamster.schlafen_end

	set_class_anim cleanstart 	hamster.putzen_start
	set_class_anim cleanloop 	hamster.putzen_loop
	set_class_anim cleanstop 	hamster.putzen_end

	set_class_anim beg			hamster.maennchen
	set_class_anim goteaten		hamster.gefressen_werden
	set_class_anim gothit		hamster.getroffen

	set_class_anim wheel_start	hamster.laufrad_start
	set_class_anim wheel_loop	hamster.laufrad_loop
	set_class_anim wheel_end	hamster.laufrad_end

    // Walk
    set_class_animset 0 {
    	{standard			hamster.stand_anim			}
    	{walk_start			hamster.laufen_start		}
    	{walk_loop			hamster.laufen_loop			}
    	{walk_stop			hamster.laufen_end			}

    	{turn_left_90		hamster.drehen_links_90		}
    	{turn_right_90		hamster.drehen_rechts_90	}
    	{turn_left_180		hamster.drehen_links_90		}
    	{turn_right_180		hamster.drehen_rechts_90	}

    	{climb_standard		hamster.gefressen_werden	}
    	{climb_up			hamster.gefressen_werden	}
    	{climb_down			hamster.gefressen_werden	}
    	{climb_right		hamster.gefressen_werden	}
    	{climb_left			hamster.gefressen_werden	}

    	{ground_to_wall		hamster.gefressen_werden	}
    	{wall_to_ground		hamster.gefressen_werden	}

    	{walk_loop_wave		hamster.gefressen_werden	}
    	{ladder_climb_up  	hamster.gefressen_werden	}
    	{ladder_climb_down	hamster.gefressen_werden	}
    	{ground_to_ladder	hamster.gefressen_werden	}
    	{ladder_to_ground	hamster.gefressen_werden	}
    }

    // Hoppel
    set_class_animset 1 {
    	{walk_start			hamster.hoppeln_start			}
    	{walk_loop			hamster.hoppeln_loop			}
    	{walk_stop			hamster.hoppeln_end				}
    }

    // Galopp
    set_class_animset 2 {
    	{walk_start			hamster.galopp_start			}
    	{walk_loop			hamster.galopp_loop				}
    	{walk_stop			hamster.galopp_end				}
    }

	def_event evt_timer0

	class_defaultanim hamster.standard

	call scripts/misc/aggr_events.tcl
	
	obj_init {

		call scripts/misc/aggr_events.tcl
		
		set_anim this hamster.stand_anim 0 $ANIM_LOOP
		set_viewinfog this 0
		set_sequenceactive this 1
		set_logactions this 0

		set_attrib this weight 0.01
		set_attrib this hitpoints 0.02
		
		set info_string ""

//# Werte zum tunen:
		set scan_range 4			;# Reichweite, die der Hamster Zwerge sieht
		set search_range 6			;# Futtersuchreicherite
		set escape_range 2			;# Entfernung, die der Punkt den der Hamster zum fliehen verwendet
		set nutrition 0			    ;# StartErnährungswert
		//set nutrivalue 50			;# Nährwert (in kcal :-) für einen Pilzhut
		//set missnutrival 30			;# Nährwert falls er den Pilzhut nicht erwischt
//# mehr gibt's noch nicht

		set last_activity 0
		set escape_pos 0
		set gnomesensor 0

		set scan_speed "fast"

		set rescan 1
		
		set is_paralyzed 0
		
		set is_farmed 0
		set myfarm 0
		set farmpos ""
		
		timer_event this evt_timer0 -interval 1 -repeat -1 -userid 0

		proc scan_timer {opt} {
			global scan_speed
			if { $opt == $scan_speed} {return}
			switch $opt {
				"fast"	{timer_event this evt_timer0 -interval 1 -repeat -1 -userid 0}
				"slow"  {timer_event this evt_timer0 -interval 5 -repeat -1 -userid 0}
				default {log "hamster illegal opt in scan_timer !"}
			}
			set scan_speed $opt
		}

		proc walk_random {plength} {
			state_disable this
			action this walk "-canclimb 0 -randompath $plength -randomz 4 -animsets 0 -useobjects 0" {state_enable this}
			return true
		}

		proc hoppel_random {plength} {
			state_disable this
			action this walk "-canclimb 0 -randompath $plength -randomz 2 -animsets 1  -useobjects 0" {state_enable this}
			return true
		}

		proc hoppel_pos {pos} {
			state_disable this
			set pos [vector_fix $pos]
			action this walk "-canclimb 0 -target \{$pos\} -animsets 1 -useobjects 0" {state_enable this} {}
			return true
		}

		proc walk_pos {pos} {
			state_disable this
			set pos [vector_fix $pos]
			action this walk "-canclimb 0 -target \{$pos\} -animsets 0  -useobjects 0" {state_enable this}
			return true
		}

		proc play_anim {anim} {
			state_disable this
			action this anim $anim {state_enable this}
			return true
		}

		proc loop_anim {anim min max} {
			tasklist_add this [list play_anim ${anim}start]
			set reps [irandom [expr $max - $min]]
			incr reps $min
			for {set i 0} {$i < $reps} {incr i} {
				tasklist_add this [list play_anim ${anim}loop]
			}
			tasklist_add this [list play_anim ${anim}stop]
		}

		proc test_escape {} {
			global escape_pos scan_range escape_range rescan
			if { [get_walkresult this] == 2 && $rescan == 0 } { return 0 }
			if { $escape_pos != 0 } { return 1 }
			set zl [obj_query this "-class Zwerg -range $scan_range"]

			if { $zl == 0 } {
				scan_timer slow
				return 0
			} else {
				scan_timer fast
			}

			set posnum 0
			set posvec {0 0 0}
			set clipping ""
			set ownpos [get_pos this]
			foreach item $zl {
				set ipos [get_pos $item]
				set dist [vector_abs [vector_sub $ownpos $ipos]]
				if { $dist <= $scan_range } {
					incr posnum
					set posvec [vector_add $ipos $posvec]
					set clipping "$clipping -clip [expr {[lindex $ipos 0] - 1.5}] [expr {[lindex $ipos 2] - 1.5}] [expr {[lindex $ipos 0] + 1.5}] [expr {[lindex $ipos 2] + 1.5}]"
				}
			}

			if { $posnum == 0 } {
				return 0
			}

			set mult [expr 1.0 / $posnum.0]
			set posvec [vector_mul $posvec $mult]
			set dir [vector_mul [vector_normalize [vector_sub $ownpos $posvec]] $escape_range]
			set preft [vector_add $ownpos $dir]
			set ev "get_place -center \{$preft\} $clipping -circle 8 -mindist 0"
			set target [eval $ev]
			if { [lindex $target 0] < 0 } {
				set escape_pos -1 ;# in die enge getrieben -> also randompathfinder!
			} else {
				set escape_pos $target
			}
			return 1
		}

		proc do_escape {} {
			global escape_pos rescan
			if { $escape_pos == -1 } {
				set rescan 0
				tasklist_add this "walk_random 5"
			} else {
				set rescan 1
				tasklist_add this "walk_pos \{$escape_pos\}"
			}
			set escape_pos 0
			state_triggerfresh this task
		}

		proc wait_time {seconds} {
			if { [get_paralyzed] } {
				set_anim this hamster.getroffen 14 0
			} else {
				set_anim this hamster.stand_anim 0 2
			}
			state_disable this;
			action this wait $seconds {state_enable this}
			return true
		}

		proc take_item {item} {
            if {![obj_valid $item]} {
                // das Item ist leider schon weg
				return
            }
			set ownpos [get_pos this]
			set itmpos [get_pos $item]
			set dist [vector_abs [vector_sub $ownpos $itmpos]]
			if { $dist < 0.8 } {
				del $item
			} else {
			}
		}

		
		// testen, obj ich in einer Farm bin

		proc test_farmed {} {
			global is_farmed
			return $is_farmed
			set farm [obj_query this "-class Farm -range 8 -limit 1"]
			if {$farm != 0} {
				set rpn [obj_query $farm "-class Hamster -boundingbox \{-2 -1 -3 2 1 3\}"]
				if {[lsearch $rpn [get_ref this]] != -1} {
					set_farmed $farm
					return
				} 
			}
			set_farmed 0
		}
		
		
		proc set_farmed {bool} {
			global is_farmed
			set is_farmed $bool
			set_attrib this farmed $bool
		}
		
		proc do_paralyzed {} {
			global is_paralyzed
			if {!$is_paralyzed} {
				tasklist_clear this
				state_disable this
				set_paralyzed 1
				play_anim gothit
				// Aufwachen des Hamsters nach 30 Minuten (30 * 60 = 1800 Sekunden)
				timer_unset this 1
				timer_event this evt_timer_wakeup -repeat 1 -interval 1 -userid 1 -attime [expr [gettime]+1800]
			}
		}
		
		proc set_paralyzed {bool} {
			global is_paralyzed
			set is_paralyzed $bool
			set_attrib this paralyzed $bool
			set_physic this $bool
		}		
		
		proc get_farmed {} {
			global is_farmed
			return $is_farmed
		}
		
		proc get_paralyzed {} {
			global is_paralyzed
			return $is_paralyzed
			//return [expr {[get_attrib this paralyzed] > 0}]
		}

		proc eat_check {} {
			global search_range nutrition
			if { $nutrition <50 } {
				incr nutrition
			} else {
				set nutrition 0
	            // Pilzhut zum essen suchen
				set foodref [obj_query this "-class Pilzhut -range $search_range -limit 1 -flagneg contained"]
				if {!$foodref} {
				    // Zweite Wahl: Grillpilze
    				set foodref [obj_query this "-class Grillpilz -range $search_range -limit 1 -flagneg contained"]
				}

				if { $foodref } {
					tasklist_add this "walk_pos \{[get_pos $foodref]\}"
					tasklist_add this "play_anim goteaten"
					tasklist_add this "play_anim goteaten"
					tasklist_add this "play_anim goteaten"
					tasklist_add this "play_anim goteaten"
					tasklist_add this "play_anim goteaten"
					tasklist_add this "take_item $foodref"
					return 1
				}
			}
			return 0
		}
		
		proc evt_timer0_proc {} {
			global is_paralyzed is_farmed gnomesensor
			if { $is_paralyzed } { return }
		
			if { !$is_paralyzed && [is_contained this] } {
				do_paralyzed
				return
			}
		
			if {!$is_paralyzed && [isunderwater [get_pos this]]} {
				do_paralyzed
				return 
			}
		
			if { !$is_farmed } {
				if { $gnomesensor } {
					incr gnomesensor -1
					if { [test_escape] } {
						tasklist_clear this
						state_triggerfresh this idle
					}
				}
			}
		}
		
		proc state_idle_proc {} {
			global is_paralyzed is_farmed last_activity myfarm farmpos
			if { [get_paralyzed] } {
				state_disable this
				return
			}
			
			if { [tasklist_cnt this] > 0 } {
				state_trigger this task
				return
			}
	
			if { !$is_farmed } {
				if { [test_escape] } {
					do_escape
					return
				}
			} 
			
			if { $is_farmed } {
				set activity [irandom 5]
				if {$activity == $last_activity} {
					set activity [expr {($activity + 1) % 5}]
				}
				set last_activity $activity
				switch $activity {
					0	{loop_anim clean 2 6}
					1	{play_anim beg}
					2	{wait_time [random 1.5 4.0]}
					3	{loop_anim sleep 6 10}
					default {
						set newpos [irandom 35]
						set newx [expr {($newpos%7)*0.5-1.5}]
						set newz [expr {($newpos/7)-2.0}]
						set newpos [vector_add $farmpos [list $newx 0 $newz]]
						hoppel_pos $newpos
					}
				}
			} else {
				if { [eat_check] } {
					return
				}
		
				set activity [irandom 6]
				if {$activity == $last_activity} {
					set activity [expr {($activity + 1) % 6}]
				}
				set last_activity $activity
				switch $activity {
					0	{loop_anim clean 2 6}
					1	{play_anim beg}
					2	{wait_time [random 1.5 4.0]}
					3	{loop_anim sleep 6 10}
					default {hoppel_random [irandom 2 4]}
				}
			}
			state_trigger this task
		}
		
		proc state_task_proc {} {
			if { [tasklist_cnt this] == 0 } {
				state_trigger this idle
			} else {
				set command [tasklist_get this 0]
				tasklist_rem this 0
				eval $command
			}
		}
		
		state_reset this
		state_trigger this idle
		state_enable this
		
		set_paralyzed 0
		set_farmed 	  0
	}


	def_event evt_timer_wakeup
	handle_event evt_timer_wakeup {
		if {[is_contained this]} {
			// geht im Moment nicht - vielleicht später
			// Aufwachen des Hamsters nach 30 Minuten (30 * 60 = 1800 Sekunden)
			timer_event this evt_timer_wakeup -repeat 1 -interval 1 -userid 1 -attime [expr [gettime]+1800]
			return
		}
		state_enable this
		state_triggerfresh this idle
		set_attrib this hitpoints 0.02
		set_paralyzed 0
	}



	state idle {
		state_idle_proc
	}


	state task {
		state_task_proc
	}

	handle_event evt_timer0 {
		evt_timer0_proc
	}

	method set_farmhamster {farm} {
		if {$farm} {
			set_farmed 1
			set_paralyzed 0
		} else {
			set_farmed 0
		}
		set myfarm $farm
		set farmpos [get_pos $farm]
		state_triggerfresh this idle
	}
	
	method activate_gnomesensor {} {
		set gnomesensor 10
	}
	
	method catch_farmhamster {} {
		if {$is_farmed&&$myfarm} {
			if {[obj_valid $myfarm]} {
				call_method $myfarm actualize_hamsters
			}
		}
	}
	
	method walkpos {pos} {
		walk_pos $pos
	}

	method Editor_Set_Info {ifo} {
		global info_string
		set info_string $ifo
		foreach entry $ifo {
			switch [lindex $entry 0] {
				"aggr" {set player_aggressivity [lindex $entry 1]}
				"aggrmax" {set aggr_max [lindex $entry 1]}
			}
		}
	}
	
	method change_owner {new_owner} {
		set_owner this $new_owner
	}

	method paralyze {} {
		do_paralyzed
	}

	method get_scanrange {} {
		return $scan_range
	}
}


