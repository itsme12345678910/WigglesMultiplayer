

def_class Raupe food material 0 {reproduces lives moves} {
	call scripts/misc/animclassinit.tcl

	class_defaultanim raupe01.standard

	set_class_anim standstill raupe01.standard
	set_class_anim hangstill raupe01.standard

	set_class_anim crawl raupe01.kriechen

	set_class_anim crawlstart raupe01.kriechen
	set_class_anim crawlloop raupe01.kriechen
	set_class_anim crawlend raupe01.kriechen

	set_class_anim turnleft raupe01.kriechen
	set_class_anim turnright raupe01.kriechen
	set_class_anim turn180right raupe01.kriechen
	set_class_anim turn180left raupe01.kriechen

	def_event evt_dummy
	def_event evt_timer0

	call scripts/misc/aggr_events.tcl
	
	call scripts/misc/mp_sync.tcl
	obj_init {
		call scripts/misc/mp_sync.tcl

		call scripts/misc/aggr_events.tcl
		
		set rtyp [irandom 1 13]
		if {[string length $rtyp]<2} {set rtyp 0$rtyp}
		set_anim this raupe$rtyp.standard 0 $ANIM_LOOP
		set anim wait

		set_viewinfog this 0

		set_sequenceactive this 1

		set_attrib this weight 0.01
		set_attrib this hitpoints 0.02

		set info_string ""

		set farmed 0
		set step 0
		
		if {[land $rtyp {02 06 07 08}]==""} {
			set attacktyp 0
		} else {
			set attacktyp 1
		}
		set attack_counter 0
		set attackplant 0
		set approached 0
		set attackanim 5
		set particledir {0 0 0}
		set particlepos {0 0 0}
		
		set_roty this [random 6.28]

		proc test_farmed {} {
			global farmed
			set farmed [obj_query this -class Farm -boundingbox {-2 -0.5 -3 2 0.5 3} -limit 1]
		}

		proc crawl_free {} {
			if {[get_max_fow this]<10} {return 0}
			set rpos [get_pos this]
			if {[mp_is_client]} {
				# Multiplayer: das Kriechziel kommt vom Host, ohne Host bleibt die Raupe liegen
				if {[find_plant]} {return}
				set place [mp_take_pos crawl]
				if {$place == ""} {set place {-1 -1 -1}}
			} else {
				set crot [expr {[get_roty this]+1.57}]
				set nrot [expr {$crot+rand()*3-1.5}]
				if {[find_plant]} {return}
				if {rand()<0.2} {
					fincr nrot 3.14
				}
				set npos [vector_add $rpos [get_vectorxz $nrot [random 2.0 4.0]]]
				set place [get_place -center $npos -circle 3 -nearpos $rpos -random 2]
				mp_give crawl $place
			}
			if {[lindex $place 0]<0} {
				wait 3
			} else {
				set_roty this [expr {[get_anglexz $rpos $place]-1.57}]
				//log "$crot->$nrot->[expr {[get_anglexz $rpos $place]-1.57}]"
				move $place
			}
		}

		proc crawl_farmed {} {
			global farmed
			set rpos [get_pos this]
			set farmpos [get_pos $farmed]
			set gnome [obj_query $farmed -class Zwerg -boundingbox {-3 -0.5 -5 3 0.5 5} -limit 1]
			if {$gnome} {
				set near $rpos
				set center [get_pos $gnome]
			} else {
				set center $rpos
			}
			set diffvec [vector_sub $farmpos $center]
			set xn [expr {[lindex $diffvec 0]-2}]
			set zn [expr {[lindex $diffvec 2]-3}]
			set xp [expr {$xn+3.5}]
			set zp [expr {$zn+6}]
			//log "$xn $xp $zn $zp ($center) ($farmpos)"
			set place [mp_choose farmcrawl {0 0 0} {
				if {$gnome} {
					get_place -center $center -rect $xn $zn $xp $zp -mindist 0.6 -nearpos $near -random 2
				} else {
					get_place -center $center -rect $xn $zn $xp $zp -mindist 0.6 -random 2
				}
			}]
			if {[lindex $place 0]<1} {
				wait 3
			} else {
				set_roty this [expr {[get_anglexz $rpos $place]-1.57}]
				move $place
			}
		}
		
		proc find_plant {} {
			global attack_plant attacktyp attack_counter
			if {$attacktyp==0} {return 0}
			if {$attack_counter<10} {
				incr attack_counter
				return 0
			}
			set attack_counter 0
			if {[get_owner this]==-1} {return 0}
			set plant [obj_query this -class Fresspflanze -range 8 -limit 1]
			if {$plant} {
				set mpos [get_pos this]
				set ppos [get_pos $plant]
				if {[vector_dist3d $mpos $ppos]>5.0} {
					set place [get_place -center [get_pos $plant] -circle 5.0 -mindist 2.0 -nearpos [get_pos this]]
					if {[lindex $place 0] > 0} {
						log "Raupe found plant, approaching: $place"
						set attack_plant $plant
						state_triggerfresh this plant_attack
						return 1
					}
				} else {
					log "Raupe found plant near"
					set attack_plant $plant
					state_triggerfresh this plant_attack
					return 1
				}
			}
			return 0
		}

		proc move {place} {
			global anim rtyp ANIM_LOOP
			if {$anim!="crawl"} {
				set_anim this raupe$rtyp.kriechen 0 $ANIM_LOOP
				set anim crawl
			}
			state_disable this
			action this move "\{$place\} 0.03" {state_enable this}
		}

		proc wait {time} {
			global anim rtyp ANIM_STILL
			set_anim this raupe$rtyp.standard 0 $ANIM_STILL
			set anim wait
			state_disable this
			action this wait $time {state_enable this}
		}

		timer_event this evt_timer0 -interval 1
	}

	handle_event evt_timer0 {
		test_farmed
		if {0==$farmed} {
			state_triggerfresh this free
//			log "new->free"
		} else {
			state_triggerfresh this farmed
//			log "new->farmed"
		}
	}

	handle_event evt_dummy {

	}

	method die {} {
		del this
	}

	method get_type {} {
		return $rtyp
	}

	method set_type {typ} {
		set rtyp $typ
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
	
	state free {
		if {[is_contained this]} {
			state_triggerfresh this contained
			set_anim this raupe$rtyp.standard 0 $ANIM_STILL
			set anim wait
//			log "free->cont"
		} else {
			crawl_free
		}
	}

	state farmed {
		if {[is_contained this]} {
			state_triggerfresh this contained
			set_anim this raupe$rtyp.standard 0 $ANIM_STILL
			set anim wait
//			log "farmed->cont"
		} else {
			if {![obj_valid $farmed]||![get_buildupstate $farmed]} {
				state_triggerfresh this free
				//log "farmed->free"
			} else {
				if {[mp_rand farmwait 0.0]<0.05} {
					wait 1
				} else {
					crawl_farmed
				}
			}
		}
	}

	state contained {
		if {[is_contained this]} {
			wait 4
		} else {
			test_farmed
			if {0==$farmed} {
				state_triggerfresh this free
//				log "cont->free"
			} else {
				state_triggerfresh this farmed
//				log "cont->farmed"
			}
		}
	}
	
	state plant_attack {
		if {[get_attrib this atr_Hitpoints]<0.01} {
			destruct this
			del this
			return
		}
		if {[is_contained this]} {
			set attack_plant 0
			set approached 0
			state_triggerfresh this contained
			set_anim this raupe$rtyp.standard 0 $ANIM_STILL
			set anim wait
			return
		}
		if {![obj_valid $attack_plant]} {
			set attack_plant 0
			set approached 0
			state_triggerfresh this free
			set_anim this raupe$rtyp.kriechen 0 $ANIM_LOOP
			return
		}
		log "Raupe attacking plant $attack_plant ($approached) ($attackanim)"
		set ppos [get_pos $attack_plant]
		set mpos [get_pos this]
		set angle [get_anglexz $ppos $mpos]
		if {$approached} {
			if {$approached==1} {
				set approached 2
				set attackanim [mp_pick attackanim {5 9} 5]
				set particledir [get_vectorxz $angle 0.02]
				lrep particledir 1 -0.02
				set particlepos [vector_add $ppos [vector_mul $particledir 15.0]]
				set_roty this [expr {$angle+1.57}]
				set_anim this raupe$rtyp.kriechen 0 $ANIM_ONCE
				state_disable this
				action this wait 0.$attackanim {
					set_anim this raupe$rtyp.kriechen $attackanim $ANIM_STILL
					action this wait 1 {
						state_enable this
					}
				}
			} else {
				call_method $attack_plant set_damage -0.03
				set_anim this raupe$rtyp.kriechen [expr {$attackanim-1}] $ANIM_STILL
				state_disable this
				action this wait 0.2 {
					create_particlesource 15 $particlepos $particledir 16 1
					add_attrib this atr_Hitpoints -0.05
					set_anim this raupe$rtyp.kriechen $attackanim $ANIM_STILL
					action this wait 1 {
						state_enable this
					}
				}
			}
		} else {
			if {abs([vector_dist3d $ppos $mpos]-0.55)<0.1} {
				log "Raupe: approach finished"
				set approached 1
				return
			}
			set place [vector_add $ppos [get_vectorxz $angle 0.55]]
			set angle [get_anglexz $mpos $ppos]
			set_roty this [expr {$angle-1.57}]
			move $place
			log "Raupe move to: $place"
		}
	}

}
