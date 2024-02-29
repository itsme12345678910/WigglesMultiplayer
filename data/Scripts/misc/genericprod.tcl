// genericprod.tcl

if {[in_class_def]} {
// class definition part

    set BOXED_CLASSES "production energy store elevator protection"
	member BOXED_CLASSES
	set noitemclasses "ZeltGrabsteinMittelalterschlafzimmerMittelalterwohnzimmerMittelalterbadIndustrieschlafzimmerIndustriewohnzimmerIndustriebadLuxusschlafzimmerLuxuswohnzimmerLuxusbad"

	def_event evt_timer_delete
	handle_event evt_timer_delete {
		destruct this
		del this
	}


	def_event evt_timer_init
	handle_event evt_timer_init {
		if {[get_boxed this] == 0} {
			if {[check_method [get_objclass this] init] == 1} {
			    call_method this init
			} else {
				log "WARNING: no init method for class [get_objclass this]"
			}
		}
	}



	// Event: Produktionsbuttons geklickt

	def_event evt_btn_on
    handle_event evt_btn_on {
		if {$current_itemtype != 0  &&  $current_worker != 0} {
			if {![obj_valid $current_worker]} {
				log "WARNING: genericprod.tcl : current_worker is != 0 but object invalid!"
				set current_worker 0
				return
			}
			if {[get_prod_slot_cnt this $current_itemtype] == 0} {
				log "genericprod.tcl : production breaked; current worker is [get_objname $current_worker]"
				set_event $current_worker evt_zwerg_break -target $current_worker
			}
			if {[get_prod_pack this] == 1} {
				log "genericprod.tcl : packing scheduled, breaking production; current worker is [get_objname $current_worker]"
				set_event $current_worker evt_zwerg_break -target $current_worker
				set_prod_pack this 1 		;// weil der Zwerg stop_prod sagt :-)
			}
		} else {
			free_unneeded_items
		}
	}


	// Event: Gegenstand aus der nahen Umgebung als Material in die PS aufnehmen

	def_event evt_prodplace_transferprod
	handle_event evt_prodplace_transferprod {
		//log "Prodplace [get_objname this] getting event evt_prodplace_tranferprod"

    	set item [event_get this -subject1]

    	if {![obj_valid $item]} {
    		return
    	}

    	if {[inv_find_obj this $item] >= 0} {
    		return
    	}

		if {[is_contained $item]  ||  [get_lock $item]} {
			log "genericprod.tcl : evt_prodplace_tranferprod : cannot take item $item !"
			return
		}

		take_item $item
	}

	// Event: Zwerg zuweisen
	def_event evt_task_workprod_prefer
	handle_event evt_task_workprod_prefer {
		prod_gnome_preferred_workplace [event_get this -subject1] [get_ref this]
	}

	def_event evt_hit_sound_notify
	handle_event evt_hit_sound_notify {
		sound play [event_get this -text1] 1.0 [get_pos this]
	}

	;# definition von productionscommandos der classe
	proc add_prod_item item {
		def_attrib Bp$item 0 1 0
		def_attrib At$item 0 1 0
	}


	def_attrib [get_class_name] 0 10000 0

	set classname [get_class_name]
	if {[string first [get_class_type $classname] "productionstoreenergyprotection"]!=-1&&[string first $classname $noitemclasses]==-1} {
		set tttsection_tocall $classname
		call scripts/misc/techtreetunes.tcl
		method prod_items {} "return \{[subst \$tttitems_$classname]\}"
		method prod_preinvented {} "return \{[subst \$tttpreinv_$classname]\}"
		set meth_def "switch \$item \{"
		foreach item [subst \$tttitems_$classname] {
			set tttsection_tocall $item
			call scripts/misc/techtreetunes.tcl
			append meth_def " \"$item\" \{return \{[subst \$tttmaterial_$item]\}\}"
		}
		append meth_def "\}"
		method prod_item_materials {item} $meth_def
		//method prod_item_materials {item} "
		//	global tttmaterial_$item
		//	return [subst \$tttmaterial_$item]
		//}
		method prod_item_tools {item} {
			return [list]
		}
		method prod_item_attribs {item} {
			global tttinvent_$item
			return [subst \$tttinvent_$item]
		}
		method prod_item_exp_incr item {
			global tttgain_$item
			return [list [subst \$tttgain_$item]]
		}
		method prod_item_exp_infl item {
			global tttinfluence_$item
			return [list [subst \$tttinfluence_$item]]
		}
		method prod_item_number2produce item {
			global "tttnumber2produce_$item"
			if {[info exists "tttnumber2produce_$item"] != 0} {
				return [subst \$tttnumber2produce_$item]
			} else {
				return 1
			}
		}
		catch {unset classname tttmaterial_$classname tttinvent_$classname tttgain_$classname tttinfluence_$classname tttpreinv_$classname tttitems_$classname}
	} else {unset classname}
	set itemlst [call_method_static [get_class_name] prod_items]
	set firstitem [lindex $itemlst 0]
	foreach itemtype $itemlst {
		add_prod_item $itemtype
	}
	if { [check_method [get_class_name] prod_preinvented] } {
		set itemlst [call_method_static [get_class_name] prod_preinvented]
		foreach itemtype $itemlst {
//			log "preinvented: $itemtype (Invented_$itemtype)"
			def_attrib Bp$itemtype 0 1 1
		}
	} else {
		if {$firstitem != "" } {def_attrib Bp$firstitem 0 1 1}
//		log " Christoph *****: - $firstitem"
	}

	;# classen destructor
	obj_exit {
		add_owner_attrib [get_owner this] [get_objclass this] -1
		stop_production 1
	}

	method change_owner {new_owner } {
		set_owner this $new_owner
	}


    // gibt alle Partikelquellen frei, damit sie während der Abbauanimation
    // nicht stören
    // evtl. noch für andere Sachen nützlich???

    method prepare_packtobox {} {
		set_light this 0			;# abschalten eventuell vorhandener lichtquellen
		;# gib alle partikelquellen frei
		for {set index 0} {$index<16} {incr index} { free_particlesource this $index }
    }

	method packtobox {} {
		// falls classe eine Methode local_packtobox besitzt
       log "PACKTOBOX - [get_ref this]: [get_objname this]"
		if {[check_method [get_objclass this] local_packtobox] == 1} {
		    call_method this local_packtobox
		} else {
			stop_production	1
		}
		set_fogofwar this -1 -1		;# die maschine deckt den fog of war nicht mehr auf
		set_light this 0			;# abschalten eventuell vorhandener lichtquellen
		;# gib alle partikelquellen frei
		for {set index 0} {$index<16} {incr index} { free_particlesource this $index }
		set_boxed this 1
	}

	method unpackfrombox {} {
		set_rot this {0 0 0}
		//set_fogofwar this 8 8
		if {[info exist tttfow_x] && [info exist tttfow_y]} {
			log "FOW fuer [get_objclass [get_ref this]] mit x = $tttfow_x und y = $tttfow_y wird aufgedeckt"
			set_fogofwar this $tttfow_x $tttfow_y
		}

		tasklist_clear this
		set_boxed this 0
		hide_obj_ghost this
		if {[check_method [get_objclass this] init] == 1} {
		    call_method this init
		} else {
			log "WARNING: no init method for class [get_objclass this]"
		}
	}

	method set_buildupstep {val} {
		global buildup_step max_buildup_step
		if { $val == "max" } {
			set buildup_step [expr $max_buildup_step + 1]
		} else {
			set buildup_step $val
		}
		info_progress_prod this $buildup_step [expr {$max_buildup_step+1}]
		set_buildupanim
	}

	method check_first_strike {caller} {
		return 1
	}

	method destroy {} {
		set cname [string tolower [get_objclass this]]
		catch {set cname [lindex [split $standard_anim "."] 0]}

		if { [catch {	set_anim this $cname.zerstoert 0 1 }] } {
			catch {	set_anim this $cname.kaputt 0 1 }
		}

		delete_transportlogic this
		call_method this prepare_packtobox
		call_method this show_damage			;# nochmal, weil prepare_packtobox die Partikel löscht
		
		foreach item [inv_list this] {
			release_item $item
			if {[get_posx $item] <= 0  ||  [get_posy $item] <= 0} {
				set_pos $item [get_pos this]
			}
		}
		
		set_selectable this 0
		set_hoverable this 0
		if {[get_selectedobject] == [get_ref this]} {
			set_selectedobject 0
		}

		if {[net localid] == [get_owner this]} {
			set id [newsticker new [get_owner this] -text "[lmsg [get_objclass this]] [lmsg wurdezerstoert]" -time [expr {3 * 60}]]
			newsticker change $id -click "newsticker delete $id; set_view [get_posx this] [expr {[get_posy this] -1}] 0 -0.35 0"
		}

		set_owner this -1
		timer_event this evt_timer_delete -repeat 1 -interval 1 -userid 0 -attime [expr [gettime]+ 120]
	}


	method show_damage {} {
		global damage_dummys maxhitpoints
		set hitpoints [get_attrib this atr_Hitpoints]
		if {$damage_dummys != 0} {
			set mindummy [lindex $damage_dummys 0]
			set maxdummy [lindex $damage_dummys 1]
			set maxfires [expr $maxdummy - $mindummy + 1]
			set nroffires [expr int((1 - ($hitpoints / $maxhitpoints)) * $maxfires)]
			//log "[get_objname this] hp: $hitpoints maxhp:$maxhitpoints mind:$mindummy maxd:$maxdummy"
			for {set i 0} {$i < $nroffires} {incr i} {
				set srcnr [expr 15 - $i]
				set lnknr [expr $mindummy + $i]
				change_particlesource this $srcnr 0 {0 0 0} {0 0 0} 32 1 0 $lnknr
				set_particlesource this $srcnr 1
			}
			for {set i $nroffires} {$i < $maxfires} {incr i} {
				set srcnr [expr 15 - $i]
				set lnknr [expr $mindummy + $i]
				free_particlesource this $srcnr
			}
		}
	}

	method Editor_Set_Info {ifo} {
		global info_string
		set info_string $ifo
		eval_info $ifo
	}

	method get_attackapproach_range {} {
		return 2.0
	}


	// Gegenstand in der PS als Material hinzufügen

	method take_item {item} {
		take_item $item
	}


	method get_buildupstep {} {
		global buildup_step
		if {$buildup_step == "max"} {
			set buildup_step [expr $max_buildup_step + 1]
		}
		return $buildup_step
	}


	method get_maxbuildupstep {} {
		global max_buildup_step
		return $max_buildup_step
	}


	method get_buildupanim {} {
		global buildup_step
		if { $buildup_step == 0 } {
			//beim Aufzug darf er nicht stehen
			if {[lsearch "Aufzug Dampfaufzug Kristallaufzug" [get_objclass this]] != -1} {
				return oben_rechtsstein
			}
			return digdownstone
		}
		global buidup_anis
		return [lindex $buidup_anis [expr $buildup_step - 1]]
	}

	method get_repairanim {step} {
		global buidup_anis
		if { $step == 0 } {
			return digdownstone
		}
		return [lindex $buidup_anis [expr $step - 1]]
	}


	method inc_buildupstep {val 1} {
		global buildup_step
		incr buildup_step $val
		info_progress_prod this $buildup_step 4
		set_buildupanim
		return $buildup_step
	}

	// default implementations

	method get_itemtasklist {itemtype gnomeref} {
		set current_worker $gnomeref
		if {[string range $itemtype 0 1]=="Bp"} {
			set current_itemtype [string range $itemtype 2 end]
		} else {
			set current_itemtype $itemtype
		}
		//log "ITEMTYPE of [get_objname this] set to $current_itemtype ($itemtype)"
		return [prod_getitemtask $itemtype]
	}

	method prod_progress {} {
		info_progress_prod this $prod_currentstep $prod_maxsteps
		incr prod_currentstep
	}

	method prod_progressjump {increment} {
		incr prod_currentstep $increment
		incr prod_maxsteps -$increment
		info_progress_prod this $prod_currentstep $prod_maxsteps
	}


	method finish_itemprod {itemtype} {
		global job_finished
		
		info_end_prod this
		set job_finished 0
		 
		stop_production
	}

	method start_prod_tasklist {zwerg} {
		return [list]
	}

	method stop_prod_tasklist {zwerg} {
		stop_production
		return [list]
	}


	method get_current_worker {} {
		global current_worker
		return $current_worker
	}

	method get_build_dummy {index} {
		global build_dummys
		return [lindex $build_dummys [expr {$index-1}]]
	}

	//method get_max_buildup_step {} {
	//	global max_buildup_step
	//	return $max_buildup_step
	//}

	method get_energyclass {} {
		return $myenergyclass
	}

	method_const  get_max_buildup_step {} {
		global max_buildup_step
		return $max_buildup_step
	}

	method nt_conquer {} {
		set id [newsticker new [get_owner this] -text "[lmsg [get_objclass this]] [lmsg wirdangegriffen]" -time [expr {3 * 60}]]
		newsticker change $id -click "newsticker delete $id; set_view [get_posx this] [expr {[get_posy this] -1}] 0 -0.35 0"
	}

	method nt_conquer_inform {} {
		set id [newsticker new [get_owner this] -text "[lmsg [get_objclass this]] [lmsg anfeindverloren]" -time [expr {3 * 60}]]
		newsticker change $id -click "newsticker delete $id; set_view [get_posx this] [expr {[get_posy this] -1}] 0 -0.35 0"
	}

	//Wird nur für Aufzüge verwendet
	method letfalldown {} {
		if {[lsearch "Aufzug Dampfaufzug Kristallaufzug" [get_objclass this]] != -1} {
			log "LETFALLDOWN: [get_objname this]"
			set_posy this [expr [get_posy this] + 2]
		}
	}
	
	
	// Aufruf teilt der PS mit, das dieser Auftrag ab sofort als erledigt anzusehen ist, auch wenn er später
	// noch abgebrochen wird
	
	method job_finished {} {
		global job_finished
		set job_finished 1
	}


} else {

	set_physic this 1				;# die punktphysik einschalten
	set_viewinfog this 1
	set_selectable this 1
	set_hoverable this 1
	set_placesnapmode this 0
	set_buildupstate this 1
#	set_collision this 1
	add_owner_attrib [get_owner this] [get_objclass this] 1

	set maxhitpoints 1
	set_attrib this hitpoints $maxhitpoints 	:# Hitpoints bei 100% - entspricht einem gesunden Zwerg

	set prod_maxsteps 		0
	set prod_currentstep 	0
	set buildup_step max
	set max_buildup_step 	0
	set damage_dummys 		0
	set current_worker 		0
	set current_itemtype 	0
	set job_finished		0				;// wird gesetzt, wenn die Aufgabe eigentlich erledigt ist, Produktion aber noch läuft
	set info_string 		""

	set myclassname [get_objclass this]
	set tttenergyclass_$myclassname 0

	call scripts/misc/animclassinit.tcl
	set classname [get_objclass this]
	if {[check_method $classname prod_items]} {
		set tttitems_$classname ""
		set tttsection_tocall $classname
		call scripts/misc/techtreetunes.tcl
		foreach prod_item [call_method this prod_items] {
			set tttsection_tocall $prod_item
			call scripts/misc/techtreetunes.tcl
		}
		set tttsection_tocall $classname
		call scripts/misc/techtreetunes.tcl

	}
	if {[info exist tttfow_x] && [info exist tttfow_y]} {
		set_fogofwar this $tttfow_x $tttfow_y
	}

	set myenergyclass [subst \$tttenergyclass_$myclassname]

	// nimmt das item als Material in diese PS auf

	proc take_item {item} {
		if {![obj_valid $item]} {
			return false
		}

		if {[inv_find_obj this $item] >= 0} {
			return true
		}

		if {[is_contained $item]  ||  [get_lock $item]} {
			return false
		}

		set pos [get_pos $item]
		inv_add this $item
		set_pos $item $pos
		set_hoverable $item 0
		set_selectable $item 0
		set_visibility $item 1

		return true
	}



	// wirft ein item aus der PS heraus (d.h. macht es für andere wieder verfügbar)

	proc release_item {item} {

		if {![obj_valid $item]} {
			return false
		}

		set opos [get_pos $item]
		inv_rem this $item
		set_visibility $item 1
		set_physic $item 1
		set_hoverable $item 1
		set_instore $item 0				;# weil es auch vom Lager benutzt wird!
		set_prodalloclock $item 0
		set_lock $item 0
		set_pos $item $opos

		return true
	}

	// wirft ein item einer bestimmten Klasse aus der PS heraus (d.h. macht es für andere wieder verfügbar)

	proc release_itemtype {itemclass} {
		set idx [inv_find this $itemclass]

		if {$idx < 0} {
			return false
		}

		release_item [inv_get this $idx]

		return true
	}


	// liefert eine Liste meines Inventorys, als Klassennamenliste (z.B. "Pilzstamm Pilzstamm Pilzstamm Stein")

	proc get_inv_class_list {} {
		set result ""
		foreach item [inv_list this] {
			lappend result [get_objclass $item]		}
		return $result
	}


	// gibt items, die im Moment nicht benötigt werden, wieder frei

	proc free_unneeded_items {} {
		global current_worker

		if {[get_boxed this]} {
			return
		}

		if {$current_worker != 0} {
			return
		}

		if {[get_objclass this] == "Lager"} {
			return
		}

		// feststellen, was wir überhaupt brauchen
		set itemneedlist ""
		set myowner [get_owner this]
		foreach slot [call_method this prod_items] {
			if {[get_owner_attrib $myowner Bp$slot] > 0} {
				set i [get_prod_slot_cnt this $slot]
				if {$i > 0} {
					set materiallist [call_method this prod_item_materials $slot]
					while {$i > 0} {
						set itemneedlist [concat $itemneedlist $materiallist]
						incr i -1
					}
				}
			}
		}

		set itemhavelist [get_inv_class_list]
		//if {$itemneedlist!=""} {log "[get_objname this] - items needed: $itemneedlist"}
		//if {$itemhavelist!=""} {log "[get_objname this] - items I have: $itemhavelist"}

		// von den vorhandenen die benötigten abziehen
		foreach item $itemneedlist {
			set idx [lsearch $itemhavelist $item]
			if {$idx >= 0} {
				lrem itemhavelist $idx
			}
		}

		if {$itemhavelist!=""} {log "[get_objname this] - items to throw out: $itemhavelist"}
		foreach item $itemhavelist {
			release_itemtype $item
		}
	}


	// stoppt die Produktion

	proc stop_production {{complete 0}} {
		global int_task_list workers_list current_worker current_itemtype ANIM_LOOP job_finished

		if {$job_finished} {
			log "genericprod : stop_production : breaking production, but job is finished - sending info_end_prod this (PS [get_ref this])"
			info_end_prod this
		}
		set job_finished 0

		// Partikelquellen am Zwerg löschen (Feuerunfall?)

		if {$current_worker != 0} {
			if {[obj_valid $current_worker]} {
				free_particlesource $current_worker 5
				free_particlesource $current_worker 4
			}
		}

		set current_worker 0
		set current_itemtype 0


		if {[get_objtype this]=="production"} {
			set_buildupanim
		}

		// Evtl. Aufräum-Procs der Produktionsstätte aufrufen (Partikel löschen etc.)

		if {[check_method [get_objclass this] stop_anim_timer]} {
			call_method this stop_anim_timer
		}

		if {[check_method [get_objclass this] deinit_production]} {
			call_method this deinit_production
		}

		// alle Halbzeuge löschen, evtl. unsichtbare Items sichtbar machen
		// arg "deplazierte" Gegenstände auf vernünftige Positionen am Boden zurückholen
		// muss und darf nicht mit dem Lager gemacht werden!

		if {[get_objclass this] != "Lager"} {
   	   		if {[check_method [get_objclass this] prod_get_invention_dummy]} {
			    set dummy [call_method this prod_get_invention_dummy]
			} else {
				set dummy 2
			}

			foreach item [inv_list this] {
				if {[lsearch "Halbzeug_holz Halbzeug_stein Halbzeug_eisen Halbzeug_tablett Halbzeug_kiste Halbzeug_trank Halbzeug_bier Halbzeug_topf Halbzeug_pfanne" [get_objclass $item]] != -1} {
					inv_rem this $item
					del $item
				} else {
				    set_visibility $item 1
				    if {[expr { [get_posy this] - [lindex [get_posbottom $item] 1] }] > 1.0} {
						set pos [vector_add [get_linkpos this $dummy] "[random -0.2 0.2] 0 [random -0.3 0.3]"]
						set pos [vector_add [get_pos this] $pos]
						set_posbottom $item $pos

						log "genericprod.tcl : stop_production : Position von [get_objname $item] korrigiert."
				    }
				}
			}
		}

		// nicht mehr benötigte Gegenstände freigeben

		free_unneeded_items

        if {$complete} {
			foreach slot [call_method this prod_items] {
				set_prod_slot_cnt this $slot 0
			}
			foreach item [inv_list this] {
				release_item $item
			}
		}
	}


	// wird vom Zwerg aufgerufen, wenn er die Arbeit an der PS beginnt

	proc prod_getitemtask {itemtobuild} {
		global prod_maxsteps prod_currentstep

		set prod_maxsteps 	 0
		set prod_currentstep 0

		if { [string compare -length 2 $itemtobuild "Bp"] == 0 } {
			// Erfindung machen

			if {[get_prod_slot_cnt this [string range $itemtobuild 2 end]] == 0} {
				return ""
			}

			set completelist [list "prod_invent $itemtobuild"]
			lappend completelist "prod_finishitem $itemtobuild"
			info_start_prod this $itemtobuild
			set prod_maxsteps [llength $completelist]
			set prod_currentstep 1
			info_progress_prod this 1 $prod_maxsteps
			return $completelist
		}

		// echte Produktion

		if {[get_prod_slot_cnt this $itemtobuild] == 0} {
			return ""
		}

		set rlist [list]
		set completelist [call_method this prod_item_actions $itemtobuild]
		lappend completelist "prod_finishitem $itemtobuild"
		set prod_maxsteps [llength $completelist]
		set prod_currentstep 0

		info_start_prod this $itemtobuild
		info_progress_prod this 0 $prod_maxsteps

		return $completelist
	}



    // liefert eine Zahl zwischen 0.0 und 1.0 abhängig von den geforderten Erfahrungen
    // für eine Aufgabe (exp_infls) und den tatsächlichen des Zwerges
    // 0.0 - Minimalpunktzahl: der Zwerg hat keine der geforderten Erfahrungen
    // 1.0 - Maximalpunktzahl: der Zwerg erfüllt die Anforderungen vollkommen

   	proc prod_getgnomeexper {ref exp_infls} {
		set exp_infls [lindex $exp_infls 0]
		set exper 0.0 ;# David, arithmetrische Mittlung
		set explen [llength $exp_infls]
		foreach exp_infl $exp_infls {
			set attr [lindex $exp_infl 0]
			set curexp [get_attrib $ref $attr]
			set maxexp [lindex $exp_infl 1]
			if {$curexp < $maxexp} {
		    	set exper [expr {$exper + ([call_method $ref get_clan_exp_factor $attr] / $maxexp * $curexp)}]
		    } else {
			    fincr exper [call_method $ref get_clan_exp_factor $attr]
			}
		}
		if {$explen} {set exper [expr $exper / $explen]}
        return [expr $exper*0.7+[get_attrib $ref atr_Mood]*0.3]
	}


	proc eval_info {ifo} {
		foreach item $ifo {
			set nam [lindex $item 0]
			set val [lindex $item 1]
			switch $nam {
				hitpoints {set_attrib this atr_Hitpoints $val}
			}
		}
		call_method this show_damage
	}

	proc set_buildupanim {} {
		global buildup_step max_buildup_step standard_anim

		if {[get_boxed this]} {
			return
		}


		if { $buildup_step > $max_buildup_step } {
			set ani standard
		} else {
			switch $buildup_step {
				0		{ set ani bau_a }
				1		{ set ani bau_b }
				2		{ set ani bau_c }
				3		{ set ani bau_d }
				4		{ set ani bau_e }
				5		{ set ani bau_f }
				6		{ set ani bau_g }
				7		{ set ani bau_h }
				8		{ set ani bau_i }
				9		{ set ani bau_k }
				default	{ set ani standard }
			}
		}

		set cname [string tolower [get_objclass this]]
		catch {set cname [lindex [split $standard_anim "."] 0]}
		if {$cname=="grabstein"&&$ani=="standard"} {set ani [lindex [split $standard_anim "."] 1]}
		//log "genprod banim: $cname $ani $buildup_step $max_buildup_step"
		if { [catch {	set_anim this $cname.$ani 0 0	}] } {
			log "[get_objname this]: buildup-anim not found: $ani"
		}
		if {$buildup_step == "max"} {
			set buildup_step [expr $max_buildup_step + 1]
		}
		set buildinprogress [expr $buildup_step > $max_buildup_step]
		set_buildupstate this $buildinprogress
	}
}
