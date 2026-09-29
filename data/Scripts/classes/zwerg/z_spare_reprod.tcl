// z_reprod.tcl

if {[in_class_def]} {

	state_enter reprod {
		if {$state_log} {log "[get_objname this] entering state REPROD (occup_ends, inits for reprod)"}
		if {$state_shell} {print "[get_objname this] entering state REPROD (occup_ends, inits for reprod)"}
		switch $current_occupation {
			"slp" { sparetime_slp_end }
			"eat" { sparetime_eat_end }
			"bth" { sparetime_bth_end }
			"fun" { sparetime_fun_end }
		}
		set reprod_actioncount 0
		set reprod_actionlock 0
		set sparetime_popplace "0.0 0.0 0.0"
		set current_occupation "reprod"
		set reprod_trapped_cnt 0
	}
		
	state reprod {
		if {$state_log} {log "[get_objname this] passing state code REPROD"}
		if {$state_shell} {print "[get_objname this] passing state code REPROD"}
		if { [tasklist_cnt this] > 0 } {
			set command [tasklist_get this 0]
			tasklist_rem this 0
//			log "reprod:$command"
			eval $command
			return
		}
		if {$reprod_actioncount!=5&&($reprod_trapped_cnt>100||![obj_valid $reprod_partner]||!([state_get $reprod_partner]=="reprod"||[call_method $reprod_partner reprod_remote_act 1]))} {
			tasklist_clear this
			state_triggerfresh this sparetime_dispatch
			return
		}
		incr reprod_trapped_cnt
//		if {$gnome_gender=="male"} {return}
		sparetime_reprod_loop
	}

	method reprod_syncaction {acount} {
		set reprod_actioncount $acount
	}

	method reprod_getactioncount {} {
		return $reprod_actioncount
	}

	method reprod_getpregnancy {} {
		return $reprod_pregnancy
	}

	method reprod_remote_act {argument} {
		if {$argument} {
			return $reprod_actionlock
		} else {
			set reprod_actionlock 1
		}
	}

	method reprod_becomepartner {newpartner} {
		global reprod_partner
		sparetime_talkissue_delete "fli"
		sparetime_talkissue_delete "mnc"
		set reprod_partner $newpartner
		set reprod_timer 120
		set partner_preference_list ""
		partner_info setpartner this $newpartner
		partner_info setpartner $newpartner this
	}
	method reprod_removepartner {} {
		global reprod_partner 
		set reprod_partner 0
	}
	method get_reprodpartner {} {
		return $reprod_partner
	}
	method reprod_getpreferredpartner {} {
		return [get_preferredpartner]
	}
	method set_partner_preference {ref} {
		set partner_preference_list [list [list $ref 6000]]
	}
	
	method reprod_getpopplace {} {
		return $sparetime_popplace
	}
	
	method reprod_checkattribs {} {
		if { !$willing_to_reprod || $sparetime_emergency } {return 0}
		if {[get_remaining_sparetime this]<0.2} {
//			log "not enough time"
			return 0
		}
		return 1
	}
	
	method get_sex_desire {} {
		return $spt_sex_desire
	}
	
	method sparetime_prtn_greet {} {
		sparetime_prtn_relief
	}
	
	method disable_reprod {} {
		set reproducability 0
	}
	handle_event evt_zwerg_birth {
		lappend idle_action_list "bear_child [event_get this -num1]"
	}
	handle_event evt_zwerg_birth {
		bear_child [event_get this -num1] 1
	}

} else {
	
	set reprod_log 0

	set reprod_partner 0
	set reprod_timer 0
	set reprod_trapped_cnt 0
	set reprod_pregnancy 0
	set reprod_actioncount 0
	set reprod_actionlock 0
	set spt_last_sex 0.0
	set current_babies {}
	set partner_preference_list ""
	set sparetime_popplace "0.0 0.0 0.0"
	set reproducability 1
	set childrencount 0
	set reprod_parents_attribs ""
	set current_partnermuetze 0
	set reprod_hitcnt 0
	set reprod_hitrate 60.0
	set reprod_sexratio {0.5 0.001}

	proc sparetime_reprod_find_partner {} {
		global partner_preference_list gnome_gender reprod_partner love_potion_taken myref
		set list_old $partner_preference_list
		set gnome_list [lnand 0 [obj_query this "-class Zwerg -owner own -range 15"]]
		set fa1 [partner_info getfather this]
		set mo1 [partner_info getfather this]
		set mystart [get_worktime this start]
		set myend [get_worktime this end]
		foreach gnome $gnome_list {
			if {[get_objgender $gnome]!=$gnome_gender} {
				if {![call_method $gnome get_reprodpartner]} {
					if {$love_potion_taken} {
						set partner_preference_list [list [list $gnome 6000]]
						call_method $gnome set_partner_preference $myref
						set love_potion_taken 0
						break
					}
					if {[state_get $gnome]=="sparetime_dispatch"} {
						for {set i 0} {$i<[llength $partner_preference_list]} {incr i} {
							set entry [lindex $partner_preference_list $i]
							if {[lindex $entry 0]==$gnome} {
								set count [lindex $entry 1]
								if {$count<8000} {
									set relatives 0
									set fa2 [partner_info getfather $gnome]
									set mo2 [partner_info getfather $gnome]
									if {$fa1==$fa2&&$fa1!=0} {incr relatives 1}
									if {$mo1==$mo2&&$mo1!=0} {incr relatives 2}
									if {$fa1==$gnome} {incr relatives 4}
									if {$mo1==$gnome} {incr relatives 8}
									if {[get_ref this]==$fa2} {incr relatives 16}
									if {[get_ref this]==$mo2} {incr relatives 32}
									if {$relatives==0} {
										set incrcount 16
									} elseif {$relatives<3} {
										set incrcount 4
									} elseif {$relatives==3} {
										set incrcount 2
									} else {
										set incrcount 1
									}
									set otstart [get_worktime $gnome start]
									set diff1 [expr {$mystart-$otstart}]
									if {$diff1>6.0} {set diff1 [expr {6.0-$diff1}]}
									set otend [get_worktime $gnome end]
									set diff2 [expr {$myend-$otend}]
									if {$diff2>6.0} {set diff2 [expr {6.0-$diff2}]}
									incr count [expr {$incrcount*(12-int($diff1+$diff2))}]
									lrep partner_preference_list $i [list $gnome $count]
								}
								break
							}
						}
					}
					if {![string match "*\{$gnome*" $partner_preference_list]} {
						lappend partner_preference_list [list $gnome 0]
					}
				}
			}
		}
		set partner_preference_list [lsort -index 1 $partner_preference_list]
		set preferred [get_preferredpartner]
		if {$preferred!=""&&[call_method $preferred reprod_getpreferredpartner]==[get_ref this]} {
			call_method this reprod_becomepartner $preferred
			call_method $preferred reprod_becomepartner [get_ref this]
		}
	}
	
	proc get_preferredpartner {} {
		global reprod_partner partner_preference_list	
		if {$reprod_partner==0} {
			set i 0
			foreach potential_partner $partner_preference_list {
				if {[lindex $potential_partner 1]>5000} {
					set poparef [lindex $potential_partner 0]
					if {![obj_valid $poparef]} {
						lrem partner_preference_list $i
						continue
					}
					return $poparef
				}
			}
		}
		return ""
	}
	
	proc sparetime_reprod_check {} {
		global gnome_gender reprod_partner reproducability childrencount reprod_timer reprod_hitcnt
		global reprod_sexratio spt_sex_desire
		global reprod_log
		if {!$reproducability} {return false}
		if {$reprod_partner != 0} {
			if {![obj_valid $reprod_partner]} {
				set reprod_timer 120
				set reprod_partner 0
				sparetime_talkissue_delete "ttp"
			}	
		}
		if {$reprod_partner == 0} {
			sparetime_reprod_find_partner
			return false
		}
		switch $gnome_gender {
			"male" {
				global reprod_actionlock
				if {$reprod_actionlock} {
					if {[state_get $reprod_partner]=="reprod"} {
						log "[get_objname this] reprodcheck male returns true ---------------"
						return true
					} else {
						set reprod_actionlock 0
					}
				} else {
				//log "[get_objname this] reprodcheck male returns false ([state_get $reprod_partner]) ------------"
				}
				return false
			}
			"female" {
				global current_occupation current_babies reprod_pregnancy reprod_timer
				global willing_to_reprod sparetime_emergency fertility_potion_taken is_old
				if {!$fertility_potion_taken&&$is_old} {return false}
				foreach baby $current_babies {
					if {![obj_valid $baby]} {
						set $current_babies [lnand $baby $current_babies]
					}
				}
				if {[get_gnomeposition $reprod_partner]==1} {return false}
				if {[state_get $reprod_partner]!="sparetime_dispatch"} {return false}
				if {[dist_between this $reprod_partner]>10} {
					if {$reprod_log} {log "Partner too far: [get_objname this] returns false ([vector_dist [get_pos this] [get_pos $reprod_partner]]) -----------------"}
					return false
				}
				if {![string match "*[call_method $reprod_partner get_current_occupation]${current_occupation}*" "fillfunfunfillslpslpfillfill"]} {
					if {$reprod_log} {log "Occupations differ: [get_objname this] returns false ([call_method $reprod_partner get_current_occupation]${current_occupation}) ---------"}
					return false
				}
				if {[call_method this reprod_checkattribs $current_occupation]&&[call_method $reprod_partner reprod_checkattribs $current_occupation]} {
					incr reprod_hitcnt 1
					if {$reprod_pregnancy} {return false}
					if {[llength $current_babies]>1} {
						if {$reprod_log} {log "Too many Babies: [get_objname this] returns false -------------"}
					}
					if { $reprod_timer < 30 } {
						incr reprod_timer
						if {$reprod_log} {log "Reprod_timer not enough: [get_objname this] returns false ($reprod_timer) -------------"}
						return false
					}
					set myhitp [get_attrib this atr_Hitpoints]
					set othitp [get_attrib $reprod_partner atr_Hitpoints]
					if {$myhitp<0.3||$othitp<0.3} {return false}
					set rnd [expr {rand()}]
					set mynutri [get_attrib this atr_Nutrition]
					set otnutri [get_attrib $reprod_partner atr_Nutrition]
					set mymood [get_attrib this atr_Mood]
					set otmood [get_attrib $reprod_partner atr_Mood]
					set otdesire [call_method $reprod_partner get_sex_desire]
					if {$fertility_potion_taken} {
						set val 1.1
					} else {
						set val [expr {pow($myhitp*$othitp*$mynutri*$otnutri*$mymood*$otmood,2)*[lindex $reprod_sexratio 1]*$spt_sex_desire*$otdesire*0.0001}]
					}
					if {$rnd>$val} {
						if {$reprod_log} {log "Bad attribs: ($val) [get_objname this] returns false ($rnd)----- $reprod_sexratio"}
						return false
					} else {
						if {$reprod_log} {log "RANDOM MADE: ($rnd) $val"}
					}
				} else {
					return false
				}
			}
		}
		log "[get_objname this] female reprodcheck returned true --------------"
		return true
	}
	
	proc sparetime_check_prtn {{checkrange 1}} {
		global reprod_partner sparetime_current_place_ref talk_partner
		global current_occupation sparetime_fun_mode gnome_gender
		if {!$reprod_partner} {
			foreach tp $talk_partner {
				if {[obj_valid $tp]&&$gnome_gender!=[call_method $tp get_gender]} {
					sparetime_prtn_relief
					return
				}
			}
			return
		}
		if {$gnome_gender=="male"} {return}
		if {$checkrange} {
			if {[dist_between this $reprod_partner]<10} {
				set near 1
			} else {
				set near 0
			}
		} else {
			set near 1
		}
		if {$near} {
			//set prtn 0
			//set op [call_method $reprod_partner get_sparetime_place]
			//if {$op&&$op==$sparetime_current_place_ref} {
			//	set prtn 1
			//} elseif {[state_get this]=="reprod"&&[state_get $reprod_partner]=="reprod"} {
			//	set prtn 1
			//} elseif {[land $reprod_partner $talk_partner]!=""} {
			//	set prtn 1
			//}
			if {$current_occupation==[call_method $reprod_partner get_current_occupation]} {
				if {$sparetime_fun_mode==[call_method $reprod_partner get_fun_mode]} {
					sparetime_prtn_relief
					call_method $reprod_partner sparetime_prtn_greet
				}
			}
		}
	}
	
	proc sparetime_prtn_relief {} {
		sparetime_talkissue_delete "ttp"
		sparetime_fun_entry "prtn"
	}
					
	proc sparetime_reprod_loop {} {
		global reprod_actioncount reprod_partner reprod_pregnancy gnome_gender
		global sparetime_popplace myref spt_last_sex reprod_sexratio fertility_potion_taken
		log "[get_objname this] reprod $reprod_actioncount"
		switch $reprod_actioncount {
			0 {
				sparetime_check_prtn 0
				if {$gnome_gender=="female"} {
					//Sexanimation festlegen
					global sparetime_sexanim
					set sparetime_sexanim sexfloor[string index ab [irandom 2]]
					//Nur Frauen: popplace aussuchen
					set mypos [get_pos this]
					set hispos [get_pos $reprod_partner]
					if {abs([vector_dist3d $mypos $hispos]-0.9)<0.2} {
						if {[obj_query this "-class \{Feuerstelle Zelt\} -owner own -range 2 -flagneg boxed -limit 1"]||[get_posz this]<10} {
							set sparetime_popplace $mypos
							ref_set $reprod_partner sparetime_popplace $hispos
							call_method $reprod_partner reprod_syncaction 2
							incr reprod_actioncount 2
							return
						}
					}
					set prodlist [obj_query this "-class \{Feuerstelle Zelt\} -range 7 -flagneg boxed -owner own"]
					if {$prodlist==0} {set prodlist ""}
					foreach prod_place $prodlist {
						set sparetime_popplace [get_place -center [get_pos $prod_place] -rect -3 -5 3 5 -except this -placelockidexcept $myref]
						if {[lindex $sparetime_popplace 0]>1} {break}
					}
					if {[lindex $sparetime_popplace 0]<1} {
						set sparetime_popplace [get_place -center [vector_add [get_pos this] {0 0 -15}] -circle 10 -except this -placelockidexcept $myref]
					}
					if {[lindex $sparetime_popplace 0]<1} {
						set sparetime_popplace [get_pos this]
					}
				} else {
				//Wenn bereits popplace festgelegt
					if {[lindex $sparetime_popplace 0]<1} {
						//Männer: Frauen fragen, wo
						set herpp [call_method $reprod_partner reprod_getpopplace]
						set sparetime_popplace [get_place -center $herpp -mindist 0.8 -circle 5 -except this -placelockidexcept $myref]
					}
				}
				//set sparetime_popplace [vector_fix $sparetime_popplace]
				//log "fixed $vorher -> $sparetime_popplace"
				if {[lindex $sparetime_popplace 0]<1} {log "[get_objname this] stpp failed";return}
				incr reprod_actioncount
				shortlock_pos $sparetime_popplace
				return
				// rac=1
			}
			1 {
				set mypos [get_pos this]
				set othpos [get_pos $reprod_partner]
				set mydist [vector_dist3d $mypos $sparetime_popplace]
				//if {abs([vector_dist3d $mypos $othpos]-0.9)<0.2} {
				//	incr reprod_actioncount
				//	return
				//}
				//Wenn Partner hat noch den weiteren Weg, idleanims. Sonst zum popplace laufen. rac=0
				set othpp [call_method $reprod_partner reprod_getpopplace]
				set othdist [vector_dist3d $othpos $othpp]
				log "[get_objname this] mp $mypos op $othpos md $mydist od $othdist mpp $sparetime_popplace opp $othpp"
				if {$othdist>$mydist} {
					play_anim [lindex {standloopa standloopb standloopc standloopd jumpa scratch breathe teeter_t wait scout wipenose cough teeter_w kneebend} [irandom 14]]
				} else {
					if {$mydist>0.3} {
						tasklist_add this "walk_pos \{$sparetime_popplace\} 1"
					} elseif {$othdist<0.3} {
						incr reprod_actioncount
						call_method  $reprod_partner reprod_syncaction 2
					} elseif {[call_method $reprod_partner reprod_getactioncount]>1} {
						incr reprod_actioncount
					} else {
						play_anim [lindex {standloopa standloopb standloopc standloopd jumpa scratch breathe teeter_t wait scout wipenose cough teeter_w kneebend} [irandom 14]]
					}
				}
				return
			}
			2 {
				//Wenn Partner soweit, dreh dich zu ihm. rac=3
				if {[call_method $reprod_partner reprod_getactioncount]>1} {
					rotate_towards $reprod_partner
					incr reprod_actioncount
				}
				return
			}
			3 {
				global reprod_trapped_cnt
				if {$gnome_gender=="female"} {
					//Frauen: Winkel überprüfen, wenn o.k., beide auf rac=4
					if {$reprod_trapped_cnt<50} {set critical 0.15} elseif {$reprod_trapped_cnt<70} {set critical 0.8} else {set critical 3.2}
					if {abs(abs(abs([get_roty this]-[get_roty $reprod_partner])-1.57)-1.57)<$critical} {
						incr reprod_actioncount
						call_method $reprod_partner reprod_syncaction 4
						return
					}
				}
				rotate_towards $reprod_partner
				return
			}
			4 {
				if {$gnome_gender=="male"} {
					set sparetime_sexanim [ref_get $reprod_partner sparetime_sexanim]
				} else {
					global sparetime_sexanim
				}
				log "[get_objname this]: $sparetime_sexanim (anim)"
				tasklist_add this "play_anim ${sparetime_sexanim}start"
				tasklist_add this "play_anim ${sparetime_sexanim}loop"
				tasklist_add this "play_anim ${sparetime_sexanim}loop"
				tasklist_add this "play_anim ${sparetime_sexanim}loop"
				tasklist_add this "play_anim ${sparetime_sexanim}loop"
				tasklist_add this "play_anim ${sparetime_sexanim}end"
				incr reprod_actioncount
				return
			}
			5 {
				tasklist_add this "rotate_tofront"
				set reprod_actioncount 0
				sparetime_sex_relief 0.9
				if {$fertility_potion_taken} {
					set kidneed 1.0
				} else {
					set kidneed [lindex $reprod_sexratio 0]
				}
				if {$gnome_gender=="female"} {
					tasklist_add this "play_anim teeter_w"
					if {rand()<$kidneed} {
						store_parents_attribs
						set reprod_pregnancy 1
						partner_info setpregnancy this 1
						if {!$fertility_potion_taken&&rand()<$kidneed*0.1-0.1} {set twin 2} {set twin 1}
						set pregntime 1000.0
						timer_event this evt_zwerg_birth -attime [expr {[gettime] + $pregntime}] -num1 $twin
						timer_event this evt_zwerg_birth_forced -attime [expr {[gettime] + $pregntime + 500}] -num1 $twin
						if {$twin>1} {log "Zwillingsgeburt in $pregntime Sekunden! ($twin)"} {log "Einzelkind in $pregntime Sekunden! ($twin)"}
						set fertility_potion_taken 0
					}
				} else {
					tasklist_add this "play_anim teeter_t"
				}
				state_triggerfresh this sparetime_dispatch
				return
			}
		}
	}
	
	proc store_parents_attribs {} {
		global reprod_partner reprod_parents_attribs
		set mothers 0; set fathers 0
		set reprod_parents_attribs ""
		foreach attribut [concat [get_expattrib] atr_ExpMax] {
			set mother [get_attrib this $attribut]
			set father [get_attrib $reprod_partner $attribut]
			if {"atr_ExpMax"==$attribut} {
				lappend reprod_parents_attribs [list $attribut [expr {[hmax $mother $father]+0.2}]]
			} {
				if {"exp_Kampf"!=$attribut} {
					set mothers [expr {$mothers+$mother}]
					set fathers [expr {$fathers+$father}]
				}
				lappend reprod_parents_attribs [list $attribut [expr {($mother+$father)*0.3}]]
			}
		}
	}
	proc recall_parents_attribs {} {
		global reprod_parents_attribs
		return reprod_parents_attribs
	}
	proc bear_child {cnt {forced 0}} {
		global current_babies reprod_pregnancy reprod_timer reprod_partner reprod_parents_attribs
		global own childrencount
		if {!$forced&&[get_gnomeposition this]} {
			if {[walk_down_from_wall]} {
				tasklist_add this "bear_child $cnt 1"
			} else {
				tasklist_add this "bear_child $cnt"
			}
			return
		}
		play_anim sitdown
		tasklist_add this "play_anim standup"
		set reprod_pregnancy 0
		set reprod_timer 0
		sel /obj
		for {set i 0} {$i<$cnt} {incr i} {
			incr childrencount
			set nz [new Baby]
			set_owner $nz [get_owner this]
			call_method $nz init
			set_worktime $nz duration [get_worktime this duration]
			lappend current_babies $nz
			partner_info addchild this $nz
			partner_info setmother $nz this
			partner_info setfather $nz $reprod_partner
			partner_info setpregnancy this 0
			log "New Gnome born !!! ([get_objname $nz])"
			foreach atrcom $reprod_parents_attribs {
				log "set_attrib $nz $atrcom"
				eval "set_attrib $nz $atrcom"
			}
			set pos [get_place -center [get_pos this] -circle 6 -random 3]
			if {[lindex $pos 0]<1} {set pos [get_pos this]}
			set_pos $nz $pos
		}
		set_owner_attrib $own LastBirth [expr {[gettime]*0.001}]
		sparetime_talkissue_delete "prgn"
	}

}
