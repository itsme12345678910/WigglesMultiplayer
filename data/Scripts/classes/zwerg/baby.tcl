def_class Baby none baby 0 {lives moves} {
	call scripts/misc/animclassinit.tcl	// anim members
	def_event evt_task_walk
	def_event evt_baby_growup

	set_class_anim standstill		baby.standard

	set_class_anim turn180right		baby.drehen_links
	set_class_anim turn180left		baby.drehen_rechts
	set_class_anim turnright		baby.drehen_rechts
	set_class_anim turnleft			baby.drehen_links

	set_class_anim walkstart		baby.laufen_start
	set_class_anim walkloop			baby.laufen_loop
	set_class_anim walkstop1		baby.laufen_end
	set_class_anim walkstop2		baby.laufen_fallen_sitzen

	set_class_anim crawlstart		baby.krabbeln_start
	set_class_anim crawlloop		baby.krabbeln_loop
	set_class_anim crawlstop		baby.krabbeln_end

	set_class_anim climbup			baby.kletter_hoch_loop
	set_class_anim climbdown		baby.kletter_runter_loop
	set_class_anim climbright		baby.kletter_rechts_loop
	set_class_anim climbleft		baby.kletter_links_loop
	set_class_anim climbtostand		baby.kletter_zu_stand
	set_class_anim standtoclimb		baby.stand_zu_kletter
	set_class_anim climbstill		baby.kletterstand_anim

	// Walk
	set_class_animset 0 {
		{standard			baby.standard				}
		{walk_start			baby.laufen_start			}
		{walk_loop			baby.laufen_loop			}
		{walk_stop			baby.laufen_end				}

		{turn_left_90		baby.drehen_links			}
		{turn_right_90		baby.drehen_rechts			}
		{turn_left_180		baby.drehen_links			}
		{turn_right_180		baby.drehen_rechts			}

		{climb_standard		baby.kletterstand_anim		}
		{climb_up			baby.kletter_hoch_loop		}
		{climb_down			baby.kletter_runter_loop	}
		{climb_right		baby.kletter_rechts_loop	}
		{climb_left			baby.kletter_links_loop		}

		{ground_to_wall		baby.stand_zu_kletter		}
		{wall_to_ground		baby.kletter_zu_stand		}


		{walk_loop_wave		baby.zappeln_loop			}
		{ladder_climb_up  	baby.kletter_hoch_loop		}
		{ladder_climb_down	baby.kletter_runter_loop	}
		{ground_to_ladder	baby.stand_zu_kletter		}
		{ladder_to_ground	baby.kletter_zu_stand		}

	}

	// Walk2 (mit hinfallen)
	set_class_animset 1 {
		{walk_stop			baby.laufen_fallen_sitzen	}
	}


	// Crawl
	set_class_animset 2 {
		{walk_start			baby.krabbeln_start			}
		{walk_loop			baby.krabbeln_loop			}
		{walk_stop			baby.krabbeln_end			}
	}

	set_class_anim crystart			baby.weinen_start
	set_class_anim cryloop			baby.weinen_loop
	set_class_anim cryend			baby.weinen_end

	set_class_anim wavestart		baby.sitzen_winken_start
	set_class_anim waveloop			baby.sitzen_winken_loop
	set_class_anim waveend			baby.sitzen_winken_end

	set_class_anim schoolstandup	baby.schule_aufstehen
	set_class_anim schoolsitdown	baby.schule_hinsetzen
	set_class_anim schoolask		baby.schule_sitzen_melden
	set_class_anim schoolagree		baby.schule_sitzen_nicken
	set_class_anim schoolstand		baby.schule_sitzen_stand
	set_class_anim schoolstandani	baby.schule_sitzen_standani
	set_class_anim schooldreamer	baby.schule_sitzen_traeumen
	set_class_anim schoolwriggle	baby.schule_sitzen_zappeln

	set_class_anim tantrumstart		baby.wutanfall_start
	set_class_anim tantrumloop		baby.wutanfall_loop
	set_class_anim tantrumend		baby.wutanfall_end

	set_class_anim wrigglestart		baby.zappeln_start
	set_class_anim wriggleloop		baby.zappeln_loop
	set_class_anim wriggleend		baby.zappeln_end

	set_class_anim roll				baby.rolle_vorwaerts
	set_class_anim falldown			baby.auf_po_fallen
	set_class_anim fallfront		baby.nach_vorn_fallen

	set_class_anim sleepstart		baby.einschlafen
	set_class_anim sleeploop		baby.schlafen_loop
	set_class_anim sleepend			baby.aufwachen

	set_class_anim growup			baby.erwachsen_werden

	call scripts/misc/genattribs.tcl   ;# define attribs for all characters
	call scripts/misc/obj_attribs.tcl

	method walk_outofplacement {prodref} {
		tasklist_add this "walk_out_of $prodref"
	}

	call scripts/misc/mp_sync.tcl

	obj_init {
		call scripts/misc/mp_sync.tcl

		set is_initialized 	0
		set idletimeout 	0
		set current_task 	0
		set current_school 	0
		set gnome_gender 	"unset"
		set idlecount 		0
		set lastschoolquery 0
		set im_grownup		0
		set_attrib this GnomeAge [gettime]


		set_anim this baby.standard 0 $ANIM_LOOP				;# set standard anim
		set_fogofwar this 14 8									;# uncover fog of war area
		set_autolight this 1
		set_collision this 1
		set_selectable this 1
		set_hoverable this 1
		auto_choose_workingtime this

		set_attrib this hitpoints 1.0

		timer_event this evt_baby_growup -repeat -1 -interval 5 -userid 1 -attime [expr {[gettime] + 1200}]
		timer_event this evt_timer0 -repeat 1 -interval 1 -userid 0 -attime [expr {[gettime] + 0.1}]

		set growup_error_counter 0

		proc grow_up {} {
			global gnome_gender growup_error_counter im_grownup
			if {$im_grownup} {return}
			if {$growup_error_counter>4} {timer_unset this 1}
			set err1 [catch {set nz [new Zwerg]}]
			if {$err1==0} {
				set err2 [catch {
					set_owner $nz [get_owner this]
					set_pos $nz [get_pos this]
					set otherattribs {}
					foreach attribut [get_expattrib] {
						lappend otherattribs [get_attrib this $attribut]
					}
					timer_unset $nz 6
					call_method $nz baby_to_gnome $gnome_gender [get_objname this] [get_worktime this] [get_attrib this atr_Nutrition] [get_attrib this atr_Alertness] [get_attrib this atr_Mood] [get_attrib this atr_Hitpoints] [get_attrib this atr_ExpMax] $otherattribs [expr {[gettime]-[get_attrib this GnomeAge]}] [get_user_groups this]
					partner_info transfer this $nz
					log "my user groups [get_user_groups this]"
					set_user_groups $nz "[get_user_groups this]"
					log "user groups $nz : [get_user_groups $nz]"					
					set_visibility this 0
					if {[is_selected this]} {set_selectedobject $nz}
				} errMsg]
				if {$err2&&$growup_error_counter<5} {
					del $nz
					incr growup_error_counter
					eval ${growup_error_counter}$errMsg
				} else {
					set im_grownup 1
					del this
				}
			}
		}

		proc walk_random {plength} {
			state_disable this
			action this walk "-canclimb 0 -animsets [irandom 2] -randompath $plength -randomz 4" {state_enable this}
			return true
		}

		proc crawl_random {plength} {
			state_disable this
			if {[mp_active]} {
				# Multiplayer: Zielpunkt vom Host statt Zufallspfad der Engine, ohne Host kurz warten
				set place [mp_random_target crawlrandom $plength]
				if {$place == ""} {
					action this wait 2 {state_enable this}
				} else {
					action this walk "-canclimb 0 -animsets 2 -target \{$place\}" {state_enable this}
				}
				return true
			}
			action this walk "-canclimb 0 -animsets 2 -randompath $plength -randomz 3" {state_enable this}
			return true
		}

		proc walk_pos {pos} {
			state_disable this
			set pos [vector_fix $pos]
			action this walk "-target \{$pos\}  -animsets [mp_irandom walkanimset 0 2]" {state_enable this}
			return true
		}

		proc walk_dummy {item dummy} {
			state_disable this
//			log "[state_get this]/[state_getenablecnt this]"
			action this walk "-object $item -dummy $dummy -animsets 0" {
				if {4 != [get_walkresult this ] } {
//					log "[get_objname this]: walk not successful"
				}
				state_enable this
//				log "[state_get this]/[state_getenablecnt this]"
			} {
				log "walk break"
		#		state_enable this
			}
			return true
		}


		proc rotate_toright {} {state_disable this;action this rotate 4.71 {state_enable this}}
		proc rotate_toleft {} {state_disable this;action this rotate 1.57 {state_enable this}}
		proc rotate_toback {} {state_disable this;action this rotate 3.14 {state_enable this}}
		proc rotate_tofront {} {state_disable this;action this rotate 0 {state_enable this}}

		proc goto_school {school} {
			// log "[get_objname this] wants to go to School!"

			prod_guest guestremove $school [get_ref this]
			set seat [prod_guest guestfree $school]
//			log "seat: $seat"
			set dummy [prod_guest getlink $school $seat]
			prod_guest guestset $school $seat [get_ref this]
			tasklist_add this "walk_dummy $school $dummy"
			tasklist_add this "prod_guest addorder $school $seat"
			tasklist_add this "set_roty this 3.14"
			tasklist_add this "play_anim schoolsitdown"
			tasklist_add this "learn_school"
		}

		proc learn_school {} {
			global current_school
			tasklist_add this "play_anim schooldreamer"
			tasklist_add this "play_anim schoolstand"
			tasklist_add this "play_anim schoolwriggle"
			tasklist_add this "play_anim schoolstandani"
			tasklist_add this "play_anim schoolask"
			tasklist_add this "play_anim schoolagree"
			tasklist_add this "play_anim schoolstand"
			tasklist_add this "play_anim schoolstandani"
			tasklist_add this "learn_school"
		}

		proc find_free_school {} {
			set schools [obj_query this "-class Schule -range 50"]
			if {$schools == 0} {
				return 0
			}

			foreach school $schools {
				if {[prod_guest guestfree $school]!=-1 && [get_prod_slot_cnt $school _Unterricht]} {
					return $school
				}
			}

			return 0
		}


		proc play_anim {anim} {
			state_disable this
			action this anim $anim {state_enable this}
			return true
		}

		proc loop_anim {anim min max} {
			tasklist_add this [list play_anim ${anim}start]
			set reps [hf2i [mp_random loopreps 0.0 [expr $max - $min]]]
			incr reps $min
			for {set i 0} {$i < $reps} {incr i} {
				tasklist_add this [list play_anim ${anim}loop]
			}
			tasklist_add this [list play_anim ${anim}end]
		}

		proc baby_sleep {} {
			tasklist_add this "play_anim sleepstart"
			loop_anim sleeploop 10 30
			tasklist_add this "play_anim sleepstop"
		}

		proc baby_fall {anim} {
			tasklist_add this "play_anim $anim"
			loop_anim cry 6 18
		}

		proc baby_roll {} {
			tasklist_add this "play_anim roll"
		}

		proc set_idle_anim {} {
			if { [get_gnomeposition this] == 0 } {
				set_anim this baby.stand_anim 0 2 ;#set idle anim
			} else {
				set_anim this baby.kletterstand_anim 0 2 ;#set idle anim
			}
		}

		proc walk_out_of {item} {
			set bbox [check_ghost_coll bbox this $item]
			if { $bbox != 0 } {
				set opos [get_pos this]
				set bbn [lindex $bbox 0]
				set bbp [lindex $bbox 1]
				if { [vector_inbox $opos $bbn $bbp] } {
					#log "[get_objname this] ich bin im weg ! "
					set xn [expr [lindex $opos 0] - [lindex $bbn 0]]
					set xp [expr [lindex $bbp 0]  - [lindex $opos 0]]
					set zn [expr [lindex $opos 2] - [lindex $bbn 2]]
					set zp [expr [lindex $bbp 2]  - [lindex $opos 2]]

					set XP [expr $xp + 4]
					set XN [expr $xn + 4]
					set ZP [expr $zp + 0]
					set ZN [expr $zn + 4]

					set pos [get_place -center $opos -rect $xn $zn $xp $zp -clip $XN $ZN $ZP $ZN -placelock 5]
					if { [lindex $pos 0] == -1 } {
//						log "get_place has found no place !!! in proc 'walk_out_of'"
						walk_pos "[get_posx this] [get_posy this] 14"
					} else {
						walk_pos $pos
					}
				}
			}
			return 1
		}

		proc get_next_gnome {} {
            return [obj_query this "-class Zwerg -owner own -limit 1"]
		}

		proc walk_near_pos {pos range} {
			set thispos [get_pos this]
            set near_pos [get_place -center $pos -nearpos $thispos -mindist 2 -circle $range -materials false]
            if { [lindex $near_pos 0] > 0 } {
            	tasklist_add this "walk_pos \{$near_pos\}"
				return 1
			}
//			log "Platz nicht gefunden: near_pos = $near_pos"
           	tasklist_add this "walk_pos \{$pos\}"

			return 1
		}

		state_reset this
		state_trigger this idle
		state_enable this

	}

	handle_event evt_task_walk {
		set evtpos [event_get this -pos1]
		state_triggerfresh this task
		if $current_school {
			prod_guest guestremove $current_school [get_ref this]
			tasklist_add this "play_anim schoolstandup"
		}
		tasklist_clear this
		set rnd [hf2i [random 5]]
		if { $rnd > 2 } {
			set rnd 0
		}

		if { [get_gnomeposition this] == 1 } {
			set rnd 0
		}
		set current_task "walk"

		if {$rnd == 0} {
			set own_gnome [obj_query this " -pos \{$evtpos\} -class Zwerg -range 20 -owner own"]
			if {$own_gnome == 0} {
//				log "Keine Eigene Gnome dort gefunden, Baby wird dorthin nicht laufen"
				set rnd 1
			}
		}

		switch $rnd {
			0 {tasklist_add this "walk_pos \{$evtpos\}"}
			1 {baby_fall falldown}
			2 {baby_fall fallfront}
		}
	}

	handle_event evt_baby_growup {
		state_disable this
		action this anim growup grow_up grow_up
	}


	method init {} {
		if {$is_initialized} {
			return
		}
		set is_initialized 1

		if { ! [minimalrun] } {
			set gnome_gender [auto_choose_gender this]
		} else {
			set gnome_gender "male"
		}
		if { $gnome_gender == "female" } {
			set_objname this auto female
		} else {
			set_objname this auto male
		}

		set favourite_worktimes 0
		foreach gnome [lnand 0 [obj_query this -class {Zwerg Baby} -owner own]] {
			set workstart [get_worktime $gnome start]
			//log "Baby - found: $gnome $workstart"
			if {$workstart<3.5||$workstart>9.5} {
				incr favourite_worktimes 1
			} else {
				incr favourite_worktimes -1
			}
		}

		//log "Baby - favw: $favourite_worktimes"
		if {$favourite_worktimes>0} {
			set_worktime this 6.0 6.0
		} else {
			set_worktime this 0.0 6.0
		}

		// Geburt im Newsticker melden
        if {[net localid] == [get_owner this]} {
			set id [newsticker new [get_owner this] -text "[lmsg zwerggeboren] ([get_objname this])" -time [expr {3 * 60}]]
			set ref [get_ref this]
			newsticker change $id -click "newsticker delete $id;
										if {\[obj_valid $ref\] } {
									  		if {\[get_objclass $ref\] == \"Baby\"} {
												set x \[get_posx $ref\];
												set y \[get_posy $ref\];
												set_view \$x \[expr \$y -1\] 0 -0.35 0
											}
										}"
		}
	}


	// Der Verjüngungstrank macht aus einem Zwerg wieder ein Baby

	method gnome_to_baby {gender name worktime nutri alert mood hitpo emax attribs age} {
		set is_initialized 1
		set gnome_gender $gender
		set_objgender this $gender
		set_objname this $name

		set_attrib  this atr_Nutrition 	$nutri
		set_attrib  this atr_Alertness 	$alert
		set_attrib  this atr_Mood	   	$mood
		set_attrib  this atr_Hitpoints 	$hitpo
		set_attrib  this atr_ExpMax 	$emax

//		log "attribs: $attribs"

		set iattr 0
		foreach attribut [get_expattrib] {
			set_attrib this $attribut [lindex $attribs $iattr]
			incr iattr
		}

		if { [llength $worktime] == 2 } {
			set_worktime this [lindex $worktime 0] [lindex $worktime 1]
		}
		set was_baby 1
	}



	state idle {
		if { [tasklist_cnt this] > 0 } {
			state_trigger this task
			return
		}

		if {$current_school > 0} {
			prod_guest guestremove $current_school [get_ref this]
			set current_school 0
		}

		set_idle_anim

		set current_school 0
	    set curtime [gettime]
	    if {$curtime - $lastschoolquery > 200} {
			set current_school [find_free_school]
			set lastschoolquery $curtime
		}

		if {$current_school} {
			tasklist_add this "goto_school $current_school"
			set current_task "school"
			return
		}

		//testen ob baby nicht weit von Zwergen entfernt ist
		//falls ja zu den Zwergen laufen

		if {$idlecount > 5} {
			set idlecount 0
			set next_gnome [get_next_gnome]
			if {$next_gnome > 0} {
				if {[vector_dist [get_pos $next_gnome] [get_pos this]] > 10} {
					walk_near_pos [get_pos $next_gnome] 5
				}
			}
		}

		incr idlecount

		// 70%-rumlaufen 30%-filler

		set rnd [mp_random babyidle 0.0 1.0]
		if { $rnd < 0.7} {
			tasklist_add this "crawl_random [hf2i [mp_random crawlradius 3.0 2 4]]"
		} else {
			set rnd [mp_irandom babyfiller 2 6]
			switch $rnd {
				0 {loop_anim cry 10 30}
				1 {loop_anim tantrum 4 14}
				2 {loop_anim wriggle 4 9}
				3 {baby_roll}
				4 {loop_anim wave 5 20}
				5 {loop_anim sleep 10 30}
			}
		}
	}


	state task {
		if { [tasklist_cnt this] == 0 } {
			state_trigger this idle
		} else {
			set command [tasklist_get this 0]
			tasklist_rem this 0
//			log "baby - command: $command"
			eval $command
		}
	}

}
