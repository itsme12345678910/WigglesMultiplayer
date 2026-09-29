// sparetime procs



proc sparetime_searchrange {} {
	global stt_maxsearch_range
	if {![get_prodautoschedule this]} {return [expr {$stt_maxsearch_range*0.05}]} {return $stt_maxsearch_range}
}

proc sparetime_disappoint {} {
	global sparetime_disappointment sparetime_disapp_rates
	if {$sparetime_disapp_rates} {
		set decrement [expr {$sparetime_disappointment / -$sparetime_disapp_rates}]
		incr sparetime_disapp_rates -1
		add_attrib this atr_Mood $decrement
		fincr sparetime_disappointment $decrement
	} else {
		set sparetime_disappointment 0.0
	}
}

proc sparetime_set_disapp {disapp} {
	global stt_disapp_max stt_disapp_factor sparetime_disappointment
	set sparetime_disappointment [hmin $stt_disapp_max [expr {$disapp * $stt_disapp_factor}]]
	set sparetime_disappointment [hmax [expr {$stt_disapp_max * -0.5}] $sparetime_disappointment]
}

proc sparetime_exec_taste {tastelist} {
	global sparetime_aftertaste
	set newtaste [list]
	set summe 0
	for {set i 0} {$i<4} {incr i} {
		set newt [expr {[lindex $sparetime_aftertaste $i]+[lindex $tastelist $i]}]
		lappend newtaste $newt
		fincr summe $newt
	}
	if {$summe<1.0} {
		set sparetime_aftertaste $newtaste
	} else {
		set sparetime_aftertaste [list]
		for {set i 0} {$i<4} {incr i} {
			lappend sparetime_aftertaste [expr {[lindex $newtaste $i]/$summe}]
		}
	}
	// log "[get_objname this]: spt_ex_t: $tastelist, $sparetime_aftertaste"
}

proc sparetime_taste_wish {} {
	global sparetime_aftertaste
	set max_at [hmax $sparetime_aftertaste]
	set rlst [list]
	foreach at $sparetime_aftertaste {
		lappend rlst [expr {$max_at - $at}]
	}
	return $rlst
}

proc sparetime_eat_judge {taste classname} {
	global civ_state sparetime_recent_food
	return [expr {(1-sqrt($civ_state)*(0.8-10*$taste)) * (1-sqrt($civ_state)*0.1*[lcount $sparetime_recent_food $classname])}]
}

proc sparetime_eat_check {} {
	global sparetime_eatclasses stt_maxsearch_range
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set bbox "-$max_search_range -$half_search_range -15 $max_search_range $half_search_range 15"
	foreach objref [inv_list this] {
		if {-1!=[lsearch $sparetime_eatclasses [get_objclass $objref]]} {return 1}
	}
	if {[inv_check this 1]==0} {return 0}
	set objreflist [obj_query this "-class \{$sparetime_eatclasses\} -boundingbox \{$bbox\} -visibility own -owner \{own -1\} -limit 10 -flagpos visible -flagneg \{contained locked\} -water 0 -limit 1"]
	if { $objreflist != 0 } {
		return 1
		foreach objref $objreflist {
			if {abs([get_posx this]-[get_posx $objref])+abs([get_posy this]-[get_posy $objref])*2.0>$max_search_range} {continue}
		//	log "found ground eatitem: $objref"
			return 1
		}
	}
	set objreflist [obj_query this "-class \{$sparetime_eatclasses\} -boundingbox \{$bbox\} -visibility own -owner \{own -1\} -limit 10 -flagpos \{visible instore\} -flagneg locked -water 0 -limit 1"]
	if { $objreflist != 0 } {
		return 1
		foreach objref $objreflist {
			if {abs([get_posx this]-[get_posx $objref])+abs([get_posy this]-[get_posy $objref])*2.0>$max_search_range} {continue}
		//	log "found lager eatitem: $objref"
			return 1
		}
	}
//	log "[get_objname this]: sparetime_eat_check failed"
	return 0
}

proc sparetime_eat_start {} {
	global sparetime_seat sparetime_current_place sparetime_current_place_ref sparetime_eat_item
	if {[is_selected this]} {log "sparetime_eat_start $sparetime_eat_item"}
	global sparetime_eatclasses sparetime_eatplaces sparetime_reservation stt_maxsearch_range
	global civ_state sparetime_recent_food sparetime_eat_mode sparetime_disappointment myref
	global stt_disapp_max stt_disapp_factor stt_eatciv_0 stt_eatciv_Feuerstelle sparetime_reserve_place
	global stt_eatciv_Mittelalterkueche stt_eatciv_Industriekueche stt_eatciv_Luxuskueche
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set bbox "-$max_search_range -$half_search_range -15 $max_search_range $half_search_range 15"
	set hunger [expr {1-[get_attrib this atr_Nutrition]}]
	set tastewish [sparetime_taste_wish]
	set qitemlist [list]
	set gainlist [list]
	set eat_item 0
	set eat_mode ""
	foreach classname $sparetime_eatclasses {
		global stt_eatgain_$classname stt_eattaste_$classname
		if {[subst \$stt_eatgain_$classname]>$hunger} {set judgement 0.5} {set judgement 1.0}
		set taste 0.0
		for {set i 0} {$i<4} {incr i} {
			fincr taste [expr {[lindex $tastewish $i] * [lindex [subst \$stt_eattaste_$classname] $i]}]
		}
		set judgement [expr {$judgement * [sparetime_eat_judge $taste $classname]}]
		lappend qitemlist $judgement
		lappend gainlist [subst \$stt_eatgain_$classname]
		//if {[is_selected this]} {log "$classname:t $taste,j $judgement,w $tastewish"}
		if {[set i [inv_find this $classname]]!=-1} {
			if {[get_gnomeposition this]} {sparetime_climb_somewhere;return}
			set eat_item [inv_get this $i]
			set sparetime_eat_mode "item"
			set eat_mode "inv"
			sparetime_check_in 0
			set disapp [expr {[hmax 0.0 [expr $civ_state-$stt_eatciv_0]]-$judgement*0.3}]
			break
			//if {[is_selected this]} {log "[get_objname this] found inv_item: $eat_item $classname"}
		}
	}
	if {!$eat_item} {
		set placelist [sparetime this queryrect eat -$max_search_range -$half_search_range $max_search_range $half_search_range]
		if {[is_selected this]} {log "Kitchens found: $placelist"}
		set qplacelist [list]
		foreach place $placelist {
			if {[get_prod_pack $place]} {continue}
			if {[prod_guest guestfree $place]==-1} {continue}
			set offer [call_method $place get_eat_objects $sparetime_eatclasses]
			if {[lcount $offer 0]==[llength $offer]} {continue}
			if {[vector_dist [get_pos this] [get_pos $place]]<5} {
				if {[call_method $place ask_for_seat]} {
					set pathcosts 0.0
				} else {
					set pathcosts 15.0
				}
			} else {
				set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*2.0}]
				if {$pathcosts>$max_search_range} {continue}
			}
			set offercount -1
			set besttaste 0.0
			for {set i 0} {$i<[llength $sparetime_eatclasses]} {incr i} {
				if {[lindex $offer $i]} {
					incr offercount [lindex $offer $i]
					set ctaste [lindex $qitemlist $i]
					if {$ctaste>=$besttaste} {
						set besttaste $ctaste
						set bestclass [lindex $sparetime_eatclasses $i]
						set bestgain [lindex $gainlist $i]
					}
				}
			}
			if {$hunger<0.01} {log "WARNING: HUNGER < 0.01!!!";set hunger 0.01}
			if {$offercount*0.15<$hunger-$bestgain} {
				set amount [expr {(atan((floor(($hunger-$bestgain)/0.15)-$offercount)*1.5)+2.0)*0.3}]
			} else {
				set amount 1.0
			}
			set disappointment [expr {[hmax 0.0 [expr {$civ_state-[subst \$stt_eatciv_[get_objclass $place]]}]]-$besttaste*0.3}]
			set judgement [expr {(1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$disappointment*$disappointment))/$amount}]
			lappend qplacelist [list $place $judgement $disappointment $bestclass $pathcosts]
			if {[is_selected this]} {log "[get_objname $place]:o $offer,bc $bestclass,bt $besttaste,a $amount,pc $pathcosts"}
		}
		if {[llength $qplacelist]} {
			log "[get_objname this]:qpl:$qplacelist"
			set bestplace [lindex [lsort -index 1 -real $qplacelist] 0]
			set disapp [lindex $bestplace 2]
			set place [lindex $bestplace 0]
			set costs [lindex $bestplace 4]
			if {$costs<0.2 && [call_method $place ask_for_seat]} {
				sparetime_check_in $place
			} else {
				set sparetime_current_place_ref $place
				if {[is_selected this]} {log "sparetime_seat reserved at $place for [get_objname this] ([get_ref this])"}
				call_method $place reserve_seat $myref
				set sparetime_reservation 1
			}
			set sparetime_eat_mode "place"
			set eat_item [call_method $place get_certain_object [lindex $bestplace 3]]
		} else {
			set sparetime_eat_mode "item"
			set bestjudge 1000
			set items [obj_query this "-class \{$sparetime_eatclasses\} -boundingbox \{$bbox\} -visibility own -owner \{own -1\} -limit 10 -flagpos visible -flagneg \{contained locked\} -water 0"]
			if {$items==0} {
				set items [obj_query this "-class \{$sparetime_eatclasses\} -boundingbox \{$bbox\} -visibility own -owner \{own -1\} -limit 10 -flagpos \{visible instore\} -flagneg locked -water 0"]
			}
			if {$items==0} {log "eatcheck!=eatstart";return false}
			foreach item $items {
				if {[get_lock $item]} {log "Gefundenes Item Nr. $item ([get_objname $item]) war gelockt!"}
				set pathcosts [expr {abs([get_posx this]-[get_posx $item])+abs([get_posy this]-[get_posy $item])*2.0}]
				//if {$pathcosts>$max_search_range} {continue}
				set classnumber [lsearch $sparetime_eatclasses [get_objclass $item]]
				set taste [lindex $qitemlist $classnumber]
				set disappointment [expr {[hmax 0.0 [expr $civ_state-$stt_eatciv_0]]-$taste}]
				set judgement [expr {1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$disappointment)}]
				if {$judgement<$bestjudge} {set bestjudge $judgement;set eat_item $item;set disapp $disappointment}
			}
		}
	}
	if {$eat_item} {
		set_objicon this -1 1 2 5
		tasklist_add this "change_tool 0"
		if {$eat_mode==""} {tasklist_add this "pickup $eat_item"}
		set sparetime_eat_item $eat_item
		lock_item $sparetime_eat_item
	} else {
		log "eatcheck!=eatstart (ende)";return false
	}
}

proc sparetime_eat_loop {} {
	global sparetime_eatplaces sparetime_seat sparetime_current_place sparetime_current_place_ref
	global sparetime_eatclasses sparetime_eat_mode sparetime_disappointment sparetime_eat_item
	global sparetime_reservation stt_dst_eatplace civ_state sparetime_recent_food
	if {![obj_valid $sparetime_eat_item]} {set sparetime_eat_item 0}
	if {[is_selected this]} {log "sparetime_eat_loop $sparetime_eat_item $sparetime_eat_mode"}
	if {[is_selected this]} {log "([get_ref this]): sparetime_eat_loop ($sparetime_eat_mode) [get_attrib this atr_Nutrition]"}
	if {[lsearch [inv_list this] $sparetime_eat_item]!=-1} {
		if {$sparetime_current_place_ref} {
			if {[obj_valid $sparetime_current_place_ref]} {
				if {![get_buildupstate $sparetime_current_place_ref]||[get_prod_pack $sparetime_current_place_ref]||[isunderwater [get_pos $sparetime_current_place_ref]]||[vector_dist [get_pos $sparetime_current_place_ref] [get_pos this]]>10} {
					sparetime_check_in 0
					fincr sparetime_disappointment $stt_dst_eatplace
				}
			} else {
				sparetime_check_in 0
				fincr sparetime_disappointment $stt_dst_eatplace
			}
		}
		if {$sparetime_reservation} {
			if {[call_method $sparetime_current_place_ref ask_for_seat]} {
				sparetime_check_in $sparetime_current_place_ref
				set sparetime_reservation 0
			} else {
				if {[get_attrib this atr_Nutrition]<0.2} {
					sparetime_check_in 0
					fincr sparetime_disappointment $stt_dst_eatplace
				} else {
					sparetime_eat_wait
					return
				}
			}
		}
		if {!$sparetime_current_place_ref} {
			set max_search_range [sparetime_searchrange]
			set half_search_range [expr {$max_search_range*0.5}]
			set placelist [sparetime this queryrange eat 20]
			foreach place $placelist {
				if {[get_prod_pack $place]} {continue}
				if {[call_method $place ask_for_seat]} {
					sparetime_check_in $place
					break
				}
			}
		}
		set sitmode "ground"
		if {$sparetime_current_place_ref} {
			set sparetime_eat_mode "place"
			set dummy [prod_guest getlink $sparetime_current_place_ref $sparetime_seat]
			tasklist_add this "walk_dummy $sparetime_current_place_ref $dummy"
			if {$sparetime_current_place!="Feuerstelle"} {
				tasklist_add this "rotate_toangle [call_method $sparetime_current_place_ref get_dummy_rot $sparetime_seat]"
				set sitmode "table"
			}
		}
		sparetime_eat $sparetime_eat_item $sitmode
	} else {
		global sparetime_goal at_Nu
		if "$sparetime_goal" {return}
		if {$sparetime_eat_mode=="item"} {
			sparetime_eat_start
			return
		} else {
			if {$sparetime_current_place_ref} {
				if {[obj_valid $sparetime_current_place_ref]} {
					if {![get_boxed $sparetime_current_place_ref]&&[vector_dist [get_pos $sparetime_current_place_ref] [get_pos this]]<10} {
						set offer [call_method $sparetime_current_place_ref get_eat_objects $sparetime_eatclasses]
						if {[lcount $offer 0]<[llength $offer]} {
							set hunger [expr {1-[get_attrib this atr_Nutrition]}]
							set tastewish [sparetime_taste_wish]
							set besttaste -1.0
							for {set i 0} {$i<[llength $sparetime_eatclasses]} {incr i} {
								if {[lindex $offer $i]==0} {continue}
								set classname [lindex $sparetime_eatclasses $i]
								global stt_eatgain_$classname stt_eattaste_$classname
								if {[subst \$stt_eatgain_$classname]>$hunger} {set judgement 0.5} {set judgement 1.0}
								set taste 0.0
								for {set j 0} {$j<4} {incr j} {
									fincr taste [expr {[lindex $tastewish $j] * [lindex [subst \$stt_eattaste_$classname] $j]}]
								}
								set judgement [expr {$judgement * [sparetime_eat_judge $taste $classname]}]
								if {$judgement>$besttaste} {set besttaste $judgement;set bestclass $classname}
								//if {[is_selected this]} {log "$classname:t $taste,j $judgement,w $tastewish"}
							}
							global stt_eatciv_[get_objclass $sparetime_current_place_ref]
							set sparetime_eat_item [call_method $sparetime_current_place_ref get_certain_object $bestclass]
							lock_item $sparetime_eat_item
							tasklist_add this "pickup $sparetime_eat_item"
							return
						}
					}
				}
			}
		}
		sparetime_eat_end
		sparetime_eat_start
	}
}

proc sparetime_eat_end {} {
	global sparetime_disappointment sparetime_eat_item
	set sparetime_eat_item 0
	sparetime_check_in 0
	set sparetime_disappointment 0.0
//	log "sparetime_eat_end"
}

proc sparetime_eat_wait {} {
	global sparetime_activities stt_wait_forseat
	set targetgnome [obj_query this "-class Zwerg -owner own -range 5 -limit 1"]
	add_attrib this atr_Mood $stt_wait_forseat
	tasklist_add this "rotate_towards $targetgnome"
	tasklist_add this [lindex $sparetime_activities [irandom 14]]
	tasklist_add this "play_anim hungry"
}
proc sparetime_eat {item mode} {
	set food [get_objclass $item]
	sparetime_check_prtn
	global stt_eatgain_$food sparetime_dissappointment stt_fungain_$food
	set affect [expr {[subst \$stt_eatgain_$food]*0.25}]
	set maffect [expr {[subst \$stt_fungain_$food]*0.25}]
	set toolclass [call_method $item get_toolclasses]
	if {[string first "suppe" $toolclass]>0} {
		set anim soup
	} elseif {$toolclass=="hamstershake"} {
		set anim shake
	} else {
		set anim eat
	}
	switch $mode {
		"ground" {
			set anim sitfloor$anim
			tasklist_add this "rotate_tofront"
			tasklist_add this "play_anim hungry"
			tasklist_add this "play_anim sitdown"
			tasklist_add this "change_tool Ess$toolclass 0 0"
			tasklist_add this "sparetime_consume $item $food"
			for {set i 0} {$i<4} {incr i} {
				tasklist_add this "play_anim $anim"
				tasklist_add this "add_attrib this atr_Nutrition $affect;add_attrib this atr_Mood $maffect"
			}
			tasklist_add this "change_tool 0;play_anim standup"
			tasklist_add this "play_anim cleanfloorstart"
			tasklist_add this "play_anim cleanfloorloop"
			tasklist_add this "play_anim cleanfloorloop"
			tasklist_add this "play_anim cleanfloorloop"
			tasklist_add this "play_anim cleanfloorstop;set sparetime_disappointment 0.0"
		}
		"table" {
			set anim sitchair$anim
			tasklist_add this "play_anim sitdown_chair"
			tasklist_add this "change_tool Ess$toolclass 0 0"
			tasklist_add this "sparetime_consume $item $food"
			for {set i 0} {$i<4} {incr i} {
				tasklist_add this "play_anim $anim"
				tasklist_add this "add_attrib this atr_Nutrition $affect;add_attrib this atr_Mood $maffect"
			}
			tasklist_add this "change_tool 0;play_anim standup_chair;set sparetime_disappointment 0.0"
		}
	}
}
proc sparetime_consume {item itemtype} {
	global sparetime_recent_food stt_eattaste_$itemtype sparetime_current_place sparetime_eat_count
	incr sparetime_eat_count
	inv_rem this $item
	set_hoverable $item 0
	sparetime_exec_taste [subst \$stt_eattaste_$itemtype]
	sparetime_update_quality "eat" $sparetime_current_place
	set_visibility $item 0
	del $item
	lappend sparetime_recent_food $itemtype
	if {[llength $sparetime_recent_food]>10} {set sparetime_recent_food [lrange $sparetime_recent_food 1 10]}
}


proc sparetime_slp_start {} {
	global sparetime_current_place sparetime_current_place_ref reprod_partner sparetime_seat
	global civ_state
	global stt_slpciv_0 stt_slpciv_Zelt stt_slpciv_Mittelalterschlafzimmer stt_slpciv_Industrieschlafzimmer stt_slpciv_Luxusschlafzimmer
	global stt_slpgain_0 stt_slpgain_Zelt stt_slpgain_Mittelalterschlafzimmer stt_slpgain_Industrieschlafzimmer stt_slpgain_Luxusschlafzimmer
	global sparetime_disapp_slp sparetime_disapp_rates stt_maxsearch_range sparetime_slp_mode
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set reflist [sparetime this queryrect sleep -$max_search_range -$half_search_range $max_search_range $half_search_range]
	set ref 0; set qreflist [list]
	set sleepneed [expr {1-[get_attrib this atr_Alertness]}]
	foreach place $reflist {
//		log "$place [get_objname $place] [get_objtype $place]"
		if {[get_prod_pack $place]} {continue}
		if {[prod_guest guestfree $place] == -1} {
//			lappend qreflist [list $place 0]
			continue
		}
		if {[vector_dist [get_pos this] [get_pos $place]]<5.0} {
			set pathcosts 0.0
		} else {
			set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*2.0}]
		//	if {$pathcosts>$max_search_range} {continue}
			fincr pathcosts [expr {$sleepneed/[subst \$stt_slpgain_[get_objclass $place]]-$sleepneed/$stt_slpgain_0}]
		}
		log "[get_objname this]: [get_objname $place] pc ($pathcosts)"
		if {$reprod_partner&&[obj_valid $reprod_partner]} {
			if {$place == [call_method $reprod_partner get_sparetime_place]} {
				set pathcosts [expr {$pathcosts*0.5}]
			}
		}
		set disappointment [hmax 0.0 [expr {$civ_state-[subst \$stt_slpciv_[get_objclass $place]]}]]
		set judgement [expr {1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$disappointment*$disappointment)}]
		log "[get_objname this]: [get_objname $place] jd ($judgement)"
		if {$judgement+$stt_slpciv_0<$civ_state} {lappend qreflist [list $place $judgement $disappointment]}
	}
	if {[llength $qreflist]} {
		if {[is_selected this]} {log "qrl: $qreflist"}
		set bestref [lindex [lsort -index 1 -real $qreflist] 0]
		set disapp [lindex $bestref 2]
		set ref [lindex $bestref 0]
	} else {
		set ref 0
		set disapp [expr {$civ_state - $stt_slpciv_0}]
	}
	if {$sparetime_disapp_slp==0} {
	}
	if {[is_selected this]} {log "disapp: $disapp"}
	if {$ref} {
		if {[isunderwater [get_pos $ref]]} {
			set ref 0
		}
	}
	if {$ref} {
		set pclass [get_objclass $ref]
		set seat -1
		if {$reprod_partner&&[check_method $pclass get_partner_seat]} {
			set seat [call_method $ref get_partner_seat $reprod_partner]
		}
	//	if {$seat!=-1} {
			sparetime_check_in $ref $seat
	//	} else {
	//		sparetime_check_in $ref
	//	}
		set sleepseat $sparetime_seat
		set dummy [prod_guest getlink $ref $sleepseat]
		set sparetime_slp_mode "place"
		switch $sparetime_current_place {
			"Zelt" {
				set angle [string map {a 5.5 b 0 c 0.78} [string index [ref_get $ref standard_anim] 5]]
				set layanim laydown
			}
			"Mittelalterschlafzimmer" {
				set angle [lindex {5.05 1.65} $sleepseat]
				set layanim [lindex {bedastart bedbstart} $sleepseat]
			}
			"Industrieschlafzimmer" {
				set angle [lindex {4.71 1.57 5.40 2.10 1.06 4.22} $sleepseat]
				set layanim bed[string index ababba $sleepseat]start
			}
			"Luxusschlafzimmer" {
				set angle [lindex {1.57 4.71} $sleepseat]
				set layanim bed[string index ba $sleepseat]start
			}
		}
		change_tool 0
		prod_guest guestset $ref $sleepseat [get_ref this]
		tasklist_add this "walk_dummy $ref $dummy"
		shortlock_dummy $ref $dummy
	} else {
		if {[get_gnomeposition this]} {sparetime_climb_somewhere;return}
		global myref
		set sparetime_slp_mode "free"
		set spoint "0.0 0.0 0.0"
		log "[get_objname this] searching for sleeping place"
		//	log "no moos found for sleep"
		set slst [obj_query this "-class Pilz -range 10 -flagneg locked"]
		if {$slst==0} {set slst ""}
		foreach sp $slst {
			if {[get_roty $sp]>0.5} {continue}
			set spos [vector_add [get_pos $sp] {0.1 0 -0.6}]
			if {[placelock_check $spos 0.9 $myref]} {continue}
			if {$sp&&-1!=[lsearch [list 0 $myref] [obj_query $sp "-class Zwerg -range 2 -limit 1"]]} {
				//if {[lindex [set spoint [get_place -center $spos -circle 1.1 -walldist 1 -except this -placelockidexcept $myref]] 0]>1}
				set angle [random 1.3 1.9]
				//	set sparetime_slp_mode "pilz"
				//	break
				// else {log "no place found near Pilz $sp"}
				set spoint $spos
			} else {log "Zwerg found near Pilz $sp"}
		}
		if {[lindex $spoint 0]<1} {
		//	log "no Pilz found for sleep"
			set cpos [get_pos this]
			set cx [lindex $cpos 0]
			set cy [expr {[lindex $cpos 1]-0.15}]
			for {set i 0} {abs($i)<8} {set i [expr {-$i+($i<1)}]} {
				set x [expr {$cx+$i*0.5}]
				set height [expr {[get_hmap $x $cy]+1.5}]
				set spos [list $x [lindex $cpos 1] $height]
				if {[placelock_check $spos 0.9 $myref]} {continue}
				if {0!=[obj_query this "-pos \{$x $cy $height\} -class Zwerg -range 2 -limit 1"]} {continue}
				if {[lindex [set spoint [get_place -center $spos -circle 3 -walldist 1 -except this -placelockidexcept $myref]] 0]>1} {
					log "[get_objname this]: spoint $spoint ($i)"
					set angle [expr {1.57+atan(2*([get_hmap [expr $x+0.5] $cy]-[get_hmap [expr $x-0.5] $cy]))}]
					break
				}
			//	else {log "no place found near wall ($spos)"}
			}
		}
		if {[lindex $spoint 0]<1} {
			log "no Wall found for sleep"
			set spoint [get_place -center $cpos -rect -8 -8 8 8 -walldist 1 -except this -placelockidexcept $myref]
			if {[lindex $spoint 0]<1} {
				set spoint $cpos
				log "no place found near mypos ($cpos)"
			}
			log "[get_objname this]: spoint $spoint ($cpos)"
			set angle 1.57
		}
		if {[isunderwater $spoint]} {
			sparetime_climb_somewhere
			return
		}
		tasklist_add this "walk_pos \{$spoint\}"
		shortlock_pos $spoint
		set layanim laydown
		set sparetime_current_place 0
		set sparetime_current_place_ref 0
	}
	set_objicon this -1 1 1	5
	tasklist_add this "rotate_toangle $angle"
	tasklist_add this "play_anim $layanim;sparetime_start_sleep"
//	log "sparetime_slp_start"
}
proc sparetime_start_sleep {} {
	global willing_to_reprod is_sleeping sparetime_current_place spt_sleep_counter
	set spt_sleep_counter 0
	set willing_to_reprod 1
	change_particlesource this 1 4 {0 0 0} {0 0 0} 2 1 0 10
	set_particlesource this 1 1
	sparetime_update_quality "slp" $sparetime_current_place
	set is_sleeping 1
}
proc sparetime_slp_loop {} {
	global sparetime_current_place_ref sparetime_current_place
	global sparetime_seat sparetime_slp_mode spt_sleep_counter
	sparetime_check_prtn
	incr spt_sleep_counter
	if {($spt_sleep_counter%5)==0} {
		if {[try_getoutof_water]} {
			return
		}
	}
	if {$sparetime_slp_mode=="place"&&$sparetime_current_place_ref} {
		if {![obj_valid $sparetime_current_place_ref]||![get_buildupstate $sparetime_current_place_ref]||[get_prod_pack $sparetime_current_place_ref]} {
			global stt_dst_bett
			add_attrib this atr_Mood $stt_dst_bett
			sparetime_slp_end
			sparetime_slp_start
			return
		}
	} elseif {$sparetime_slp_mode=="pilz"} {
		set pref [obj_query this "-class Pilz -range 2 -limit 1"]
		if {[get_lock $pref]} {
			global stt_dst_pilz
			add_attrib this atr_Mood $stt_dst_pilz
			sparetime_slp_end
			sparetime_slp_start
			return
		}
	}
//	log "sparetime_slp_loop"
	switch $sparetime_current_place {
		"Zelt" {set sanim sleepside;set gf 1.1}
		"Mittelalterschlafzimmer" {set sanim [lindex {bedaloop bedbloop} $sparetime_seat];set gf 1.2}
		"Industrieschlafzimmer" {set sanim bed[string index ababba $sparetime_seat]loop;set gf 1.2}
		"Luxusschlafzimmer" {set sanim bed[string index ba $sparetime_seat]loop;set gf 1.2}
		default {set sanim sleepside;set gf 1.1}
	}
	global stt_slpgain_$sparetime_current_place sparetime_disapp_rates sparetime_disapp_slp
	add_attrib this atr_Alertness [expr {[subst \$stt_slpgain_$sparetime_current_place]*$gf}]
	tasklist_add this "play_anim $sanim"
	if {$sparetime_disapp_rates} {
		tasklist_add this "play_anim $sanim;sparetime_disappoint"
	} else {
		tasklist_add this "play_anim $sanim"
		set sparetime_disapp_slp 1
	}
}
proc sparetime_slp_end {{finally 1}} {
	global sparetime_disapp_slp is_sleeping sparetime_disappointment sparetime_current_place
	if {$finally} {
		sparetime_check_in 0
		set sparetime_disapp_slp 0
	}
	switch $sparetime_current_place {
		"Zelt" {set sanim sleeptostand}
		"Mittelalterschlafzimmer" {set sanim [lindex {bedastop bedbstop} $sparetime_seat]}
		"Industrieschlafzimmer" {set sanim bed[string index ababba $sparetime_seat]stop}
		"Luxusschlafzimmer" {set sanim bed[string index ba $sparetime_seat]stop}
		default {set sanim sleeptostand}
	}
	tasklist_add this "play_anim $sanim"
//	log "sparetime_slp_end"
	set_particlesource this 1 0
	set is_sleeping 0
	set sparetime_disappointment 0.0
}

proc sparetime_bth_start {} {
	global sparetime_current_place sparetime_current_place_ref reprod_partner civ_state
	global spt_bath_disapp stt_maxsearch_range
	global stt_bthciv_0 stt_bthciv_Mittelalterbad stt_bthciv_Industriebad stt_bthciv_Luxusbad
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set pl [sparetime this queryrect bath -$max_search_range -$half_search_range $max_search_range $half_search_range]
	log "searching for bathsites: found ($pl)"
	if {$pl==0} {set pl ""}
	set plist {}
	foreach place $pl {
		if {[get_prod_pack $place]} {continue}
		if {[prod_guest guestfree $place] == -1} {
			continue
		}
		if {[vector_dist [get_pos this] [get_pos $place]]<5.0} {
			set pathcosts 0.0
		} else {
			set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*2.0}]
			//if {$pathcosts>$max_search_range} {continue}
		}
		if {$reprod_partner&&[obj_valid $reprod_partner]} {
			if {$place == [call_method $reprod_partner get_sparetime_place]} {
				set pathcosts [expr {$pathcosts*0.5}]
			}
		}
		set disappointment [hmax 0.0 [expr {$civ_state-[subst \$stt_bthciv_[get_objclass $place]]}]]
		set judgement [expr {1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$disappointment*$disappointment)}]
		log "[get_objname this]: [get_objname $place] bath-jd ($judgement) ($disappointment)"
		if {$judgement+$stt_bthciv_0<$civ_state} {lappend plist [list $place $judgement $disappointment]}
	}
	if {$plist==""} {
		set spt_bath_disapp [expr {$civ_state - $stt_bthciv_0}]
	} else {
		set entry [lindex [lsort -index 1 -real $plist] 0]
		set spt_bath_disapp [lindex $entry 2]
		sparetime_check_in $place
		global sparetime_seat
		set dummy [prod_guest getlink $place $sparetime_seat]
		tasklist_add this "walk_dummy $place $dummy"
	}
	//	tasklist_add this "play_anim sitdown_bath"
}
proc sparetime_bth_loop {} {
	global sparetime_current_place_ref sparetime_seat spt_bath_desire spt_bath_disapp has_bathed
	sparetime_check_prtn
	if {$sparetime_current_place_ref} {
		if {[obj_valid $sparetime_current_place_ref]} {
			if {[get_buildupstate $sparetime_current_place_ref]&&![get_prod_pack $sparetime_current_place_ref]} {
				set place $sparetime_current_place_ref
				if {$has_bathed} {
					if {$has_bathed>1} {
						fincr spt_bath_desire -5.0
						if {[sparetime_bth_anim $place $sparetime_seat]} {
							sparetime_filler_loop
						}
						set has_bathed 5
					} else {
						if {$spt_bath_desire<2.0} {
							set has_bathed 5
						} else {
							if {[set link [call_method $place get_otherdummy $sparetime_seat]]!=-1} {
								sparetime_check_in $place $link
								set dummy [prod_guest getlink $place $sparetime_seat]
								walk_dummy $place $dummy
								set has_bathed 2
							} else {
								set has_bathed 5
							}
						}
					}
				} elseif {[call_method $place is_wait_dummy $sparetime_seat]} {
					if {[prod_guest guestfree $place]!=-1} {
						sparetime_check_in $place
						set dummy [prod_guest getlink $place $sparetime_seat]
						walk_dummy $place $dummy
					} else {
					sparetime_filler_loop
					}
				} else {
					fincr spt_bath_desire -5.0
					if {[sparetime_bth_anim $place $sparetime_seat]} {
						sparetime_filler_loop
					}
					set has_bathed 1
				}
				return
			}
		}
		sparetime_check_in 0
		act_when_idle
		return
	}
	sparetime_update_quality "bth" 0
	tasklist_add this "play_anim washface"
	tasklist_add this "incr has_bathed 2"
}
proc sparetime_bth_anim {place link} {
	if {![check_method [get_objclass $place] get_bath_actions]} {return 1}
	global sparetime_current_place myref
	sparetime_update_quality "bth" $sparetime_current_place
	set firstcmd 1
	foreach cmd [call_method $place get_bath_actions $myref $link] {
		if {$firstcmd} {
			eval $cmd
			set firstcmd 0
		} else {
			tasklist_add this $cmd
		}
	}
	return 0
}
proc sparetime_bth_end {} {
	global sparetime_current_place_ref sparetime_seat myref has_bathed
	set has_bathed 0
	if {$sparetime_current_place_ref} {
		if {[obj_valid $sparetime_current_place_ref]} {
			call_method $sparetime_current_place_ref remove_from_bath $myref $sparetime_seat
			prod_change_muetze sparetime
		}
	}
	sparetime_reset_clothes
	sparetime_check_in 0
}

proc sparetime_ill_start {} {
	if {[set hosp_list [obj_query this "-class Krankenhaus -range 40 -owner own -flagneg boxed"]]==0} {
		return 0
	}
	set found 0
	global sparetime_seat
	foreach hospital $hosp_list {
		if {[set sparetime_seat [prod_guest guestfree $hospital]]!=-1} {
			set found 1
			break
		}
	}
	if {$found==0} {return 0}
	global sparetime_current_place sparetime_current_place_ref
	set dummy [prod_guest getlink $hospital $sparetime_seat]
	prod_guest guestset $hospital $sparetime_seat [get_ref this]
	set sparetime_current_place Krankenhaus
	set sparetime_current_place_ref $hospital
	tasklist_add this "walk_dummy $hospital $dummy"
	tasklist_add this "prod_turnleft"
}
proc sparetime_ill_loop {} {
	global sparetime_seat sparetime_current_place_ref 
	if {![obj_valid $sparetime_current_place_ref]} {sparetime_checkin 0}
	prod_guest addorder $sparetime_current_place_ref $sparetime_seat
	set arzt [call_method $sparetime_current_place_ref get_worker]
	if {$arzt == 0 } {
		set patient 0
	} else {
		set patient [call_method $sparetime_current_place_ref get_patient]
	}
	if {[get_ref this] == $patient} { 
		set todo [call_method $sparetime_current_place_ref get_current_todo]
		switch $todo {
			1 {	
				tasklist_add this "walk_dummy $sparetime_current_place_ref 1"
				tasklist_add this "prod_turnback"
				tasklist_add this "prod_anim illstart"
				tasklist_add this "play_anim illloop"
				tasklist_add this "call_method $sparetime_current_place_ref set_current_todo 2"
			}
			2 {
				tasklist_add this "play_anim illloop"
			}
			
			4 {
				tasklist_add this "walk_dummy $sparetime_current_place_ref 19"
				tasklist_add this "prod_turnleft"
				tasklist_add this "call_method $sparetime_current_place_ref set_current_todo 5"
			}
			5 {
				tasklist_add this "prod_anim breathe"
				tasklist_add this "prod_ill_leicht $sparetime_current_place_ref $arzt"			
			}
			6 {
				tasklist_add this "play_anim illnormal"
				tasklist_add this "call_method $sparetime_current_place_ref set_current_todo 7"
			}
				
			default {
				tasklist_add this "play_anim wait"
			}
		}
	} else {
		tasklist_add this "play_anim wait"
	}
}
proc sparetime_ill_end {} {
	global sparetime_current_place_ref 
	set arzt [call_method $sparetime_current_place_ref get_worker]
	;#if {$arzt==0} {}
	call_method $sparetime_current_place_ref set_current_todo 0
	call_method $sparetime_current_place_ref set_patient 0
	tasklist_add this "prod_anim illend"	
	tasklist_add this "walk_dummy $sparetime_current_place_ref 3"
	
	sparetime_check_in 0
}
proc sparetime_ill_check {} {
	global sparetime_current_place sparetime_current_place_ref
	if {$sparetime_current_place=="Krankenhaus"} {return 1}
	if {[set hosp_list [obj_query this "-class Krankenhaus -range 40 -owner own -flagneg boxed"]]==0} {
		return 0
	}
	foreach hospital $hosp_list {
		if {[prod_guest guestfree $hospital]!=-1} {
			if {[get_prod_slot_cnt $hospital _Heilen] != 0} {
				return 1
			}
		}
	}
	return 0
}

proc sparetime_random {} {
	global sparetime_activities
	eval [lindex $sparetime_activities [irandom [llength $sparetime_activities]]]
}

proc sparetime_find_place {} {
	global current_occupation sparetime_current_place
	global sparetime_${current_occupation}places sparetime_current_place_ref sparetime_seat
	set places [subst \$sparetime_${current_occupation}places]
	#log "[get_objname this] places found: $placereflist"
	if {-1==[lsearch $places $sparetime_current_place]||![obj_valid $sparetime_current_place_ref]||[get_boxed $sparetime_current_place_ref]||[vector_dist [get_pos this] [get_pos $sparetime_current_place_ref]]>60} {
		if {$current_occupation=="eat"} {set range 15} else {set range 60}
		set placereflist [obj_query this "-class \{$places\} -range $range -owner own -flagpos visible -flagneg \{boxed contained\}"]
		foreach placeref $placereflist {
			if {$current_occupation=="fun" && $placeref} {
				if { [get_prod_slot_cnt $placeref [string trim [call_method $placeref prod_items]]] == 0 } {
					set placeref 0
				}
			}
			if { $placeref && [sparetime_check_in $placeref] } {
				if {$current_occupation == "eat"} {
					set dummy [prod_guest getlink $sparetime_current_place_ref $sparetime_seat]
					tasklist_add this "walk_dummy $sparetime_current_place_ref $dummy"
				}
				return 1
			}
		}
	} elseif { $current_occupation == "eat" } {
		set dummy [prod_guest getlink $sparetime_current_place_ref $sparetime_seat]
		tasklist_add this "walk_dummy $sparetime_current_place_ref $dummy"
		return 1
	}
	return 0

}

proc sparetime_check_in {placeref {meth 0}} {
	global sparetime_current_place sparetime_current_place_ref sparetime_seat sparetime_reservation
	set sparetime_reservation 0
	if {$sparetime_current_place_ref} {
		if {[obj_valid $sparetime_current_place_ref]} {
			prod_guest guestremove $sparetime_current_place_ref [get_ref this]
			prod_guest resetorder $sparetime_current_place_ref $sparetime_seat
		}
		set sparetime_current_place_ref 0
		set sparetime_current_place 0
	}
	if {$placeref} {
		if {$meth} {
			if {$meth==-1} {
				set seat [call_method $placeref get_random_seat]
				//log "[get_objname this] getting random: $seat ($placeref)"
				//log "bisher: [prod_guest guestget $placeref $seat]"
			} else {
				set seat $meth
			}
		} else {
			set seat [prod_guest guestfree $placeref]
		}
		if {$seat != -1} {
			set sparetime_seat $seat
			//log "bisher: [prod_guest guestget $placeref $seat]"
			prod_guest guestset $placeref $seat [get_ref this]
			//log "[get_objname this] checkin $placeref $seat"
			prod_guest resetorder $placeref $seat
			set sparetime_current_place_ref $placeref
			set sparetime_current_place [get_objclass $placeref]
			return 1
		}
	}
	return 0
}

proc sparetime_filler_loop {} {
	play_anim [lindex {breathe teeter_t wait scout wipenose cough teeter_w scout} [irandom 8]]
}

proc sparetime_idle_loop {} {
	play_anim [lindex {standloopa standloopb standloopc standloopd jumpa scratch breathe teeter_t wait scout wipenose cough teeter_w kneebend} [irandom 14]]
}

proc sparetime_react_towater {} {
	global idle_action_list current_occupation sparetime_fun_mode
	if {[get_walkresult this]==2} {return}
	switch $current_occupation {
		"fun" {
			switch $sparetime_fun_mode {
				"place"	{tasklist_addfront this "try_getoutof_water"}
				"home"	{tasklist_addfront this "try_getoutof_water"}
				"talk"	{tasklist_addfront this "try_getoutof_water"}
			}
		}
		"bth" {
			tasklist_addfront this "try_getoutof_water"
		}
		"ill" {
			tasklist_addfront this "try_getoutof_water"
		}
		default {
			if {[get_prodautoschedule this]} {
				if {[lsearch $idle_action_list "try_getoutof_water"]==-1} {
					lappend idle_action_list "try_getoutof_water"
				}
			}
		}
	}
}

proc try_getoutof_water {} {
	global current_occupation
	if {[isunderwater [vector_add [get_pos this] {0 -0.1 0}]]} {
		log "stillunderwater [vector_add [get_pos this] {0 -0.1 0}]"
		if {[lsearch {eat slp bth ill fun} $current_occupation]!=-1} {
			sparetime_${current_occupation}_end
		}
		tasklist_add this walk_down_from_wall
		return 1
	} else {
		return 0
	}
}

proc sparetime_climb_somewhere {} {
	global current_occupation
	switch $current_occupation {
		"slp" {set classes {Feuerstelle Zelt Mittelalterschlafzimmer Mittelalterbad Industrieschlafzimmer Industriebad Luxusschlafzimmer Luxusbad}}
		"fun" {set classes {Zwerg Feuerstelle Bar Theater Disco Fitnessstudio Bowlingbahn Bordell Mittelalterwohnzimmer Industriewohnzimmer Luxuswohnzimmer}}
		"eat" {set classes {Feuerstelle Mittelalterkueche Industriekueche Luxuskueche}}
	}
	set current_occupation "idle"
	set plist [obj_query this -class $classes -range 30 -limit 5 -flagneg boxed -water 0]
	if {$plist!=0} {
		log "Places found: $plist"
		set vec {0 0 0}
		set cnt 0
		foreach item $plist {
			set vec [vector_add $vec [get_pos $item]]
			incr cnt
		}
		set vec [vector_mul $vec [expr {1.0/$cnt}]]
		set place [get_place_long [vector_mul [vector_add [get_pos this] $vec] 0.5] 12 1 1]
		if {[lindex $place 0]>0} {
			walk_pos $place
			return
		}
	}
	walk_down_from_wall
}

proc state_code_counting {time} {
	global current_occupation sparetime_fun_mode state_code_diff
	set name $current_occupation
	if {$name=="fun"} {append name $sparetime_fun_mode}
	set nl [expr {[lindex $state_code_diff 0]+$time}]
	lrep state_code_diff 0 $nl
	set idx [lsearch -glob $state_code_diff "$name *"]
	if {$idx==-1} {
		lappend state_code_diff [list $name $time 1]
	} else {
		set entry [lindex $state_code_diff $idx]
		set ov [lindex $entry 1]
		set i [lindex $entry 2]
		fincr ov $time
		incr i
		lrep state_code_diff $idx [list $name $ov $i]
	}
}
proc state_core_counting {time} {
	global state_code_diff
	set name "core"
	lrep state_code_diff 0 [expr {[lindex $state_code_diff 0]+$time}]
	set idx [lsearch -glob $state_code_diff "$name *"]
	if {$idx==-1} {
		lappend state_code_diff [list $name $time 1]
	} else {
		set entry [lindex $state_code_diff $idx]
		set ov [lindex $entry 1]
		set i [lindex $entry 2]
		fincr ov $time
		incr i
		lrep state_code_diff $idx [list $name $ov $i]
	}
}
proc state_length_counting {time} {
	global current_occupation sparetime_fun_mode state_history last_taskcnt
	set name $current_occupation
	if {$name=="fun"} {append name $sparetime_fun_mode}
	if {$last_taskcnt==0} {
		if {$name=="funtalk"} {
			global talk_step talk_partner talk_leader talk_listener
			set talk [list $talk_step $talk_partner $talk_leader $talk_listener]
			lappend state_history [list $name $last_taskcnt $time $talk]
			return
		}
	}
	lappend state_history [list $name $last_taskcnt $time]
}

proc sparetime_change_clothes {type} {
	global gnome_gender clothes_changed
	if {$gnome_gender == "male"} {
		set gender 0
		//lappend rlst "sparetime_change_clothes 17 19"
	} else {
		set gender 1
	}
	switch $type {
		1 {
			set texvars [lindex {{17 19} {11 10}} $gender]
		}
	}
	set_textureanimation this 0 [lindex $texvars 0] 0 0
	set_textureanimation this 1 [lindex $texvars 1] 0 0
	set clothes_changed 1
}

proc sparetime_reset_clothes {} {
	global clothing clothes_changed
	if {$clothes_changed} {
		set_textureanimation this 0 [scan [string index $clothing 0] %x]
		set_textureanimation this 1 [scan [string index $clothing 1] %x]
		set clothes_changed 0
	}
}
