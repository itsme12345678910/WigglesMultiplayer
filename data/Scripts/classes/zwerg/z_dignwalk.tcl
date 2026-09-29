/// Rausgenommen aus den überlasteten z_work und z_procs
/// Abschnitt 1 : dig - Graben
/// Abschnitt 2 : walk - Gehen (weiter unten)
/// Abschnitt 3 : rotate - Drehen (noch weiter unten)


// ----------------------------------------------------------------------
//								Wrapper der Walk-Action
// ----------------------------------------------------------------------

// Löst eine Walk-Action auf dem aktuelle Zwerg aus
// !! niemand sollte das von Hand tun, falls es nicht unbedingt nötig ist !!
//
// syntax:	walk_action "paramstring" "finishcode optional" "breakcode optional" "erweiterte Parameter"
//
// paramstring wird direkt an die action übergeben
// erweiterte Parameter: finish- und breakcode muessen angegeben sein (notfalls leer ""):
//		-withbox		: mit kiste laufen, schnell laufen verbieten


proc walk_action {paramstring {finishcode ""} {breakcode ""} args} {
	global ANIMSET_STANDARDWALK     ANIMSET_RUN   				ANIMSET_WALKTIRED  	  	 	ANIMSET_SWIM			\
	global ANIMSET_WALKWITHPANNIER	ANIMSET_HAMSTERRIDE	  		ANIMSET_HOVERBOARD			ANIMSET_WALKWITHBOX		\
	global ANIMSET_SNEAK			ANIMSET_FLEE				ANIMSET_ZOMBIE				ANIMSET_DIVER
	global ANIMSET_SKIPPWALK        ANIMSET_DRUNKENWALK         ANIMSET_BARRELWALK			ANIMSET_WALKSTRIKE
	global is_wearing_divingbell	event_repeat				is_escaping

	// index des Speedtype-Parameters suchen und notfalls einen eintragen

	set speedidx [lsearch $paramstring "-speedtype"]
	if {$speedidx >= 0} {
		set speedidx [expr {$speedidx + 1}]
		set speedtype [lindex $paramstring $speedidx]
	} else {
		set paramstring [concat $paramstring " -speedtype 0"]
		set speedidx [expr {[llength $paramstring] -1}]
		set speedtype 0
	}
	// wenn wiederholtes Event, rennen
	if {$event_repeat} {
		set speedtype 2
		lrep paramstring $speedidx 2
	}

	// underwater animations

	if {$is_wearing_divingbell} {
		set dive $ANIMSET_DIVER
	} else {
		set dive $ANIMSET_SWIM
	}

	if {$is_escaping} {
		set fast $ANIMSET_FLEE
	} else {
		set fast $ANIMSET_RUN
	}

	// normal walk animations (short range)

	if {[get_attrib this atr_Alertness] < 0.5} {
		set slow $ANIMSET_WALKTIRED
		if {$speedtype != 2} {					;// falls nicht schnell laufen erzwungen wird, rennen verbieten
			set fast -1
		}
	} else {
		set slow $ANIMSET_STANDARDWALK
	}

	// fast movement animations (long range)

	catch {
    	if {[inv_find this "Hoverboard"] >= 0} {
    		set fast $ANIMSET_HOVERBOARD
    		if {$speedtype == 0  ||  $speedtype == 2} {
    			if {$event_repeat} {
    				lrep paramstring $speedidx 2						;// Hoverboard: Speedtype 2 da erzwungen schnell
    				set speedtype 2
    				set slow -1
    			} else {
    				lrep paramstring $speedidx 3						;// Hoverboard: Speedtype 3 (autodist)
    				set speedtype 3
    			}
    		}
    	} elseif {[inv_find this "Reithamster"] >= 0} {
    		set fast $ANIMSET_HAMSTERRIDE
    		if {$speedtype == 0  ||  $speedtype == 2} {
    			if {$event_repeat} {
    				lrep paramstring $speedidx 2						;// Reithamster: Speedtype 2 da erzwungen schnell
    				set speedtype 2
    				set slow -1
    			} else {
    				lrep paramstring $speedidx 3						;// Reithamster: Speedtype 3 (autodist)
    				set speedtype 3
    			}
    		}
    	}
    }
	// Sonderfall Kiepe

	if {[is_wearing_pannier this]} {
		set slow $ANIMSET_WALKWITHPANNIER
		if {$is_wearing_divingbell == 0} {
			set dive $ANIMSET_WALKWITHPANNIER
		}
		if {$fast == $ANIMSET_RUN} {
			set fast -1
		}
	}

	// zusätzliche Wünsche des Skripts berücksichtigen

	if {[lsearch $args "-withbox"] >= 0} {
		set slow $ANIMSET_WALKWITHBOX
		set fast -1
		set dive $ANIMSET_WALKWITHBOX
	}

	if {[state_get this]=="strike"} {
		set slow $ANIMSET_WALKSTRIKE
		set fast -1
		set dive $ANIMSET_WALKSTRIKE
	}

	set paramstring [concat $paramstring " -animsets \{$slow $fast $dive $ANIMSET_STANDARDWALK\}"]

	//log "WALK_ACTION: $paramstring"
	action this walk "$paramstring" $finishcode $breakcode
}


// ----------------------------------------------------------------------
//								Abschnitt 1 : Graben
// ----------------------------------------------------------------------

proc dig_starttask {startpos} {
	global current_digpose
	if {$startpos==0} {set current_digpos [get_pos this]} {global current_digpos}
	set startpos $current_digpos
	log "dig_starttask @ $startpos"
	log "mypos: [get_pos this]"

	gnome_announce_dig this $startpos
	set edgepos [get_digedge $startpos this]			;# Kante zum Anfangen finden
	log "Startedgepos: $edgepos"

	if {[vector_unpacky $edgepos]>0} {
		set originalz [lindex $edgepos 2]
		set walkpos [vector_fixdig $edgepos [get_pos this]]
		lrep walkpos 2 $originalz
		log "Startwalkpos: $walkpos"
		tasklist_add this "walk_pos_dig \{$walkpos\} \{$edgepos\}"
		tasklist_add this "dig_continue"
		set current_digpose ""
//		if {[inv_find this Presslufthammer]==-1} {
//			tasklist_add this "prod_changetool Spitzhacke"
//		} else {
//			tasklist_add this "prod_changetool Presslufthammer"
//		}
		return true
	} else {
		return false
	}
}

proc dig_check {pos {try 0}} {
	set x [lindex $pos 0]
	set y [lindex $pos 1]
	set cpos [vector_add [get_pos this] {0 -0.8 0}]
	set w [get_angle_num4 $pos $cpos]
	switch $w {
		0 {set xl {0.0 -1.0 1.0};set yl {-1.0 -1.0 -1.0}}
		1 {set xl {1.0 1.0 1.0};set yl {0.0 -1.0 1.0}}
		2 {set xl {0.0 -1.0 1.0};set yl {1.0 1.0 1.0}}
		3 {set xl {-1.0 -1.0 -1.0};set yl {0.0 -1.0 1.0}}
	}
	set freeneighbours 0
	for {set i 0} {$i<3} {incr i} {
		set h [get_hmap [expr $x+[lindex $xl $i]] [expr $y+[lindex $yl $i]]]
		if {$h<13} {incr freeneighbours}
	}
	if {$freeneighbours>1} {return 1} {return 0}
}

proc enable_digbrushes {own} {
	global tttexp_digbrush2 tttexp_digbrush3 tttexp_digbrush4
	if {[im_in_tutorial]} {return}
	set maxstones [gamestats attribmax $own exp_Stein]
	set maxreached 0
	for {set i 1} {$i<5} {} {
		if {$maxreached} {
			set_owner_attrib $own digenable$i 0
			incr i
		} else {
			set_owner_attrib $own digenable$i 1
			incr i
			if {$i==5} {break}
			if {$maxstones<[subst \$tttexp_digbrush$i]} {
				set maxreached 1
			}
		}
	}
}

proc dig_continue {{try 0}} {
	global current_time_plan current_worktask current_digpose current_tool_class
//	log "dig_continue"
	if { [get_remaining_sparetime this] == 0.0 || $current_worktask!="dig"} {
		if {$try>6} {dig_resetid this}
		if {[get_gnomeposition this] == 0} {set ground 1} {set ground 0}
		set cpos [get_pos this]
		set digpoint [vector_add [dig_next $cpos this $try] {0 0 -1}]
		//log "nextdigpoint: $digpoint"
		if {$ground&&[lindex $cpos 1]>[lindex $digpoint 1]&&[inv_find this Kristallstrahl]!=-1} {set laser 1} {set laser 0}
		if {$laser} {
			set oldtry $try
			set digdir [get_anglexz $cpos [vector_add $digpoint {0 0 -0.5}]]
			set olddir $digdir
			set oldpoint $digpoint
			set diff [expr {[get_roty this]-$digdir}]
			if {$diff<-3.14} {fincr diff 6.28} {if {$diff>3.14} {fincr diff -6.28}}
			while {abs($diff)>0.4&&$try<8} {
				incr try
				if {$try>6} {dig_resetid this}
				set digpoint [dig_next $cpos this $try]
				set digdir [get_anglexz $cpos $digpoint]
				set diff [expr {[get_roty this]-$digdir}]
				if {$diff<-3.14} {fincr diff 6.28} {if {$diff>3.14} {fincr diff -6.28}}
			}
			if {abs($diff)>0.4} {
				dig_resetid this
				set digpoint $oldpoint
				set try $oldtry
			}
		}
		gnome_announce_dig this $digpoint
		if {[vector_unpacky $digpoint]>0&&$try<9} {
			//log "dig_continue ($digpoint) $try $hastorotate"
			if {!$laser&&![dig_check $digpoint $try]} {dig_continue [expr $try + 1];return}
			// weitermachen
			set walkpos [vector_fixdig $digpoint [get_pos this]]
			//log "next digpoint: $digpoint (try $try) ($walkpos)"
			set nonewwalk 0.5
			if {$laser||[inv_find this Presslufthammer]==-1} {set airhammer 0} {set airhammer 1;set nonewwalk 1.1}
			set walkdist [vector_dist3d [get_pos this] $walkpos]
			if {$laser} {
				set nonewwalk 10.0
			}
			if {$walkdist > $nonewwalk} {
				dig_endanim 0
				tasklist_add this "walk_pos_dig \{$walkpos\} \{$digpoint\}"
				global walkfail_tasks
				incr try
				if {$try<8} {
					set walkfail_tasks "\"tasklist_clear this\" \"dig_continue $try\""
				} elseif {$try==8} {
					set walkfail_tasks "\"tasklist_clear this\" \"dig_starttask 0\""
				} else {
					set walkfail_tasks ""
				}
			}
			set toolchange 0
			if {$airhammer&&![string match {[wh]?} $current_digpose]} {
				if {[string match {l?} $current_digpose]} {dig_endanim}
				tasklist_add this "change_tool Presslufthammer"
				set toolchange 1
			} elseif {$laser&&![string match {l?} $current_digpose]} {
				if {[string match {[wh]?} $current_digpose]} {dig_endanim}
				tasklist_add this "change_tool Kristallstrahl"
				set toolchange 1
			} elseif {!$airhammer&&!$laser} {
				tasklist_add this "change_tool Spitzhacke"
			}
			if {$toolchange||[string first [string range $current_tool_class 0 4] "PressKrist"]!=-1} {
				tasklist_add this "change_tool 0 0 0"
			}
			tasklist_add this "dig_anim \{$digpoint\}"
			if {[tasklist_cnt this]} {
				set cmd [tasklist_get this 0]
				tasklist_rem this 0
				//log $cmd
				eval $cmd
			}
		} else {
			// Ende
		//	log "dig_notcontinue ($digpoint) $try $hastorotate"
			dig_endanim
			dig_resetid this
			state_triggerfresh this work_idle
			return true
		}
	}
}

proc dig_execute {digpoint} {
	global tttgain_dig tttinfluence_dig tttfailmax_dig current_digpose
	set digattr [get_attrib this exp_Stein]
	set minextrarange 3.0
	if {[string match {l?} $current_digpose]} {
		set laser 1
		set airhammer 1
	} else {
		set laser 0
		if {[inv_find this Presslufthammer]!=-1} {set airhammer 2} {
			set minextrarange 2.0
			set airhammer 1
			set digattr [expr {$digattr*0.5}]
		}
	}
	set thispos [vector_add [get_pos this] {0 -0.8 0}]
	set dig_z [lindex $digpoint 2]
	set digcount [expr [hmax 0.5 [expr sqrt($digattr*$tttinfluence_dig*$airhammer)]]]
	gnome_announce_dig this $digpoint
	while {$laser||[vector_dist $digpoint $thispos]<(3.0+$digattr*2.0)&&abs([lindex $digpoint 2]-$dig_z)<2} {
		if {$laser||rand()<$digcount*[get_material $digpoint]*0.7} {
			if {[dig_apply $digpoint this]} {
				for {set i 0} {$i<[llength $tttgain_dig]} {incr i} {
					set attr [lindex $tttgain_dig $i]
					set val [lindex $attr 1]
					set attr [lindex $attr 0]
					set val [expr {$val * [clan_exp_factor $attr]}]
					if {[llength $tttgain_dig]-$i==1} {
						add_expattrib this $attr $val
					} else {
						add_attrib this $attr $val
					}
				}
				if {[im_in_campaign]} {
					set rndval 0.01
				} else {
					set rndval 0.04
				}
				if {rand()<$rndval} {
					if {[im_in_campaign]} {
						set zone 0
						set UMK 0;set UTP 0; set UUM 0
						catch {set UMK [sm_get_event Uebergang_Met_Kris]}
						if {$UMK} {
							set zone 3
						} else {
							catch {set UTP [sm_get_event Titanic_Pumpe_aktiviert]}
							if {$UTP} {
								set zone 2
							} else {
								catch {set UUM [sm_get_event Uebergang_Urw_Met]}
								if {$UUM} {
									set zone 1
								}
							}
						}
					} else {
						global civ_state
						set zone [hmax 0 [hmin [expr {int($civ_state*10.0)}] 3]]
					}
					set mix [lindex {{0.0 1.1} {0.0 0.7 0.9 1.1} {0.0 0.5 0.66 0.94 1.1} {0.0 0.3 0.45 0.7 0.8 1.1}} $zone]
					set rnd [random]
					set idx -1
					foreach entry $mix {
						if {$rnd<$entry} {
							break
						} else {
							incr idx
						}
					}
					set cc [lindex {Stein Eisenerz Kohle Golderz Kristallerz} $idx]
					//log "($cc) $rnd $idx ($mix) $zone"
					sel /obj
					set present [new $cc "" $digpoint {0 0 0}]
					set_physic $present true
					set_autolight $present false
					set_owner $present -1
				}
			}
			if {$digattr<$tttfailmax_dig||$laser} {break}
			set digpoint [dig_next $thispos this 1 1]
			if {![dig_check $digpoint]} {break}
			set digcount [expr $digcount*0.5]
		} else {
			break
		}
	}
	return true
}

proc dig_anim {digpos {accident_possible 1}} {
	// log "dig anim mit accident: $accident_possible"
	global tttfailmax_dig current_digpose
	if {[inv_find this Presslufthammer]==-1} {set airhammer 0} {set airhammer 1}
	set digattr [get_attrib this exp_Stein]
	set animcnt [hmax [expr 4.8-$digattr*5.0] 1]
	if {[get_gnomeposition this] == 0} {
		// boden
		if {[inv_find this Kristallstrahl]==-1||[lindex $digpos 1]>[get_posy this]} {
			set animcnt [hf2i $animcnt]
			set accident 0
			if {$accident_possible} {
				set accident [hmax [expr {($tttfailmax_dig-$digattr)*5}] 0.0]
			}
			set height [expr [get_posy this]-[lindex $digpos 1]]
			if {$height>1.6} {
				set digpose 0								;# nach oben
			} elseif {$height>0.6} {
				set digpose 1								;# nach vorn
				set accident 0								;# keine Unfallanimation für vorne da
			} else {
				set digpose 2								;# nach unten
			}
			set dir [lindex {up front down} $digpose]
			if {$accident>0.0&&!$airhammer} {
				tasklist_addfront this "dig_anim \{$digpos\} 0"
				tasklist_addfront this "play_anim dig${dir}accident"
			} else {
				if {$airhammer} {
					if {$animcnt>1} {
						tasklist_addfront this "play_dig_anim_loop airhamm${dir} $animcnt \{$digpos\} $accident"
					} else {
						tasklist_addfront this "play_anim airhamm${dir}loop \{$digpos\}"
					}
				} else {
					tasklist_addfront this "play_anim dig${dir} \{$digpos\}"
				}
			}
			set cpos [vector_add [get_pos this] {0 -0.7 0}]
			set digdist [hmax [vector_dist3d $cpos $digpos] 0.1]
			set digdir [get_anglexz $cpos [vector_add $digpos {0 0 -0.5}]]
			set height [expr {[lindex $cpos 1]-0.7-[lindex $digpos 1]}]
			if {$height>0.8} {
				set digpose 0
			} elseif {$height>-0.1} {
				set digpose 1
			} else {
				set digpose 2
			}
			set diff [expr {[get_roty this]-$digdir}]
			if {$diff<-3.14} {fincr diff 6.28} {if {$diff>3.14} {fincr diff -6.28}}
			if {abs($diff)<0.3} {
				set_roty this $digdir
				set angle 0
			} else {
				set angle 1
			}
			if {$airhammer} {
				if {$angle} {
					tasklist_addfront this "change_tool 0 0 0;play_anim airhamm${dir}start"
					tasklist_addfront this "change_tool Presslufthammer 0 0;rotate_toangle $digdir"
					if {$current_digpose!=""} {
						set old [lindex {up front down} [string index $current_digpose 1]]
						tasklist_addfront this "play_anim airhamm${old}end"
					}
				} elseif {$current_digpose==""} {
					tasklist_addfront this "play_anim airhamm${dir}start"
				} else {
					set o [string index ufd [string index $current_digpose 1]]
					switch ${o}$digpose {
						"u1" {tasklist_addfront this "play_anim airhammu2f"}
						"u2" {
							tasklist_addfront this "play_anim airhammu2f"
							tasklist_addfront this "play_anim airhammf2d"
						}
						"d1" {tasklist_addfront this "play_anim airhammd2f"}
						"d0" {
							tasklist_addfront this "play_anim airhammd2f"
							tasklist_addfront this "play_anim airhammf2u"
						}
						"f0" {tasklist_addfront this "play_anim airhammf2u"}
						"f2" {tasklist_addfront this "play_anim airhammf2d"}
					}
				}
				set current_digpose h$digpose
			} elseif {$angle} {
				tasklist_addfront this "rotate_toangle $digdir"
			}
		} else {
			set cpos [vector_add [get_pos this] {0 -0.7 0}]
			set digdist [hmax [vector_dist3d $cpos $digpos] 0.1]
			set digdir [get_anglexz $cpos $digpos]
			set diff [expr {[get_roty this]-$digdir}]
			if {$diff<-3.14} {fincr diff 6.28} {if {$diff>3.14} {fincr diff -6.28}}
			if {abs($diff)<0.4} {
				set_roty this $digdir
				set rotate 0
			} else {
				set rotate 1
			}
			if {([get_posy this]-0.7-[lindex $digpos 1])/$digdist>0.7} {
				set digpose "l0"
				set diganim mann.laserbohrer_oben_loop
			} else {
				set digpose "l1"
				set diganim mann.laserbohrer_vorne_loop
			}
			//log "dp $digpose ($digpos) ($cpos)"
			set animcnt [hmax [expr {$animcnt-1.5}] 1]
			set animcnt [expr {int($animcnt*1.6)*0.8}]
			if {$current_digpose==$digpose&&!$rotate} {
				tasklist_addfront this "wait_time_dig $animcnt \{$digpos\};laser this 12 \{$digpos\} [expr {$animcnt+0.5}]"
			} else {
				tasklist_addfront this "play_anim_time $diganim $animcnt \{$digpos\};laser this 12 \{$digpos\} [expr {$animcnt+0.5}]"
				if {$rotate} {
					set new [string map {l0 up l1 fr} $digpose]
					tasklist_addfront this "change_tool 0 0 0;play_anim laserdrill${new}start"
					tasklist_addfront this "change_tool Kristallstrahl 0 0;rotate_toangle $digdir"
					set old [string map {l0 up l1 fr} $current_digpose]
					if {$old!=""} {tasklist_addfront this "play_anim laserdrill${old}stop"}
				} else {
					switch ${digpose}$current_digpose {
						"l0" {tasklist_addfront this "play_anim laserdrillupstart"}
						"l0l1" {tasklist_addfront this "play_anim laserdrillfr2up"}
						"l1l0" {tasklist_addfront this "play_anim laserdrillup2fr"}
						"l1" {tasklist_addfront this "play_anim laserdrillfrstart"}
					}
				}
			}
			set current_digpose $digpose
		}
	} else {
		// wand
		set digpose [get_angle_num4 [get_pos this] $digpos]
		if {$airhammer} {
			set dir [string index urdl $digpose]
			tasklist_addfront this "play_dig_anim_loop airhammwall$dir $animcnt \{$digpos\}"
			if {$current_digpose==""} {
				tasklist_addfront this "play_anim airhammwall${dir}start"
			} else {
				set o [string index urdl [string index $current_digpose 1]]
				if {[string first $o "lurd"]>[string first $dir "lurd"]} {
					set lut {l u u r r d}
				} else {
					set lut {d r r u u l}
				}
				while {$o!=$dir} {
					set next [string map $lut $dir]
					tasklist_addfront this "play_anim airhammwall${next}2$dir"
					set dir $next
				}
			}
			set current_digpose w$digpose
		} else {
			set dir [lindex {up right down left} $digpose]
			tasklist_addfront this "play_anim digclimb$dir \{$digpos\}"
		}
		if {abs([get_roty this]-3.14)>0.3} {
			tasklist_addfront this "rotate_toback"
		}
	}
	if {[tasklist_cnt this]} {
		set cmd [tasklist_get this 0]
		tasklist_rem this 0
		//log $cmd
		eval $cmd
	}
	return true
}

proc dig_endanim {{toolchange 1}} {
	global current_digpose
	set tool 0
	switch [string index $current_digpose 0] {
		"l" {
			tasklist_add this "play_anim laserdrill[lindex {up fr} [string index $current_digpose 1]]stop"
			set tool 2
		}
		"w" {
			tasklist_add this "play_anim airhammwall[string index urdl [string index $current_digpose 1]]end"
			set tool 1
		}
		"h" {
			tasklist_add this "play_anim airhamm[lindex {up front down} [string index $current_digpose 1]]end"
			set tool 1
		}
	}
	if {$tool} {
		tasklist_add this "change_tool [lindex {"" Presslufthammer Kristallstrahl} $tool] 0 0"
		if {$toolchange} {
			tasklist_add this "change_tool 0"
		}
	}
	set current_digpose ""
}

proc work_dig {digpos} {
//	log "i'm walking..."
	tasklist_add this "walk_pos $digpos"
}

// ----------------------------------------------------------------------
//								Abschnitt 2 : Gehen
// ----------------------------------------------------------------------

proc walk_pos {pos {force 0}} {
    //log "WALK - POS [get_objname this]"
	beam_back
	note_pathlength $pos
	state_disable this
//	log "[get_objname this]: state_disable für walkpos..."
	set pos [vector_fix $pos]
	if {$force} {set force "-forcetarget $force"} {set force "-forcetarget 0"}
	walk_action "-target \{$pos\} -waving 1 $force" {
		walkfail
	} {
		//log "[get_objname this]: walk break"
	}
	return true
}


proc walk_pos_with_box {pos} {
	beam_back
	note_pathlength $pos
	state_disable this
//	log "[get_objname this]: state_disable für walkpos..."
	set pos [vector_fix $pos]
	walk_action "-target \{$pos\} -forcetarget 0 -canclimb 0" {
		walkfail
	} {
		log "[get_objname this]: walk_with_box break"
	} "-withbox"
	return true
}

proc run_pos {pos {force 0}} {
	beam_back
	note_pathlength $pos
	state_disable this
	set pos [vector_fix $pos]
	if {$force} {set force "-forcetarget $force"} {set force "-forcetarget 0"}
	walk_action "-target \{$pos\} -waving 1 -speedtype 2 $force" {
		walkfail
	} {
		//log "[get_objname this]: walk break"
	}
	return true
}

proc run_away {{pos "auto"}} {
	global is_escaping
	beam_back

	if { $pos == "auto" } {
		set pos [calc_escape_pos]
	}

	// Fail
	if { $pos == 0 } { return }

	// Zu nahe (3 Meter)
	set dist [vector_dist3d $pos [get_pos this]]
	if { $dist < 3 } { log "zu nah"; return }

	//if { [get_walkresult this] != 4 } { return }

	state_disable this
	set pos [vector_fix $pos]
	set is_escaping 1
	if { [lindex $pos 0] == -1 } {
		walk_action "-randompath [irandom 4 10] -waving 0 -speedtype 2 " { set is_escaping 0 ; state_enable this ; run_away } { set is_escaping 0 ; tasklist_add this "run_away" }
	} else {
		walk_action "-target \{$pos\} -waving 0 -speedtype 2 " { set is_escaping 0 ; state_enable this ; run_away } { set is_escaping 0 ; tasklist_add this "run_away" }
	}
	return true
}

proc run_pos_obj {pos obj {dist 1.8}} {
    global fight_run_pos fight_last_dist attack_item
    beam_back
	set animset 256
	set pose [get_weapon_pose [get_weapon_class this]]

	set fight_last_dist [vector_dist3d $pos [get_pos this]]

	switch { $pose } {
		"normal" 	{set animset 256}
		"kungfu" 	{set animset 256}
		"sword" 	{set animset 257}
		"twohand" 	{set animset 258}
		"ballistic"	{set animset 256}
	}


	state_disable this
	set pos [vector_fix $pos]
	set fight_run_pos [get_pos $obj]
	note_pathlength $pos

	if { $obj != $attack_item } {
	    action this walk "-target \{$pos\} -animsets $animset" "state_enable this"
	} else {
		set objdist [vector_dist3d $pos [get_pos this]]
		set timing 15
		if { $objdist < 4 } {
			set timing 3
		} elseif { $objdist < 8 } {
			set timing 6
		} elseif { $objdist < 10 } {
			set timing 9
		}

		action this walk "-target \{$pos\} -dontstop 1 -animsets $animset -walktimercallback fight_walk_timer_callback -walktimercounter $timing" "state_enable this;set_fight_idleanim"
	}

	return true
}


proc walk_pos_dig {pos dpos} {
	state_disable this
//	log "[get_objname this]: state_disable für walkpos..."
//	log "DIG_VERSUCHE = $dig_versuche"
	set pos [vector_fix $pos]
	if {[get_gnomeposition this]&&[get_hmap [lindex $pos 0] [lindex $pos 1]]<12} {
		set speed "-speedtype 2"
	} else {
		set speed ""
	}
	walk_action "-target \{$pos\} -waving 0 -dig 1 -digpos \{$dpos\} $speed" {
		walkfail
		return true
	} {
		//log "[get_objname this]: walk break"
	}
	return true
}

proc walk_random {plength} {
	set place [get_place -center [get_pos this] -circle $plength -mindist 0.7 -random $plength -walldist 1]
	if {[lindex $place 0]<1} {return false}
	walk_pos $place
	return true
}



// läuft in die Nähe eines Items (oder eines Punktes)

proc walk_near_item {item radius {tolerance 0.1} {speedtype auto}} {
	//log "WALK NEAR ITEM [get_objname this] pos: $item radius: $radius"
	set thispos [get_pos this]

    // Ziel ist entweder ein Item oder ein Vektor
	if {[llength $item]==1} {
		if {[obj_valid $item] == 0} {
			return false
		}
	    set itempos [get_posbottom $item]
	} else {
	    set itempos $item
	}

	//log "walk_near_item: itempos: $itempos"


    // falls wir schon nah genug dran sind ist nichts zu tun
	if {[vector_dist3d $thispos $itempos]-$radius <= $tolerance} {
//		log "WALK NEAR ITEM 1. Ausstieg"
//    	log "thispos:   $thispos"
//    	log "itempos:   $itempos"
//    	log "dist:      [vector_dist3d $thispos $itempos]"
//    	log "radius:    $radius"
//    	log "tolerance: $tolerance"
	    return true
	}

    // Position zum Hinlaufen ermitteln
	set walkpos [vector_fix [get_place -center $itempos -nearpos $thispos -mindist $radius -circle [expr $radius +2] -except this]]
	//log "$walkpos"
	if {[lindex $walkpos 0]<0} {
        // fehlgeschlagen - 2. Versuch ohne Materials
		log "walk_near_item: get_place 1 failed"
   		set walkpos [vector_fix [get_place -center $itempos -nearpos $thispos -mindist $radius -circle [expr $radius +2] -except this -materials false]]
		//log "$walkpos"
    	if {[lindex $walkpos 0]<0} {
			log "walk_near_item: get_place 2 failed - last fallback is vector_fix!"
	        // immernoch fehlgeschlagen - evtl. ein Objekt an der Wand... auf Landscape gefixte Itempos
			set walkpos [vector_fix $itempos]
   		}
   	}
	note_pathlength $walkpos

    // falls wir schon nahe genug dran sind, ist nichts zu tun
	if {[vector_dist3d $thispos $walkpos]<$tolerance} {
//		log "WALK NEAR ITEM 2. Ausstieg"
//    	log "thispos:   $thispos"
//    	log "itempos:   $itempos"
//    	log "walkpos:   $walkpos"
//    	log "dist:      [vector_dist3d $thispos $itempos]"
//    	log "radius:    $radius"
//    	log "tolerance: $tolerance"
	    return true
	}
	
	// falls das Ziel vor dem Zwerg in der Luft schwebt
	if {[get_gnomeposition this]&&[lindex $thispos 2]<[lindex $walkpos 2]+2&&[vector_dist $thispos $walkpos]<=2.0} {
	//	log "WALK NEAR ITEM 3. Ausstieg - Wand (unerreichbar)"
		return true
	}

	if {$speedtype=="auto"} {
	    set speed ""
	} else {
	    set speed "-speedtype $speedtype"
	}

	//log "walk_near_item: currentpos: $thispos walkpos: $walkpos"

	state_disable this
	walk_action "-target \{$walkpos\} $speed" {
		walkfail
	} {
		//log "[get_objname this]: walk break"
	}
}


proc walk_dummy {item dummy {speed 0}} {
	if {[obj_valid $item] == 0} {
		return false
	}
	state_disable this
	note_pathlength [vector_add [get_pos $item] [get_linkpos $item $dummy]]
	walk_action "-object $item -dummy $dummy -speedtype $speed" {
		walkfail
	} {
		//log "walk break"
#		state_enable this
	}
	return true
}


proc walk_dummy_with_box {item dummy {speed 0}} {
	if {[obj_valid $item] == 0} {
		return false
	}
	state_disable this
	note_pathlength [vector_add [get_pos $item] [get_linkpos $item $dummy]]
	//log "walk-action with box"
	walk_action "-object $item -dummy $dummy -speedtype $speed -canclimb 0" {
		walkfail
	} {
		log "walk with box break"
	} "-withbox"
	return true
}


proc walk_outoftransit {} {
	set vPos [get_pos this]
	if { [vector_unpackz $vPos]>13 } {
		walk_pos [vector_add [vector_setz $vPos 13] {0.2 0 0}]
	}
	return true
}


proc walk_down_from_wall {} {
	set found 0
	for {set range 5} {$range<51} {incr range 5} {
		set groundpos [get_place_long [get_pos this] $range 1 1]
		if {[lindex $groundpos 0]>1} {
			if {![isunderwater $groundpos]} {
				set found 1
				break
			}
		}
	}
	if {!$found} {return 1}
	log "Found Groundpos: $groundpos ([isunderwater $groundpos])"
	global myref walkfail_tasks
	set walkpos [get_place -center $groundpos -rect -4 -8 4 8 -except this -placelockidexcept $myref]
	if {[lindex $walkpos 0]>0} {
		log "walk down to $walkpos"
		tasklist_add this "walk_pos \{$walkpos\}"
		set walkfail_tasks {{set walkfail_tasks "";wait_time 2}}
		return 0
	}
	log "[get_objname this]: No groundpos found!"
	return 1
}

proc walk_free {} {

}

proc walk_around {} {
	tasklist_add this "walk_random [irandom 2 4]"
	tasklist_add this "adjust_gnome_rotation"
}

proc walk_near_hamster {item} {
	if {![obj_valid $item]} {
		return false
	}

	set rng [call_method $item get_scanrange]
	set opos [get_pos this]
	set ipos [get_pos $item]
	set dist [vector_abs [vector_sub $opos $ipos]]
	if { $dist <= $rng + 2 } {return}
	set newpos [get_place -center $ipos -circle [expr $rng + 5] -mindist [expr $rng + 0.5] -nearpos $opos]
	if { [lindex $newpos 0] == -1 } {
		tasklist_clear this
		gnome_failed_work this
		state_trigger this idle
		return
	}
	walk_pos $newpos
}


proc walkfail {} {
	global walkfail_tasks myref
	placelock_rem $myref
	if { [catch { set walkfail_tasks }] } {
		set walkfail_tasks ""
	}
	if {4 != [get_walkresult this ] } {
		if {$walkfail_tasks==""} {
			log "[get_objname this]: walk not successful"
			tasklist_clear this
			kill_all_ghosts
			stop_prod
			gnome_failed_work this
			state_triggerfresh this idle
		} else {
			log "[get_objname this]: walkretry ($walkfail_tasks)"
			foreach entry $walkfail_tasks {
				eval $entry
			}
			state_enable this
		}
	} else {
		set walkfail_tasks ""
		state_enable this
	}
}

proc note_pathlength {pos {lock 1}} {
	if {[lindex $pos 0]<1} {return}
	global planned_pathlength myref
	set pathlength [expr abs([get_posx this]-[lindex $pos 0])+abs([get_posy this]-[lindex $pos 1])]
	if {$lock} {
		// log "locking place for walk ($pos) for [get_objname this] ($myref) ($pathlength *2)"
		placelock_set $pos [expr $pathlength*2] $myref} {log "not locking walk"}
	if {$pathlength > 5} {fincr planned_pathlength $pathlength}
}

// ----------------------------------------------------------------------
//								Abschnitt 3 : Drehen
// ----------------------------------------------------------------------

proc rotate_toright {} {state_disable this;action this rotate 4.71 {state_enable this}}
proc rotate_toleft {} {state_disable this;action this rotate 1.57 {state_enable this}}
proc rotate_toback {} {state_disable this;action this rotate 3.14 {state_enable this}}
proc rotate_tofront {} {state_disable this;action this rotate 0 {state_enable this}}

proc rotate_to {dir} {
	switch $dir {
		right
			{rotate_toright}
		left
			{rotate_toleft}
		front
			{rotate_tofront}
		back
			{rotate_toback}
		default
			{rotate_tofront}
	}
}

proc rotate_towards {item {direction 0}} {
	if {[get_gnomeposition this]} {return}
	//log "rotate_towards: ($item)"
	if {[llength $item]==1} {
		if {![obj_valid $item]} {
			return false
		}
			set itempos [get_pos $item]
	} else {
		set itempos $item
	}
	set angle [vector_angle "[lindex $itempos 0] 0 [expr [lindex $itempos 2]*0.5]" "[get_posx this] 0 [expr [get_posz this]*0.5]"]
	if {$direction} {fincr angle 1.57} {fincr angle -1.57}
	if {$angle<0.0} {fincr angle 6.2832}
	if {$angle>6.2832} {fincr angle -6.2832}
	// log "rotate: ($direction) $angle ([get_rot this])"
	set myangle [get_roty this]
	if {abs($angle-$myangle)<0.05||abs($angle-$myangle-6.28)<0.05} {return true}
	state_disable this
	action this rotate $angle {state_enable this} {}
	return true
}


proc rotate_towards_pos {pos} {
	state_disable this
	action this rotate [expr 1.57+[vector_angle [get_pos this] $pos]] {state_enable this}
	return true
}


proc rotate_towards_with_box {item {direction 0}} {
//	log "rotate_towards_with_box"
	global ANIMSET_WALKWITHBOX
	if {[get_gnomeposition this]} {return}
	if {[llength $item]==1} {
		if {![obj_valid $item]} {
			return false
		}
			set itempos [get_pos $item]
	} else {
		set itempos $item
	}
	set angle [vector_angle "[lindex $itempos 0] 0 [expr [lindex $itempos 2]*0.5]" "[get_posx this] 0 [expr [get_posz this]*0.5]"]
	if {$direction} {fincr angle 1.57} {fincr angle -1.57}
	if {$angle<0.0} {fincr angle 6.2832}
	if {$angle>6.2832} {fincr angle -6.2832}
//  log "rotate: ($direction) $angle"
	state_disable this;
	action this rotate "$angle $ANIMSET_WALKWITHBOX" {state_enable this}
	return true
}


proc rotate_toclock {clock} {
	set degree [expr 3.14159 + ( $clock * 0.5236 ) ]
	state_disable this;
	action this rotate $degree {state_enable this}
	return true
}

proc rotate_toangle {angle {anim ""}} {
	state_disable this;
	if {$anim==""} {
		action this rotate $angle {state_enable this}
	} else {
		action this rotate "$angle $anim" {state_enable this}
	}
	return true
}

proc adjust_gnome_rotation {} {
	set roty [get_roty this]
	if {abs($roty)>1.2} {
		tasklist_add this "rotate_tofront"
	}
}

proc walk_out_of {item} {
	set bbox [check_ghost_coll bbox this $item]
	if { $bbox != 0 } {
		set opos [get_pos this]
		set bbn [lindex $bbox 0]
		set bbp [lindex $bbox 1]
		if { [vector_inbox $opos $bbn $bbp] } {
			set xn [expr [lindex $bbn 0] - [lindex $opos 0]-1]
			set xp [expr [lindex $bbp 0] - [lindex $opos 0]+1]
			set zn [expr [lindex $bbn 2] - [lindex $opos 2]-2]
			set zp [expr [lindex $bbp 2] - [lindex $opos 2]+2]
			set XP [expr $xp + 8]
			set XN [expr $xn - 8]
			set ZP [expr $zp + 0]
			set ZN [expr $zn - 8]
			set pos [get_place -center $opos -rect $XN $ZN $XP $ZP -clip $xn $zn $xp $zp -placelock 5]
			if { [lindex $pos 0] == -1 } {
				log "get_place has found no place !!! in proc 'walk_out_of'"
				walk_pos "[get_posx this] [get_posy this] 14"
			} else {
				walk_pos $pos
			}
		} else {
		}
	} else {
	}
	return 1
}

//return values: 0 - fail   1 - success  2 - no need
proc fight_rotate_towards {} {
	global attack_item
	if {[get_gnomeposition this]} {
		return 2
	}
//	if {[llength $attack_item]==1} {
		if {![obj_valid $attack_item]} {
			return 0
		}
		set itempos [get_pos $attack_item]
//	} else {
//		set itempos $attack_item
//	}
	//log "*** '$itempos' of $attack_item"
	set angle [vector_angle "[lindex $itempos 0] 0 [expr [lindex $itempos 2]*0.5]" "[get_posx this] 0 [expr [get_posz this]*0.5]"]
	fincr angle -1.57
	if {$angle<0.0} {fincr angle 6.2832}
	if {$angle>6.2832} {fincr angle -6.2832}
	set myangle [get_roty this]
	//log "-- abs($angle-$myangle)<0.05||abs($angle-$myangle-6.28)<0.05 ([expr abs($angle-$myangle)] / [expr abs($angle-$myangle-6.28)]"
	if { abs($angle-$myangle)<0.005 || abs($angle-$myangle-6.28)<0.005 } {
		return 2
	}

	set animset 0
	set pose [get_weapon_pose [get_weapon_class this]]
	switch { $pose } {
		"normal" 	{set animset 256}
		"kungfu" 	{set animset 256}
		"sword" 	{set animset 257}
		"twohand" 	{set animset 258}
		"ballistic"	{set animset 2}
	}

	state_disable this
	action this rotate "$angle $animset" {state_enable this} {}
	return 1
}

