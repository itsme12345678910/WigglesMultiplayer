// zwerg procs
// walk und rotate wurden ausgelagert in dignwalk !!!

// kill
proc kill_item {item} {
	global current_lock_obj

	if {![obj_valid $item]} {
		return
	}

	if { $current_lock_obj == $item } {
		unlock_item
	}
	if {[get_owner $item]==-1} {set_owner $item [get_owner this]}
	call_method $item die
	set_lock $item 1
	state_disable this;
	action this wait 0.1 {state_enable this}
}

proc im_in_campaign {} {
	global is_campaign
	return $is_campaign
}

proc im_in_tutorial {} {
	global is_tutorial
	return $is_tutorial
}

proc im_a_human {} {
	global is_human
	return $is_human
}

proc multi_exp_factor {} {
	if {[im_in_campaign]} {
		return 1.0
	} else {
		return 2.0
	}
}

proc clan_exp_factor {genre} {
	global clanname
	global ttt_${clanname}clanexp
	set factorlist [subst \$ttt_${clanname}clanexp]
	set idx [lsearch -glob $factorlist "$genre *"]
	if {$idx!=-1} {
		set cfactor [lindex [lindex $factorlist $idx] 1]
	} else {
		set cfactor 1.0
	}
	return [expr {$cfactor*[multi_exp_factor]}]
}

proc exp_transp_increase {} {
	global tttgain_supply
	add_expattrib this exp_Transport [expr {$tttgain_supply*[clan_exp_factor exp_Transport]}]
}

proc lock_item {item} {
	global current_lock_obj
	if { $current_lock_obj != 0 } {
		set_lock $current_lock_obj 0
		set current_lock_obj 0
	}
	if { $item != 0 } {
		set current_lock_obj $item
		set_lock $current_lock_obj 1
	}
}

proc unlock_item {} {
	global current_lock_obj
	if { $current_lock_obj != 0 } {
		if {[obj_valid $current_lock_obj]} {
			if {[get_objclass $current_lock_obj]!="Pilz"||[get_attrib $current_lock_obj PilzAge]==3} {
				catch {set_lock $current_lock_obj 0}
			}
		}
		set current_lock_obj 0
	}
}


// schaltet von allen items im Inventory den Ghost (Alpha-Objekt) aus

proc kill_all_ghosts {} {
	global objghostlist

	set objghostlist ""
	foreach item [inv_list this] {
		hide_obj_ghost $item
	}
}


proc clear_ghostlist {} {
	global objghostlist
	set objghostlist ""
}


proc set_ghostlist {alist} {
	global objghostlist
	set objghostlist $alist
}


proc add_ghostlist {alist} {
	global objghostlist
	lappend objghostlist $alist
}


// löscht alle Alphaobjekte, die nicht in der Ghostliste sind

proc kill_old_ghosts {} {
	global objghostlist
	foreach item [inv_list this] {
		if {[lsearch $objghostlist $item] < 0} {
			hide_obj_ghost $item
		}
	}
}

proc switch_item {item} {
	if {[get_attrib $item Schaltstatus]} {return false}
	set pos [get_pos $item]
	set pos [vector_add $pos [get_vectorxz [get_roty $item] 0.8]]
	set posy [lindex $pos 1]
	set posy [expr {0.5+int($posy+0.5)}]
	lrep pos 1 $posy
	if {[vector_dist3d [get_pos this] $pos]> 0.2} {
		tasklist_add this "walk_pos \{$pos\}"
	}
	tasklist_add this "check_switcher_dist \{$pos\}"
	tasklist_add this "rotate_towards $item"
	if {[string first "knopf" [get_objclass $item]]==-1} {
		set switchanim switchup
	} else {
		set switchanim switchnorm
	}
	tasklist_add this "play_anim $switchanim;call_method $item druecken"
}

proc get_switcher_icon {item} {
	set swname [get_objclass $item]
	log "Schaltstatus: [get_attrib $item Schaltstatus]"
	if {[string first "knopf" $swname]!=-1} {
		return arrow_right
	} elseif {([lindex [split $swname "_"] end]=="up")^int([get_attrib $item Schaltstatus])} {
		return arrow_up
	} else {
		return arrow_down
	}
}

proc check_switcher_dist {pos} {
	log "csd: ([get_pos this]) ($pos) [vector_dist3d [get_pos this] $pos]"
	if {[vector_dist3d [get_pos this] $pos]>1} {
		tasklist_clear this
	}
}

proc get_nexttaskitem {} {
	set taskliste [tasklist_list this]
	set ifound [string first "0x" $taskliste]
	return [string range $taskliste $ifound [expr {$ifound + 9}]]
}

proc wait_time {seconds} {
	state_disable this;
	action this wait $seconds {state_enable this}
	return true
}

proc wait_time_dig {seconds digpos} {
	state_disable this;
	action this wait $seconds "state_enable this;dig_execute \{$digpos\};dig_continue"
	return true
}

proc play_anim {anim args} {
	global sparetime_talkevents

	if {[string first "accident" $anim]!=-1} {
		lappend sparetime_talkevents "uqw"
	}

	state_disable this
	if {$args!=""} {
		action this anim $anim "state_enable this;dig_execute $args;dig_continue"
	} else {
		action this anim $anim {state_enable this}
	}
	if {[set fanim [get_classaniminfo $anim]]!=""} {
		if {$fanim=="Illegel Anim"} {log "illegal Anim: $anim!!!";return true}
		set submesh [lindex $fanim 0]
		set fanim [lrange $fanim 1 end]
		start_fanim_sequence $fanim "-mesh $submesh"
	}
	return true
}

proc play_anim_time {anim time args} {
	set_anim this $anim 0 2
	state_disable this
	if {$args!=""} {
		action this wait $time "state_enable this;dig_execute $args;dig_continue"
	} else {
		action this wait $time {state_enable this}
	}
	return true
}

proc play_anim_loop {animroot cnt} {
	tasklist_addfront this "play_anim ${animroot}end"
	for {set i 0} {$i<$cnt} {incr i} {
		tasklist_addfront this "play_anim ${animroot}loop"
	}
	tasklist_addfront this "play_anim ${animroot}start"
	return true
}

proc play_dig_anim_loop {animroot cnt digpoint {acc 0}} {
	set first 1
	for {set i 1} {$i<=$cnt} {incr i} {
		if {$first} {
			set cmd "play_anim ${animroot}loop \{$digpoint\}"
			set first 0
		} else {
			if {$acc*0.3>rand()} {
				set cmd "play_anim ${animroot}accident"
				set acc 0
			} else {
				set cmd "play_anim ${animroot}loop"
			}
		}
		if {$i==$cnt} {
			eval $cmd
		} else {
			tasklist_addfront this $cmd
		}
	}
	return true
}


// beamt Item aus der Welt ins Inventar des Zwergen
// ACHTUNG!!!: normalerweise sollte statt dieser proc take_item verwendet werden (Errorchecks!!!)

proc beamto_inv {item} {
	//log "[get_objname this] beamto_inv"

	if {![obj_valid $item]} {
		return
	}

	if {[get_objclass $item] == "Schatzbuch"} {
		call_method $item set_standartanim
	}
	unlock_item
	inv_add this $item
	set_prodalloclock $item 0
	set_rotx $item 0.0
	set_rotz $item 0.0
	set current_owner [get_owner $item]
	set my_owner [get_owner this]
	if {$my_owner!=$current_owner&&$current_owner!=-1} {
		if {[get_diplomacy $current_owner $my_owner]=="neutral"} {
			catch {
				ai exec $current_owner "
					set iNeutralGnomeStoleItem $my_owner
					set rStolenItem $item
					set vStolenPos \{[get_pos this]\}
				"
			}
		}
	}
	set_owner $item $my_owner {change_owner_fail}
	return true
}

proc change_owner_fail {} {
	log "SET_OWNER FAILED ([get_objname this]) [get_ref this]"
	evt_zwerg_break_proc
}

proc beam_from_inv_to_pos {item pos} {
	if {![obj_valid $item]} {
		return
	}
	if {[inv_find_obj this $item] < 0} {
		return
	}

	if {[vector_dist3d [get_pos this] $pos] > 2.0} {
		return
	}

	global current_weapon_item current_weapon_out current_shield_out current_shield_item
	if { $current_weapon_item == $item } {
		set current_weapon_out 0
		set current_weapon_item 0
	}
	if { $current_shield_item == $item } {
		set current_shield_out 0
		set current_shield_item 0
	}


	global current_lock_obj
	inv_rem this $item
	if {[get_objclass $item] == "Schatzbuch"} {
	//Schatzbuch soll über dem Boden schweben
		set pos [vector_add $pos "0 -0.15 0"]
		call_method $item initiate $pos
	} else {
		set_posbottom $item $pos
	}
	set_visibility $item 1
	set_hoverable $item 1
	if {$current_lock_obj==$item} {
		set current_lock_obj 0
	}
	set_lock $item 0

	// Container generell ausleeren, sonst können böse Bugs entstehen (Zwerg mit voller Kiepe hebt volle Kiepe auf...)
	if {[get_class_type [get_objclass $item]] == "transport"} {
		log "[inv_list $item]"
		foreach invitem [inv_list $item] {
			inv_rem $item $invitem
			set_visibility $invitem 1
			set_hoverable $invitem 1
			set_posbottom $invitem [vector_fix [get_pos $item]]
			log "removed $invitem from container"
		}
	}
}



// leert das gesamte Inventory

proc beamto_world_all {} {
	foreach item [inv_list this] {
		// zusätzliches inv_find_obj, weil beamto_world u.U. mehrere Items ablegt (bei Kiepen mit Inhalt z.B.)
		if {[inv_find_obj this $item] >= 0} {
			beamto_world $item [get_roty this]
		}
	}
}


proc beamto_world {item args} {
	unlock_item
	global current_weapon_item current_weapon_out current_shield_out current_shield_item
	if { $current_weapon_item == $item } {
		set current_weapon_out 0
		set current_weapon_item 0
	}
	if { $current_shield_item == $item } {
		set current_shield_out 0
		set current_shield_item 0
	}

	set_lock $item 0
	link_obj $item

	if {$args == ""} {
		set roty [get_roty this]
	} else {
		set roty $args
	}

	if {[get_boxed $item]} {
		set abst 0.8
	} else {
		set abst 0.5
	}

	set npos [ vector_add [get_pos this] "[expr {-sin($roty)*$abst}] 0 [expr {cos($roty)*$abst}]" ]
	set errorMsg [catch {
		inv_rem this $item
	} ]
	catch {
		call_method $item change_owner [get_owner this]
	}
	if {[get_objclass $item] == "Schatzbuch"} {
		call_method $item initiate $npos
	} else {
		set_posbottom $item [vector_fix $npos]
	}

    from_wall $item

	set_visibility $item 1
	set_hoverable $item 1

	// Container generell ausleeren, sonst können böse Bugs entstehen (Zwerg mit voller Kiepe hebt volle Kiepe auf...)
	if {[get_class_type [get_objclass $item]] == "transport"} {
		log "[inv_list $item]"
		foreach invitem [inv_list $item] {
			inv_rem $item $invitem
			set_visibility $invitem 1
			set_hoverable $invitem 1
			if {[get_objclass $invitem] == "Schatzbuch"} {
				call_method $invitem initiate [vector_fix $npos]
			} else {
				set_posbottom $invitem [vector_fix $npos]
			}
			from_wall $invitem
			log "removed $invitem from container"
		}
	}
	return true
}


//Diese Procedure testet, ob item nicht in der Wand steckt. Gegebenfalls wird item nach vorne verschoben
proc from_wall {item} {
	log "from_wall fuer $item"
    if {![get_gnomeposition this]} {return}

    set x [get_posx $item]
    set y [get_posy $item]
    set z [get_posz $item]
    set bboxz [lindex [get_negbbox $item] 2]
    set checkpoint [expr $z + $bboxz - 1.0]
    set hmappoint [get_hmap $x $y]
    if {$hmappoint > $checkpoint} {
    	set diff [expr $hmappoint - $checkpoint]
        set_posz $item [expr $z + $diff]
    }
}



// Gegenstand wird aufgehoben (inklusive hinlaufen usw.)
// - Hamster werden automatisch erschossen, wenn möglich
// - funktioniert auch für Gegenstände im Lager

proc pickup {item} {
	if {![obj_valid $item]} {
		return false
	}

	if {[inv_find_obj this $item] != -1} {
		return true
	}

	if {[inv_check this $item] == 0} {
		tasklist_add this "play_anim leftright"
		tasklist_add this "play_anim dontknow"
		return false
	}

	if { [get_instore $item]} {
		return [pickup_from_store $item]
	} elseif { [is_contained $item] } {
		return false
	}

	if { [get_objclass $item] == "Hamster"  && ![get_attrib $item paralyzed] && ![get_attrib $item farmed]} {
		// Hamster
		if {[inv_find this "Steinschleuder"] >= 0} {
			tasklist_add this "shoot $item"
			return true
		} else {
			call_method $item activate_gnomesensor
			tasklist_add this "walk_near_item $item 0.6 0.2 2"
		}

	} else {
		// normale items
		tasklist_add this "walk_near_item $item 0.6 0.2"
	}

	tasklist_add this "rotate_towards $item"
	tasklist_add this "play_anim_pickup $item"
	tasklist_add this "take_item $item"

	lock_item $item

	return true
}

proc convert {item} {
	if {![obj_valid $item]} {
		return false
	}

	if {[inv_find_obj this $item] != -1} {
		return true
	}

	if {[inv_check this $item] == 0} {
		return false
	}

	if { [get_instore $item]} {
		return false
	} elseif { [is_contained $item] } {
		return false
	}

	tasklist_add this "walk_near_item $item 0.6 0.2"

	tasklist_add this "rotate_towards $item"
	tasklist_add this "play_anim_pickup $item"
	set own [get_owner this]
	tasklist_add this "set_item_owner $item $own"

	return true
}

proc set_item_owner {item owner} {
	set_owner $item $owner {change_owner_fail}
	return true
}

proc shoot {item} {
	if { [is_contained $item] || ![inv_check this $item]} {
		return false
	}
	if { [inv_find this "Steinschleuder"] != -1 } {
		tasklist_add this "change_tool Steinschleuder 0"
		tasklist_add this "walk_near_hamster $item"
		tasklist_add this "rotate_towards $item"
		tasklist_add this "shoot_anim $item"			;// shoot_anim ist mit Schleuder gemergt
	} else {
		return false
	}
	return true
}

proc shoot_anim {item} {
	global current_tool_item
	set wpnid [get_weapon_id $current_tool_item true]
	set_weapon_class this $wpnid
	change_tool_finish_in		;// Steinschleuder weg, weil schon in der Ani drin!
	set fresult [fight_setactions_ballistic this $item "state_enable [get_ref this]"]
	set_weapon_class this 0
	log "shootres: $fresult"
	if { [string first "attack" $fresult] != -1 } {
		tasklist_add this "shoot_result $item"
		return true
	}
	tasklist_add this "change_tool 0"
	return false
}

proc shoot_result {item} {
	if { [get_ballisticresult this] == 1 } {
		call_method $item paralyze
		tasklist_add this "pickup $item"
		tasklist_add this "change_tool 0"
		return true
	}
	tasklist_add this "change_tool 0"
	return false
}

proc play_anim_pickup {item} {
	if {![obj_valid $item]} {
		 return false
	}

	if {[vector_dist3d [get_pos this] [get_pos $item]] > 2.0 || ![inv_check this $item]} {
		return false
	}

	if {[get_gnomeposition this]} {
		play_anim takewall
	} else {
		if {[expr {[get_posy this] - [get_posy $item]}] > 0.4} {
			play_anim put
		} else {
			play_anim bend
		}
	}

	return true
}


// Gegenstand aus der Welt ins Inventar des Zwerges befördern

proc take_item {item} {
	global current_worklist

	if {![obj_valid $item] || ![inv_check this $item]} {
		// Objekt ist ungültig oder kann nicht aufgehoben werden
		tasklist_clear this
		if {[get_gnomeposition this] == 0} {
			play_anim scout
		}
		gnome_failed_work this
		return false
	}
	
	set objclass [get_objclass $item]
	set objtype  [get_class_type $objclass]
	if {$objtype == "elevator"  ||  $objtype == "production"  ||  $objtype == "energy"  ||
		$objtype == "store"     ||  $objtype == "protection"} {
		
		if {![get_boxed $item]} {
			tasklist_clear this
			gnome_failed_work this
			return false
		}
	}
	
	set mypos [get_pos this]
	set itempos [get_pos $item]

	if {$objclass == "Hamster"} {
		if {[get_attrib $item farmed]} {
			// Hamster ist in der Farm - aufheben erfolgreich
			call_method $item catch_farmhamster
			// weiterlaufen in die checks weiter unten
		} elseif {[get_attrib $item paralyzed]} {
			// Hamster ist tot
			// weiterlaufen in die checks weiter unten
		} elseif {[vector_dist3d $mypos $itempos] <= 1.0} {
			// Hamster ist sehr nah
			beamto_inv $item
			return true
		} else {
			// nochmal versuchen!!!
			pickup $item
			return true
		}
	}

	if {[get_gnomeposition this]} {
		if {[lindex $mypos 2]>[lindex $itempos 2]+2||[vector_dist $mypos $itempos]>2.0} {
			// Gewöhnlicher Gegenstand: zu weit weg an Wand!
			set current_worklist {}
			//log "Cant take it: $item [get_gnomeposition this] ($mypos) ($itempos)"
			tasklist_clear this
			gnome_failed_work this
			return false
		}
	} elseif {[vector_dist3d $mypos $itempos] > 3.0} {
		// Gewöhnlicher Gegenstand: zu weit weg!
		set current_worklist {}
		tasklist_clear this
		play_anim bowllose
		gnome_failed_work this
		return false
	}

	beamto_inv $item

	// CaptureTheFlag-Hack
	if {[get_objclass $item] == "Flagge"} {
		link_obj $item this 7
	}

	return true
}


proc putdown_anim {} {
	if {[get_gnomeposition this]} {return putwall} {return bend}
}


// legt Gegenstand vor dem Zwerg ab bzw. legt Gegenstand an gewünschter Position ab

proc putdown {item {pos 0}} {
	if {![obj_valid $item]} {
		return false
	}

	if {[inv_find_obj this $item] < 0} {
		return false
	}

	if { $pos == 0 } {
		// putdown an Position des Zwerges
		set angle ""
		tasklist_add this "play_anim [putdown_anim]"
		tasklist_add this "beamto_world $item $angle"
	} else {
		// putdown an bestimmter Position

		tasklist_add this "set_objworkicons this arrow_down [get_objclass $item]; walk_near_item \{$pos\} 0.7"
		tasklist_add this "rotate_towards \{$pos\}"
		tasklist_add this "play_anim benda"
		tasklist_add this "beam_from_inv_to_pos \{$item\} \{$pos\}"
		tasklist_add this "play_anim bendb"
	}

	return true
}



// legt Gegenstand vor dem Zwerg ab bzw. legt Gegenstand an gewünschter Position ab
// diese Version trägt die Befehle am Anfang der Tasklist ein, so dass das
// Kommando in der Tasklist korrekt expandiert werden kann

proc putdown_tasklist {item {pos 0}} {
	if {![obj_valid $item]} {
		return false
	}

	if {[inv_find_obj this $item] < 0} {
		return false
	}

	if { $pos == 0 } {
		// putdown an Position des Zwerges
		set angle ""
		tasklist_addfront this "beamto_world $item $angle"
		tasklist_addfront this "play_anim [putdown_anim]"
	} else {
		// putdown an bestimmter Position

		tasklist_addfront this "play_anim bendb"
		tasklist_addfront this "beam_from_inv_to_pos \{$item\} \{$pos\}"
		tasklist_addfront this "play_anim benda"
		tasklist_addfront this "rotate_towards \{$pos\}"
		tasklist_addfront this "set_objworkicons this arrow_down [get_objclass $item]; walk_near_item \{$pos\} 0.7"
	}

	return true
}



// Erntet den angegebenen Pilz

proc harvest {item} {
	global tttgain_Pilz tttinfluence_Pilz

	if {![obj_valid $item]} {
		return false
	}

	lock_item $item
	set fitness 2
	foreach atr "atr_Hitpoints atr_Nutrition atr_Alertness atr_Mood" {
		if {[get_attrib this $atr]<0.8} {
			set fitness 1
		}
	}

	if {[get_attrib this atr_Alertness]<0.4} {
		set fitness 0
	}

	switch $fitness {
		0 {set maxloops 9.4; set minloops 3; set maxexp $tttinfluence_Pilz; set ani tired}
		1 {set maxloops 5.4; set minloops 1; set maxexp [expr {0.5*$tttinfluence_Pilz}]; set ani ""}
		2 {set maxloops 4.4; set minloops 1; set maxexp [expr {0.4*$tttinfluence_Pilz}]; set ani fit}
	}
	set abschlag [expr {(1+[get_attrib $item PilzAge])*0.25}]
	set cur_HP [get_attrib $item atr_Hitpoints]

	set cur_exp [hmin $maxexp [get_attrib this exp_Holz]]
	if {[inv_find this Kettensaege] < 0} {
		set loops [hmax 1 [hf2i [expr {($minloops+$abschlag*($maxloops-$minloops)*(1-$cur_exp/$maxexp))*$cur_HP}]]]
	} else {
		set loops 1
	}
	set exp_incr [lindex [lindex $tttgain_Pilz 0] 1]
	set exp_incr [expr {$exp_incr * $cur_HP * [clan_exp_factor exp_Holz] / $loops}]

	set damage [expr {-$cur_HP / $loops}]
	set ppos [get_pos $item]
	set cpos [get_pos this]
	set roty [get_roty $item]
	if {abs($roty)>0.5} {
		if {$roty<0.0} {
			set targetdummy 1
		} elseif {$roty<2} {
			set targetdummy 4
		} elseif {$roty<3} {
			set targetdummy 3
		} elseif {$roty<4} {
			set targetdummy 1
		} else {
			set targetdummy 0
		}
	} elseif {abs([get_posy $item]-[get_posy this])>5} {
		set targetdummy 0
	} else {
		set cposx [get_posx this]
		set pposx [get_posx $item]
		if {$cposx-$pposx<-5} {
			set targetdummy 0
		} elseif {$cposx-$pposx>5} {
			set targetdummy 4
		} else {
			set angle [vector_angle [get_pos $item] [get_pos this]]
			set targetdummy 4
			for {set tryangle -2.749} {$tryangle<$angle} {fincr tryangle 0.7853} {incr targetdummy -1}
			if {$targetdummy<0} {incr targetdummy 8}
			if {$targetdummy==2} {incr targetdummy -1}
			if {$targetdummy==6} {incr targetdummy}
		}
	}
	//log "walking to Pilz $item dummy $targetdummy ($roty)"

	if {[inv_find this Kettensaege] < 0} {
		// Pilz fällen ohne Kettensäge (also mit der Axt)

		tasklist_add this "change_tool Axt"
		tasklist_add this "walk_dummy $item $targetdummy"
		tasklist_add this "check_valid $item"
		tasklist_add this "check_lockedbyother $item"
		tasklist_add this "play_anim standstill"
		tasklist_add this "rotate_towards $item"
		tasklist_add this "play_anim hack${ani}start"

		tasklist_add this "change_particlesource this 8 26 {0 0 0.5} {0 0 0} 24 5 0 1"

		for {set i 1} {$i<=$loops} {incr i} {
			if {$loops>15*rand()&&$loops!=$i} {
				tasklist_add this "play_anim hackaccidenta;check_pilz_valid $item"
			} else {
				tasklist_add this "play_anim hack${ani}loop;check_pilz_valid $item"
				tasklist_add this "set_particlesource this 8 5"
			}
			if {$i==$loops} {
				set cmd add_expattrib
			} else {
				set cmd add_attrib
			}
			tasklist_add this "call_method $item attr_add atr_Hitpoints $damage;$cmd this exp_Holz $exp_incr"
		}
		tasklist_add this "play_anim hack${ani}end"
		tasklist_add this "play_anim standstill"
		tasklist_add this "free_particlesource this 8"		;// wird möglicherweise nicht ausgeführt, still better than nothing
		tasklist_add this "kill_item $item"
		tasklist_add this "change_tool 0"
	} else {
		// Pilz fällen mit Kettensäge

		tasklist_add this "change_tool Kettensaege"
		tasklist_add this "walk_dummy $item $targetdummy"
		tasklist_add this "check_valid $item"
		tasklist_add this "check_lockedbyother $item"
		tasklist_add this "play_anim standstill"
		tasklist_add this "rotate_towards $item"
		tasklist_add this "change_tool_finish_in; play_anim sawhorstart"		;// Saege ist in Anim schon drin

		tasklist_add this "change_particlesource this 8 17 {0 0 0.7} \{[vector_roty {0 0 0.1} [get_roty this]]\} 64 8 0 1"

		for {set i 1} {$i<=$loops} {incr i} {
			tasklist_add this "set_particlesource this 8 1"
			tasklist_add this "play_anim sawhorloop"
			tasklist_add this "set_particlesource this 8 0;check_pilz_valid $item"
			if {$i==$loops} {
				set cmd add_expattrib
			} else {
				set cmd add_attrib
			}
			tasklist_add this "call_method $item attr_add atr_Hitpoints $damage;$cmd this exp_Holz $exp_incr"
		}
		tasklist_add this "play_anim sawhorend"
		tasklist_add this "play_anim standstill"
		tasklist_add this "free_particlesource this 8"		;// wird möglicherweise nicht ausgeführt, still better than nothing
		tasklist_add this "kill_item $item"
	}

	return true
}

proc check_pilz_valid {item} {
	if {![obj_valid $item]} {
		log "Pilz $item was already invalid ([get_objname this])"
		tasklist_clear this
		free_particlesource this 8
	}
}

proc mine {item {cnt 3}} {
	set fitness 2
	lock_item $item
	tasklist_add this "change_tool Spitzhacke"
	tasklist_add this "walk_near_item $item 0.7"
	tasklist_add this "play_anim standstill"
	tasklist_add this "rotate_towards $item"
	tasklist_add this "mine_rep $item $cnt"
	return true
}

proc mine_rep {item cnt} {
	global current_worktask
	if {$current_worktask=="mine"&&[get_remaining_sparetime this]>0.0} {unlock_item;return}
	if { $cnt >= 1 } {
		if { [obj_valid $item] } {
			set cont [get_attrib $item PilzAge]
			if {$cont > 0} {
				state_disable this
				set itemclass [get_objclass $item]
				if {$itemclass=="Eisenerzbrocken"||$itemclass=="Golderzbrocken"} {
					set animname mann.buddeln_unten_metall
					set attr [hmin [get_attrib this exp_Metall] 0.4]
				} else {
					set animname mann.buddeln_unten_stein
					set attr [hmin [get_attrib this exp_Stein] 0.4]
				}
				set_anim this $animname 0 2
				set animcnt [expr {1.2*int((0.5-$attr)*11.0)}]
				action this wait $animcnt "state_enable this;call_method $item mine [get_ref this]"
				if {0||$cont==1} {
					log [list [get_objname this] found: [obj_query this "-class \{Steinbrocken Kohlebrocken Eisenerzbrocken Golderzbrocken Kristallerzbrocken\} -range 10 -limit 1 -flagneg locked"]]
					if {[get_remaining_sparetime this]<0.1&&[set nextbrock [obj_query this "-class \{Steinbrocken Kohlebrocken Eisenerzbrocken Golderzbrocken Kristallerzbrocken\} -range 10 -limit 1 -flagneg locked"]]} {
						tasklist_clear this
						tasklist_add this "mine $nextbrock [get_attrib $item PilzAge]"
						tasklist_add this "set_objworkicons this Spitzhacke [string map {brocken {}} [get_objclass $nextbrock]]"
						log "[get_objname this]: [state_get this] [tasklist_list this]"
						unlock_item
					}
				} else {
					tasklist_add this "mine_rep $item [expr {$cnt - 1}]"
					if {rand()<0.1} {tasklist_add this "play_anim tired"}
					tasklist_add this "walk_near_item $item 0.7 0.2"
					tasklist_add this "rotate_towards $item"
				}
			}
		}
	}
}

proc open_box {item} {
	global own
	lock_item $item
//	log "Open_Box wurde aufgerufen item = $item"
	if {[get_objclass $item]=="Schatzbuch"} {
		if {[inv_find_obj this $item] == -1} {
			set_owner $item $own {change_owner_fail}
			tasklist_add this "walk_pos \{[vector_add [get_pos $item] {0 0 -1.6}]\}"
			tasklist_add this "rotate_tofront"
		} else {
			tasklist_add this "rotate_tofront"
			tasklist_add this "play_anim [putdown_anim]"
			set opt2 ""
			tasklist_add this "beamto_world $item $opt2"
		}
		tasklist_add this "call_method $item set_standartanim"
		tasklist_add this "play_anim read"
		tasklist_add this "read_book $item"
	} else {
		tasklist_add this "walk_near_item $item 0.6 0.2"
		tasklist_add this "rotate_towards $item"
		tasklist_add this "if {\[get_attrib $item PilzAge\]} {tasklist_clear this}"
		tasklist_add this "check_switcher_dist \{[get_pos $item]\}"
		//if {[random 1.0] < 0.5} {
			tasklist_add this "play_anim kickb"   ;#treten
			tasklist_add this "call_method $item release_content [get_owner this]"
		//} else {
		//	tasklist_add this "change_tool Axt"
		//	tasklist_add this "play_anim hammerstart"
		//	tasklist_add this "play_anim hammerloopholz"
		//	tasklist_add this "play_anim hammerend"
		//	tasklist_add this "call_method $item release_content [get_owner this]"
		//	tasklist_add this "change_tool 0"
		//}
	}
}


// Magisches Buch lesen

proc read_book {item} {
	if {![obj_valid $item]} {
		return 0
	}

	//set_owner $item [get_owner this]

	set gain [call_method $item get_gain]
	set erfBez [lindex $gain 0]
	if {[string range $gain 0 2]=="exp"} {
		set ins "exp"
	} else {
		set ins ""
	}
	set old_value [get_attrib this $erfBez]
	log "OldValue in:$erfBez :$old_value"
	set errMsg [catch {eval "add_${ins}attrib this $gain"}]
	if {$errMsg} {
		log "FEHLER $errMsg: add_${ins}attrib ([get_objname this]) $gain"
	}
	set punktezahl [expr {int(([get_attrib this $erfBez] - $old_value)*100)}]
	log "Punktezahl in:$erfBez :$punktezahl"
	if {[lindex $gain 0]=="atr_Mood"} {
		if {[lindex $gain 1]>=0} {
			tasklist_add this "play_anim talks"
		} else {
			tasklist_add this "play_anim bowllose"
		}
	}

	if {[net localid] == [get_owner this]} {
		//Meldung in NewsTicker ausgeben
		set buchname [lmsg [get_objname $item]]
		log "Z_PROCS: buchname = $buchname"
		set erfahrung [call_method $item get_erfahrungsbezeichnung]

		if {$erfahrung == "Stimmung"} {
			if {[call_method $item get_sign] == 0} {
				set ntMessage [lmsg_param "-1-:+-2-%in-3-(-4-)" "-1- [get_objname this] -2- $punktezahl -3- $erfahrung -4- {[lmsg $buchname]}"]
			} else {
				set ntMessage [lmsg_param "-1-:-2-%in-3-(-4-)" "-1- [get_objname this] -2- $punktezahl -3- $erfahrung -4- {[lmsg $buchname]}"]
			}
		} else {
			set ntMessage [lmsg_param "-1-:+-2-in-3-(-4-)" "-1- [get_objname this] -2- $punktezahl -3- $erfahrung -4- {[lmsg $buchname]}"]
		}


		 set id [newsticker new [get_owner this] -text "$ntMessage" -time [expr {3 * 60}]]
		set ref [get_ref this]
		newsticker change $id -click "newsticker delete $id;
										if {\[obj_valid $ref\] } {
											if {\[get_objclass $ref\] == \"Zwerg\"} {
												set x \[get_posx $ref\];
												set y \[get_posy $ref\];
												set_view \$x \[expr \$y -1\] 0 -0.35 0
											}
										}"
	}
}


// Zwerg trinkt den angegebenen Trank Referenz

proc drinkpotion {potion_ref} {
	if {![obj_valid $potion_ref]} {
		return 0
	}

	set idx [inv_find_obj this $potion_ref]
	if {$idx == -1} {
		return 0
	}

	inv_rem this $idx
	link_obj $potion_ref this 0
	set_hoverable $potion_ref 0
	call_method $potion_ref set_animation drink
	state_disable this
	action this anim drinkpotion "
		call_method $potion_ref reaction [get_ref this]; link_obj $potion_ref; del $potion_ref; state_enable this
	" " call_method $potion_ref reaction [get_ref this]; link_obj $potion_ref; del $potion_ref; state_enable this "

	return 1
}


// Zwerg wird liebestoll (vom Liebestrank ausgelöst)

proc become_lovecrazed {} {
	global love_potion_taken
	set love_potion_taken 1
	log "[get_objname this] is now love-crazed..."
}


// Zwerg wird fruchtbar (vom Fruchtbarkeitstrank ausgelöst)

proc become_fertile {} {
	global fertility_potion_taken
	set fertility_potion_taken 1
	log "[get_objname this] is now ferile..."
}

// beam_back:
// mit get_beambackpos kann die aktuelle Position des Zwerges gespeichert werden (z.B. bevor er etwas aufbaut)
// mit beam_back wird er an eine passende Stelle in der Nähe der gespeichetern Pos zurückgebeamt (z.B. nach dem Aufbauen)

proc get_beambackpos {} {
	global beam_backto
	set beam_backto [get_pos this]
	return true
}

proc clear_beambackpos {} {
	global beam_backto
	set beam_backto 0
}

proc beam_back {} {
	global beam_backto
	if { $beam_backto == 0 } {
		return true
	}

	set bbpos [get_place -center $beam_backto -rect -2 -4 2 4 -nearpos $beam_backto -except this -materials false]
	log "beamback pos is $bbpos; original position was $beam_backto"
	if {[vector_dist3d $bbpos $beam_backto] < 5.5} {
		set_pos this $bbpos
	} else {
		set_pos this $beam_backto
	}

	set beam_backto 0
	return true
}



proc pack {item} {
	global current_worklist
	log "PACK: item = $item, this = [get_ref this], [get_objname this]"
//	if {0&&![get_buildupstate $item]} {
//		set flag 0
//		set near_obj [obj_query $item "-class Zwerg -boundingbox 4"]
//		log "PACK: near_obj: = $near_obj"
//		if {[llength $near_obj] > 0} {
//			for {set i 0} {$i<[llength $near_obj]} {incr i} {
//					set obj_tasks [tasklist_list [lindex $near_obj $i]]
//					if {[lsearch -regexp $obj_tasks "prod_buildup $item"]>0 || [lsearch -regexp $obj_tasks "prod_buildup_rep $item"]>0} {
//							//log "DIE AUFBAU VON $item MACHT [get_objname [lindex $near_obj $i]]"
//							set z_obj [lindex $near_obj $i]
//							tasklist_clear $z_obj
//							tasklist_add $z_obj "prod_builddown $item"
//							set_objworkicons $z_obj arrow_down [get_objclass $item]
//							set flag 1
//							break
//					}
//			}
//		}
//		if {$flag > 0} {
//		tasklist_clear this
//		set current_worklist {}
//		log "Pack abgebrochen: this = [get_ref this], item = $item"
//		return true
//		}
//	}
	lock_item $item
	stop_prod
	set bstep [call_method $item get_buildupstep]
	//log "PACK: bstep = $bstep"
	if { $bstep } {
		//set ppos [get_pos $item]
		//set dummy [call_method $item get_build_dummy $bstep]
		//set nextpoint [lreplace [vector_add $ppos [get_linkpos $item $dummy]] 1 1 [lindex $ppos 1]]
		//set place [get_place -center $nextpoint -rect -8 -2 8 8 -nearpos [get_pos this] -except this -materials 0]
		//if {[lindex $place 0]>0} {
		//	tasklist_add this "walk_pos \{$place\}"
		//} else {
			if {[lsearch "Aufzug Dampfaufzug Kristallaufzug" [get_objclass $item]] != -1} {
				set dummy0 [vector_add [get_pos $item] [get_linkpos $item 0]]
				set wall_pos [lreplace $dummy0 2 2 [get_hmap [vector_unpackx $dummy0] [vector_unpacky $dummy0]]]
				set pos [vector_fix $wall_pos]
				tasklist_add this "walk_pos \{ $pos \}"

			} else {
				tasklist_add this "walk_dummy $item 0"
			}
		//}
	} else {
		log "pack packed item $item [get_objname this]"
		tasklist_add this "play_anim [putdown_anim]"
	}
	tasklist_add this "prod_builddown $item"
	tasklist_add this "unlock_item"
	return true
}


proc unpack_pos_unfixed {item pos asbox} {
	if {![obj_valid $item]} {
		return false
	}

	if {[inv_find_obj this $item] < 0} {
		return false
	}

	lock_item $item
	stop_prod
	tasklist_add this "walk_outoftransit"
	tasklist_add this "rotate_toback"
	tasklist_add this "play_anim [putdown_anim]"
	tasklist_add this "exp_transp_increase"

	if {[expr {!$asbox}]} {
		tasklist_add this "prod_buildup_new $item \{$pos\}"
	} else {
		tasklist_add this "inv_rem this $item; set_pos $item \[vector_add \{$pos\} { 0 0 0 } \]; set_visibility $item 1 "
		tasklist_add this "unlock_item"
	}
	return true
}

proc start_prod {prodplace} {
//	log "Work start"
	if { $prodplace != 0 } {
		if { $prodplace != "dig" } {
			set tsklist [call_method $prodplace start_prod_tasklist [get_ref this]]
			foreach itm $tsklist {
				tasklist_add this $itm
			}
		}
	}
}


// beendet alle eventuell laufenden Arbeits- und Produktionsaufgaben
// muss *NACH* tasklist_clear aufgerufen werden!

proc stop_prod {{toolchange 1}} {
	global current_workplace current_worklist reprod_actionlock walkfail_tasks
	global last_disturb sparetime_talkevents myref event_repeat

    beam_back
	set event_repeat 0
	if {[gettime]-$last_disturb>5} {
		switch [state_get this] {
			"sparetime_dispatch" {
				global stt_dst_spare current_occupation
				add_attrib this atr_Mood $stt_dst_spare
				lappend sparetime_talkevents wis
				if {[lsearch {eat fun slp} $current_occupation]!=-1} {sparetime_${current_occupation}_end}
			}
			"reprod" {global stt_dst_sex;add_attrib this atr_Mood $stt_dst_sex;lappend sparetime_talkevents ubr}
			"interaction" {global stt_dst_talk;add_attrib this atr_Mood $stt_dst_talk;lappend sparetime_talkevents ubt}
			"work_dispatch" {global stt_dst_work;add_attrib this atr_Mood $stt_dst_work;lappend sparetime_talkevents ubw}
			default {global stt_dst_idle;add_attrib this atr_Mood $stt_dst_idle}
		}
		set last_disturb [gettime]
	}

	set reprod_actionlock 0
	unlock_item
	foreach item [inv_list this] {
		set objtp [get_objtype $item]
		if {[lsearch {production elevator energy store protection} $objtp]!=-1} {
			set_prod_unpack $item 0
		}
	}
	dig_resetid this
	placelock_rem $myref
	placelock_rem [expr $myref + 65536]
	enable_auto_fanim
	dig_endanim
	sparetime_reset_clothes
	if {$toolchange} {change_tool 0; change_tool 0 1}
	set walkfail_tasks ""

	if { $current_workplace != 0 }	{
		if { $current_workplace != "dig" } {
//			log "production interrupted"
			set tsklist [call_method $current_workplace stop_prod_tasklist [get_ref this]]
			foreach itm $tsklist {
				tasklist_add this $itm
			}
		}
		set current_workplace 0
	}
	set current_worklist ""
	set_particlesource this 1 0
}

proc act_when_idle {} {
	global idle_action_list myref current_occupation
	if {[get_gnomeposition this]} {
		set rect {-0.7 -1.0 -0.5 0.7 1.0 0.5}
		set ol [obj_query this -class {Zwerg Baby} -boundingbox $rect]
		if {$ol==0} {return 0}
		set found 0
		foreach o $ol {
			if {[get_walkresult $o]!=2} {
				set found 1
				break
			}
		}
		if {$found} {
			set mpos [get_pos this]
			foreach p {{0 1.3 0} {0 -1.3 0} {-1.3 0 0} {1.3 0 0}} {
				set sp [vector_add $mpos $p]
				set sh [get_hmap [lindex $sp 0] [lindex $sp 1]]
				lrep sp 2 $sh
				if {[obj_query this -pos $sp -class {Zwerg Baby} -boundingbox $rect]==0} {
					if {![placelock_check $sp 0.7 $myref]} {
						walk_pos $sp
						return 1
					}
				}
			}
		}
		return 0
	}
	set idle 1
	if {[placelock_check [get_pos this] 0.8 $myref]} {
		log "[get_objname this] leaves locked place at [get_pos this]"
		walk_random_or_aside [mp_irandom leaveradius 3 2 4]
		set idle 0
	} else {
		set ol [lnand 0 [obj_query this -class {Zwerg Baby} -boundingbox {-0.6 -0.3 -1.2 0.6 0.3 1.2}]]
		foreach o $ol {
			if {[get_walkresult $o]!=2} {
			//	log "[get_objname this] leaves occupied place at [get_pos this]"
				walk_random_or_aside [mp_irandom leaveradius 3 2 4]
				set idle 0
				break
			}
		}
	}
	if {$idle} {
		if {$idle_action_list==""} {
			return 0
		} else {
			eval [lindex $idle_action_list 0]
			lrem idle_action_list 0
		}
	}
	set current_occupation "idle"
	return 1
}

proc shortlock_dummy {place dummy} {
	global myref
	//log "locking placedummy $dummy of $place for [get_objname this] ($myref)"
	placelock_set [vector_add [get_pos $place] [get_linkpos $place $dummy]] 1 $myref
}

proc shortlock_pos {pos} {
	global myref
	//log "locking pos ($pos) for [get_objname this] ($myref) [get_pos this]"
	placelock_set $pos 1 $myref
}

proc change_weapon_finish_in {} {
	global current_weapon_out
	global current_weapon_item
	if {$current_weapon_item > 0} {
		set_visibility $current_weapon_item 0
		set_hoverable $current_weapon_item 1
		link_obj $current_weapon_item
	}
	//log "weaponingesteckt[get_objname this]: $current_weapon_item $current_weapon_out"
	set current_weapon_out 0
	set current_weapon_item 0
	set_weapon_class this 0
}

proc change_shield_finish_in {} {
	global current_shield_out
	global current_shield_item
	if {$current_shield_item > 0} {
		set_visibility $current_shield_item 0
		set_hoverable $current_shield_item 1
		link_obj $current_shield_item
	}
	set current_shield_out 0
	set current_shield_item 0
	set_shield_class this 0
}

proc weapon_inanim {} {
	global current_weapon_item
	if { [check_method [get_objclass $current_weapon_item] get_in] } {
		call_method $current_weapon_item get_in
	}
}

proc weapon_putin {} {
	global current_weapon_out
	if { $current_weapon_out != 0 } {
    	tasklist_add this "weapon_inanim"
    	tasklist_add this "play_anim toolputaway_a"
    	tasklist_add this "change_weapon_finish_in"
    	tasklist_add this "play_anim toolputaway_b"
    	state_trigger this task
    }
}

proc shield_putin {} {
	global current_shield_out
	if { $current_shield_out != 0 } {
    	tasklist_add this "play_anim toolputaway_a"
    	tasklist_add this "change_shield_finish_in"
    	tasklist_add this "play_anim toolputaway_b"
    	state_trigger this task
    }
}


// alle Werkzeuge weg

proc hide_tools {} {
	global current_tool_item current_tool_class current_lefttool_item current_lefttool_class
	if { $current_tool_item != 0 } {
		link_obj $current_tool_item
		set_visibility $current_tool_item 0
		del $current_tool_item
		set current_tool_item 0
		set current_tool_class 0
	}
	if { $current_lefttool_item != 0 } {
		link_obj $current_lefttool_item
		set_visibility $current_lefttool_item 0
		del $current_lefttool_item
		set current_lefttool_item 0
		set current_lefttool_class 0
	}
}

proc wpn_out {} {
	global current_weapon_item current_weapon_out
	hide_tools
	if { $current_weapon_item!=$current_weapon_out } {
		link_obj $current_weapon_item this 0
		//log "link_obj $current_weapon_item this 0"
		set current_weapon_out $current_weapon_item
		set_visibility $current_weapon_item 1
		set_hoverable $current_weapon_item 0
		if { [check_method [get_objclass $current_weapon_item] get_out] } {
			call_method $current_weapon_item get_out
		}
	}
	fight_hat_out
}

proc fight_hat_out {} {
	global current_weapon_item current_weapon_out current_muetze_name is_wearing_divingbell is_counterwiggle

	if { $is_counterwiggle != 0 } {
		return 1													;// in Counterwiggles keine Muetzenaktionen
	}

	if {$is_wearing_divingbell != 0} {
		return 1													;// Taucherglocke verhindert alle Mützenaktionen
	}

	if { [get_objclass this] == "Zwerg" } {
		set muetze [call_method this get_nameofmuetze "fight"]
		if {$current_muetze_name == $muetze} { 							;// nichts zu tun
			return true
		}
		del_current_muetze
		create_muetze $muetze
	}
}

proc shld_out {} {
	global current_shield_item current_shield_out
	if { $current_shield_item!=$current_shield_out } {
		link_obj $current_shield_item this 1
		//log "link_obj $current_shield_item this 1"
		set current_shield_out $current_shield_item
		set_visibility $current_shield_item 1
		set_hoverable $current_shield_item 0
	}
}

proc weapon_shield_takeout {{bAnim 0}} {
	global current_weapon_item current_weapon_out current_shield_item current_shield_out current_tool_class current_tool_item current_lefttool_class current_lefttool_item weapon_range
	set weapon_not_out [expr {$current_weapon_item!=$current_weapon_out}]
	set shield_not_out [expr {$current_shield_item!=$current_shield_out}]

	//log "-- $current_weapon_item != $current_weapon_out -- $bAnim"

	// Ballisic Waffen sind in die Anim gemerged
	if { $weapon_range > 1.0 } {
		fight_hat_out
		return 1
	}

	if { $bAnim } {

		call_method this set_special_feeling_fanim fight_v[irandom 4]

		set finishcode [list]
		if { $weapon_not_out || $shield_not_out } {
			state_disable this
			action this anim tooltakeout_a "wpn_out
											shld_out
											action this anim tooltakeout_b \"state_enable [get_ref this];call_method [get_ref this] fight_idle_anim\"
											" "wpn_out;shld_out"
				return 1
		} else {
			hide_tools
			fight_hat_out
		}

	} else {
		wpn_out
		shld_out
		return 0
	}
	return 0
}

proc weapon_ballistic_takeout {} {
	global current_weapon_item current_weapon_out
	set weapon_not_out [expr {$current_weapon_item!=$current_weapon_out}]
	if {$weapon_not_out} {
		state_disable this
		action this anim tooltakeout_a "hide_tools
										//link_obj $current_weapon_item this 1
										//set_visibility $current_weapon_item 1
										fight_hat_out
										action this anim tooltakeout_b \"state_enable [get_ref this]\"
										" "fight_hat_out"
			set current_weapon_out $current_weapon_item
			return
	}
}



// nur von change_tool und sequencer aufgerufen: altes Werkzeug weg

proc change_tool_finish_in {} {
	global current_tool_class current_tool_item current_lefttool_class current_lefttool_item
	if { $current_tool_item != 0 } {
		set_visibility $current_tool_item 0
		link_obj $current_tool_item
		del $current_tool_item
	}
	if { $current_lefttool_item != 0} {
		set_visibility $current_lefttool_item 0
		link_obj $current_lefttool_item
		del $current_lefttool_item
	}
	set current_tool_class 0
	set current_tool_item 0
	set current_lefttool_class 0
	set current_lefttool_item 0
}


// nur von change_tool und sequencer aufgerufen: neues Werkzeug ran

proc change_tool_finish_out {outobj {hand 0}} {
	if {![obj_valid $outobj]} {
		log "WARNING: z_procs.tcl : change_tool_finish_out : parameter outobj is an invalid object!"
		return
	}

	if {$hand} {
		set insert "left"
	} else {
		set insert ""
	}
	global current_${insert}tool_class
	global current_${insert}tool_item

	change_weapon_finish_in
	change_shield_finish_in

	if { $outobj != 0 } {
		link_obj $outobj this $hand
		set_visibility $outobj 1
	}
	set current_${insert}tool_class [get_objclass $outobj]
	set current_${insert}tool_item $outobj
}


// nur von change_tool aufgerufen: altes Werzeug weg, neues Werkzeug ran

proc change_tool_finish_inout {outobj {hand 0}} {
	if {![obj_valid $outobj]} {
		log "WARNING: z_procs.tcl : change_tool_finish_out : parameter outobj is an invalid object!"
		return
	}

	if {$hand} {
		set insert "left"
	} else {
		set insert ""
	}
	global current_${insert}tool_class
	global current_${insert}tool_item

	if {$hand} {
		set cti $current_lefttool_item
	} else {
		set cti $current_tool_item
	}

	change_weapon_finish_in
	change_shield_finish_in

	set_visibility $cti 0
	link_obj $cti
	del $cti
	link_obj $outobj this $hand
	set_visibility $outobj 1
	set current_${insert}tool_class [get_objclass $outobj]
	set current_${insert}tool_item $outobj
}


// Werkzeug wechseln
// change_tool <Werkzeugklassenname / 0=Weglegen> [Hand re=0; li=1] [Animation abspielen 0/1]

proc change_tool {toolclass {hand 0} {playanim 1}} {
	if {$hand} {
		global current_lefttool_class
		set ctc $current_lefttool_class
	} else {
		global current_tool_class
		set ctc $current_tool_class
	}
	if {[lsearch {Hal Ess} [string range $ctc 0 2]]!=-1} {
		set playanim 0
	}

//	log "$current_tool_class --> $toolclass"
	if {$toolclass==$ctc} {
		return 						;// nichts zu tun
	}

	if {$toolclass != 0} {
		set fall 1
		set outobj [new $toolclass]
	} else {
		set fall 0
	}

	// Fall:
	// 0 - Tool weglegen
	// 1 - Tool in die Hand nehmen
	// 2 - Tool weglegen; hat schon eins in der Hand
	// 3 - Toll in die Hand nehmen, hat schon eins in der Hand


	if {$ctc != 0} {
		set fall [expr {$fall + 2}]
	}

	if {[get_gnomeposition this]} {
		set insert "wall"
	} elseif {$hand} {
		set insert "left"
	} else {
		set insert ""
	}
	if {$toolclass=="Presslufthammer"||$ctc=="Presslufthammer"} {
		if {$insert=="left"} {
			set insert ""
		}
		set outa_anim airhamm${insert}starta
		set outb_anim airhamm${insert}startb
		set ina_anim airhamm${insert}enda
		set inb_anim airhamm${insert}endb
	} else {
		set outa_anim tooltakeout${insert}_a
		set outb_anim tooltakeout${insert}_b
		set ina_anim toolputaway${insert}_a
		set inb_anim toolputaway${insert}_b
	}

	if {$playanim} {
		switch [expr {1&$fall}] {
			0 {tasklist_addfront this "play_anim $inb_anim"}
			1 {tasklist_addfront this "play_anim $outb_anim"}
		}
	}
	switch $fall {
		1 {tasklist_addfront this "change_tool_finish_out $outobj $hand"}
		2 {tasklist_addfront this "change_tool_finish_in"}
		3 {tasklist_addfront this "change_tool_finish_inout $outobj $hand"}
	}
	if {$playanim} {
		switch [expr {2&$fall}] {
			0 {tasklist_addfront this "play_anim $outa_anim"}
			2 {tasklist_addfront this "play_anim $ina_anim"}
		}
	}
	//log "[get_objname this]: changed tool to $toolclass"
	return
}


// Verändert das Aussehen eines Tool (vorausgesetzt, das Tool unterstützt dies)

proc change_tool_look {look} {
	global current_tool_item current_tool_class
	if {$current_tool_item} {
		if {[check_method $current_tool_class change_look]} {
			call_method $current_tool_item change_look $look
			return true
		}
	}
	return false
}


proc set_idle_anim {} {
	if { [get_diedinfight this] } {
		return
	}
	if { [get_gnomeposition this] == 0 } {
			switch [hf2i [mp_random standanim 0.0 4]] {
				0 	{set_anim this mann.stand_anim_a 0 2 ;#set idle anim}
				1	{set_anim this mann.stand_anim_b 0 2 ;#set idle anim}
				2	{set_anim this mann.stand_anim_c 0 2 ;#set idle anim}
				3	{set_anim this mann.stand_anim_d 0 2 ;#set idle anim}
			}
	} else {
		if {abs([get_roty this]-3.14)>0.1} {set_roty this 3.14}
		set_anim this mann.kletterstand_anim 0 2 ;#set idle anim
	}
}

proc check_valid {item} {
	if {![obj_valid $item]} {
		log "Objekt $item ist nicht mehr gültig!"
		tasklist_clear this
		return 0
	}
	return 1
}

proc check_lockedbyother {item} {
	global current_lock_obj
	if [obj_valid $item] {
		if [get_lock $item] {
			if {$current_lock_obj!=$item} {
				log "[get_objname $item] ist gelockt!"
				tasklist_clear this
			}
		}
	}
}

proc kidnap {item} {
	global myref
	if {![obj_valid $item]||[vector_dist3d [get_pos this] [get_pos $item]]>2} {
		return
	}
	play_anim talk[lindex {acpoc acpob acntc acngb renga} [irandom 5]]e
	set_owner $item [get_owner this]
	call_method $item youre_kidnapped $myref
}

proc handle_bomb {item} {
	if {[get_attrib $item PilzAge]<0.5} {
		if {[obj_query $item -class CS_BombPlace -range 5 -limit 1]} {
			set status 0
		} else {
			tasklist_add this "play_anim talk[lindex {acngae rengbe} [irandom 2]]"
			return
		}
	} else {
		set status 1
	}
	tasklist_add this "walk_near_item $item 1.0 0.2"
	tasklist_add this "rotate_towards $item"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "play_anim workfloormetall"
	tasklist_add this "call_method $item activate $status"
}

proc get_info {name} {
	global info_string
	if { ![info exists info_string] } {set info_string ""}
	foreach item $info_string {
		set inam [lindex $item 0]
		set ival [lindex $item 1]
		if { $name == $inam } {
			return $ival
		}
	}
	return 0
}

proc calc_age {} {
	global birthtime is_old gnome_gender
	set gnome_age [expr {[gettime]-$birthtime}]
	if {$gnome_age>23*1800} {
		if {$is_old<2} {
	//		if {$gnome_gender=="male"} {set var 5} {set var 5}
			set_textureanimation this 2 5
			set is_old 2
		}
	} elseif {$gnome_age>22*1800} {
		if {$is_old<1} {
			if {$gnome_gender=="female"} {
				global haircolor
				set var [lindex {15 6 14 16 16 6 6 16 16 15 14 16 14 6} $haircolor]
			} else {
				set var 5
			}
			set_textureanimation this 2 $var
			set is_old 1
		}
	}
	return $gnome_age
}

proc set_stoned_textures {bool} {
	global gnome_gender myhairs myglasses current_muetze_ref clothing haircolor hatcolor
	if {$bool} {
		if {$gnome_gender=="male"} {
			set texvars {19 21 10 20 30}
		} else {
			set texvars {13 12 17 16 30}
		}
		for {set i 0} {$i<5} {incr i} {
			set_textureanimation this $i [lindex $texvars $i] 0 0
		}
		if {$myhairs||[obj_valid $myhairs]} {
			set_textureanimation $myhairs 0 [lindex $texvars 2] 0 0
		}
		if {$current_muetze_ref||[obj_valid $current_muetze_ref]} {
			set_textureanimation $current_muetze_ref 0 9 0 0
		}
	} else {
		set_textureanimation this 0 [scan [string index $clothing 0] %x] 0 0
		set_textureanimation this 1 [scan [string index $clothing 1] %x] 0 0
		set_textureanimation this 2 $haircolor 0 0
		set_textureanimation this 3 0 0 0
		set_textureanimation this 4 0 0 0
		if {$myhairs||[obj_valid $myhairs]} {
			set_textureanimation $myhairs 0 $haircolor 0 0
		}
		if {$current_muetze_ref||[obj_valid $current_muetze_ref]} {
			set_textureanimation $current_muetze_ref 0 $hatcolor 0 0
		}
	}
}


// alle Items freisetzen

proc inv_rem_all {} {
	// Container generell zuerst ausleeren, sonst können böse Bugs entstehen
	foreach item [inv_list this] {
		if {[get_class_type [get_objclass $item]] == "transport"} {
			foreach invitem [inv_list $item] {
				inv_rem $item $invitem
				set_visibility $invitem 1
				set_hoverable $invitem 1
				set_posbottom $invitem [vector_fix [get_pos $item]]
				from_wall $invitem
				log "removed $invitem from container"
			}
		}
	}

	foreach item [inv_list this] {
		log "Gnome dies: dropping [get_objname $item]"
		inv_rem this $item
		set_hoverable $item 1
		set_selectable $item 1
		set_physic $item 1
		set_pos $item [vector_add [get_pos this] {0 -1 0}]
		from_wall $item
		set_visibility $item 1
	}
}



proc destroy {} {
	global reprod_partner logoff_code

	del_current_muetze

	// Partner vom Ableben informieren

	if {$reprod_partner != 0} {
		call_method $reprod_partner reprod_removepartner
	}

	if { [catch { eval $logoff_code }] } {
		log "[get_objname this]: Error in logoff_code: $logoff_code"
	}

	inv_rem_all
	stop_prod
	gnome_failed_work this
	state_trigger this
	state_disable this
	state_trigger this

	destruct this
	create_particlesource 8 [get_pos this] {0.0 -0.15 0.0} 128 1
	create_particlesource 8 [vector_add [get_pos this] [get_linkpos this  6] ] {0.0 -0.15 0.0} 128 1
	create_particlesource 8 [vector_add [get_pos this] [get_linkpos this 10] ] {0.0 -0.15 0.0} 128 1
	create_particlesource 8 [vector_add [get_pos this] [get_linkpos this 11] ] {0.0 -0.15 0.0} 128 1
	del this
}


proc lmsg_param {txt paramlist} {
	log "LMSG_PARAM_VOR: txt = $txt, paramlist = $paramlist"
	set text [lmsg $txt]
	log "LMSG_PARAM_NACH: text = $text"
	set message [string map $paramlist $text]
	log "Nach tring map: message = $message"
	return $message
}

set last_eventtype "none"
proc notify_userevent {} {
	global last_eventtype last_userevent_time
	set last_userevent_time [gettime]
	set last_eventtype "user"
}

proc notify_autoevent {} {
	global last_eventtype
	set last_eventtype "auto"
}

proc get_last_eventtype {} {
	global last_eventtype
	return $last_eventtype
}

#############################TitanicPumpe####################################
proc pumpe_activate {pumpe} {
	call_method $pumpe activate
	return true
}

