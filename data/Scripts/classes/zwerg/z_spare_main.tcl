// z_spare.tcl (classdef-Teil)
// occupations: idle work spare sleep eat fun
if {[in_class_def]} {
	
	state_enter sparetime_dispatch { 
		if {$state_log} {log "[get_objname this] entering state SPARETIME_DISPATCH (Muetze,change_tool 0)"}
		if {$state_shell} {print "[get_objname this] entering state SPARETIME_DISPATCH (Muetze,change_tool 0)"}
		if {$current_muetze_name != [call_method this get_nameofmuetze sparetime]} {
	//		log "[get_objname this]: CHANGE MUETZE SPARETIME in  state_enter"
			prod_change_muetze sparetime
		}
		if {$current_tool_item != 0} {
			tasklist_add this "change_tool 0"
		}
	}
	
	state sparetime_dispatch {
		if {$state_log} {log "[get_objname this] passing state code SPARETIME_DISPATCH"}
		if {$state_shell} {print "[get_objname this] passing state code SPARETIME_DISPATCH"}
		if { [tasklist_cnt this] } {
			set command [tasklist_get this 0]
			tasklist_rem this 0
	//		log "spare:$command"
			eval $command
			return
		}
		if {$sparetime_initialize} {
			log [gethours]:[get_objname this]:[get_worktime this]:[get_remaining_sparetime this]
			sparetime_time_log 1
			set state_code_counter 0
			set state_code_timeneed 0
			set time_count_start [gettime]
			set state_code_diff 0.0
			set current_worktask ""
			set last_event ""
			set event_repeat 0
			set sparetime_history {}
			set sparetime_goal_reached 2
			set sparetime_goal ""
			set sparetime_mingoal ""
			set sparetime_emergency 0
			set sparetime_emchange_initial 0
			set has_bathed 0
			set sparetime_disapp_slp 0
			set sparetime_eat_item 0
			set sparetime_disapp_fun 0
			set sparetime_funrelief 1.0
			set sparetime_disappointment 0.0
			set sparetime_disapp_rates 0
			set willing_to_reprod 0
			set current_task "idle"
			set sparetime_remembered_scv 0
			set sparetime_rest [hceil [get_remaining_sparetime this]]
			if {$last_spareleave<$time_count_start-100||$sparetime_future==""} {
				switch $sparetime_rest {
					0.0 {set sparetime_future ""}
					1.0 {set sparetime_future [lindex {eat slp} [irandom 2]]}
					2.0 {set sparetime_future [lrange {eat slp eat} [expr {$sparetime_initialize-1}] $sparetime_initialize]}
					3.0 {set sparetime_future [lrange {"" eat fun slp eat} $sparetime_initialize [expr {$sparetime_initialize+2}]]}
					4.0 {set sparetime_future {eat fun slp eat}}
					default {set sparetime_future {eat fun slp bth eat}}
				}
				if {$spt_bath_desire<3.0} {set sparetime_future [lnand "bth" $sparetime_future]}
				set spt_fun_stations 0
				set spt_fun_fail 0
				set spt_talk_fail 0
				set spt_talkfind_counter 0
			}
	//		log "[get_objname this]: $sparetime_future"
			set own [get_owner this]
			set sparetime_is_on 1
			set sparetime_initialize 0
			//set last_sparestate [gettime]
			return
		}
		//state_length_counting [expr {[gettime]-$last_sparestate}]
		//set last_sparestate [gettime]
		//set last_taskcnt [tasklist_cnt this]
		set idletimeout 0
		// Taskliste bearbeiten
		////////////// Verlassen des States zur Arbeit ////////////////////
		if { [get_remaining_sparetime this]==0.0} {
			sparetime_state_end
			sparetime_time_log 0
			return
		}
		prod_gnome_state this sparetime
		if { 0*[get_gnomeposition this] == 1 } {
			if {[walk_down_from_wall]} {
				set_anim this mann.kletterstand_anim 0 2
				state_disable this
				action this wait 2 {state_enable this}
			}
			return
		}
	//	if {$current_tool_item != 0} {
	//		tasklist_add this "change_tool 0"
	//	}
		//Axels Hack ab hier
		//Möglichkeiten überprüfen
		incr state_code_counter
		set vorher [gettime]
		fincr state_code_timeneed -$vorher
		set at_Hi [get_attrib this atr_Hitpoints]
		set at_Nu [get_attrib this atr_Nutrition]
		set at_Al [get_attrib this atr_Alertness]
		set at_Mo [get_attrib this atr_Mood]
		if { [sparetime_decide_occup] } {
			state_core_counting [expr {[gettime]-$vorher}]
			fincr state_code_timeneed [gettime]
			//set state_code_timeneed [expr $state_code_timeneed + [gettime] - $time_count_start]
			return
		}
	//	log "[get_objname this] [string range [expr ${timeplan_prog}.0/${timeplan_length}.0] 0 5]: $current_wish_occupation"
		state_core_counting [expr {[gettime]-$vorher}]
		if { [sparetime_reprod_check] } {
			state_triggerfresh this "reprod"
			if { $gnome_gender == "female" } {
				call_method $reprod_partner reprod_remote_act 0
			}
	//		state_triggerfresh $reprod_partner "reprod"
			fincr state_code_timeneed [gettime]
			//set state_code_timeneed [expr $state_code_timeneed + [gettime] - $time_count_start]
			return
		}
	//	log "SparetimeDispatch: $current_wish_occupation  $current_occupation"
		if {$current_wish_occupation != $current_occupation} {
			log "[get_objname this] $current_occupation -> $current_wish_occupation"
			if {[string first $current_occupation "slpeatillfunbth"]!=-1} {
				set vorher [gettime]
				sparetime_${current_occupation}_end
				state_code_counting [expr {[gettime]-$vorher}]
			}
			//if {$current_wish_occupation!="reprod"} {set willing_to_reprod 0}
			if {![act_when_idle]} {
				set current_occupation $current_wish_occupation
				set vorher [gettime]
				sparetime_${current_occupation}_start
				state_code_counting [expr {[gettime]-$vorher}]
			}
		} else {
			if {$declog&&[is_selected this]} {log "$current_occupation loops"}
			set vorher [gettime]
			sparetime_${current_occupation}_loop
			state_code_counting [expr [gettime]-$vorher]
		}
		fincr state_code_timeneed [gettime]
		//set state_code_timeneed [expr $state_code_timeneed + [gettime] - $time_count_start]
	}
	
	method get_sparetime_place {} {return $sparetime_current_place_ref}
	method get_sparetime_futurecnt {} {return [llength $sparetime_future]}
	method get_fun_mode {} {return $sparetime_fun_mode}
	method get_eat_count {} {return $sparetime_eat_count}
	method ask_for_talk {} {
		if {[llength $talk_partner]>2} {return 0}
		if {$spt_talk_desire<3.0} {return 0}
		//if {[lindex [sparetime_talk_next] 2]<0.0} {return 0}
		return $sparetime_talkanswer
	}
//	method get_funintents {} {return [lrange $sparetime_funintents 0 5]}
	method set_sparetime_base_avoid {nv} {set sparetime_base_avoid $nv}
	method check_is_talking {} {return $is_talking}
	method get_talk_desire {} {return $spt_talk_desire}
	method get_talk_partner {} {return $talk_partner}
	method get_talk_leader {} {return $talk_leader}
	method get_talk_status {} {return $talk_status}
	method set_talk_step {step} {sparetime_talk_setminstep $step}
	method get_talk_listener {} {return $talk_listener}
	method get_talk_sign {} {return $talk_sign}
	method start_talk {ref} {
		if {$talk_partner==""} {
			if {[get_walkresult this]==2} {
				state_disable this
				tasklist_clear this
			}
			sparetime_break_bytalk
			sparetime_talk_start $ref 0
			set spt_talk_count 0
		} else {
			sparetime_add_partner $ref
		}
		//state_enable this
	}
	method finish_talk {ref} {
		if {$ref==$talk_listener} {set talk_listener_away 1}
		sparetime_talk_remove $ref
	}
	method end_talk_too {} {
		sparetime_talk_end 0
	}
	method get_talk_urge {} {
		return [sparetime_talk_urge 0]
	}
	method search_for_issue {issue} {
		if {[talkissue this get $issue]<0.0} {return 1} {return 0}
	}
	method set_talk_status {status lead follow changing} {
		set talk_step $status
		set talk_leader $lead
		set talk_listener $follow
		set talk_imthe_leader 0
		if {$changing} {set talk_history [concat $status [lrange $talk_history 0 5]];set talk_imthe_leader 1}
	}
	method add_talk_partner {ref} {
		global talk_partner
		if {[land $ref $talk_partner]!=""} {
			log "FEHLER in method add_talk_partner [get_objname this]: ($talk_partner) $ref"
		}
		sparetime_add_partner $ref 0
	}
	
	// remote issuing
	
	method talk_issue_implant {name value} {
		sparetime_talkissue_set $name $value
	}
	method talk_issue_exist {name} {
		if {[sparetime_talkissue_get $name]>0.0} {return 1} {return 0}
	}
	method talk_issue_delete {name} {
		sparetime_talkissue_delete $name
	}
	method get_recent_food {} {
		set len [llength $sparetime_recent_food]
		incr len -2
		return [lrange $sparetime_recent_food $len end]
	}
	
} else {

	// obj_init-Teil
	
	set civ_state 0.0 ;# vorübergehend - zum Zivilisationswerttesten
	set sparetime_base_avoid 0
	set last_spareleave [gettime]
	set sexwish_recount 0
	//set last_sparestate 0.0
	//set last_taskcnt 0
	//set state_history [list]
	
	set work_strike 0
	set sparetime_future ""
	set sparetime_goal ""
	set sparetime_mingoal ""
	set sparetime_first_option ""
	set sparetime_compare_value 0.3
	set sparetime_emergency 0
	set sparetime_aftertaste {0 0 0 0}
	set sparetime_recent_food [list]
	set sparetime_eat_mode ""
	set sparetime_eat_item 0
	set sparetime_eat_count 0
	set spt_sleep_counter 0
	set sparetime_recent_fun [list]
	set sparetime_talkissues [list]
	set sparetime_talkevents [list]
	set spt_talk_desire 1.0
	set spt_talkfind_counter 0
	set spt_talk_fail 0
	set sparetime_talkanswer 0
	set sparetime_funrelief 1.0
	set spt_fun_check 0
	set spt_fun_stations 0
	set spt_fun_fail 0
	set spt_fun_ignore 0
	set spt_fun_needs 0
	set spt_fun_items 0
	set spt_fun_portion 0.0
	set spt_place_desire 0.0
	set spt_place_desire
	set spt_place_disapp 0.0
	set spt_last_place [gettime]
	set spt_placefind_counter 0
	set spt_prtn_desire 0.0
	set spt_last_prtn 0.0
	set spt_home_desire 0.0
	set spt_home_disapp 0.0
	set spt_last_home [gettime]
	set spt_home_counter 0
	set spt_bath_desire 0.0
	set spt_bath_disapp 0.0
	set spt_sex_desire 0.0
	set spt_sex_disapp 0.0
	set spt_last_sex [expr {[gettime]-300}]
	set spt_favplaces {}
	set sparetime_avoid_place {0 0.0}
	set sparetime_disappointment 0.0
	set spt_disappointment 0.0
	set is_talking 0
	set is_sleeping 0
	set parlympcs 0
	set sparetime_fun_mode ""
	set sparetime_fun_history {}
	set talk_partner {}
	set talk_leader 0
	set talk_listener 0
	set talk_listener_away 0
	set talk_step 0
	set spt_talk_count 0
	set talk_history {4}
	set talk_current_phrase ""
	set talk_current_issue ""
	set talk_current_length 0
	set talk_imthe_leader 0
	set talk_issue "" ;# Kompatibilität
	set talk_sign ""
	set talk_issue_history {}
	set planned_pathlength 0.0
	set sparetime_activities [list]
	lappend sparetime_activities "play_anim standloopa"
	lappend sparetime_activities "play_anim standloopb"
	lappend sparetime_activities "play_anim standloopc"
	lappend sparetime_activities "play_anim standloopd"
	lappend sparetime_activities "play_anim jumpa"
	lappend sparetime_activities "play_anim scratch"
	lappend sparetime_activities "play_anim breathe"
	lappend sparetime_activities "play_anim teeter_t"
	lappend sparetime_activities "play_anim wait"
	lappend sparetime_activities "play_anim scout"
	lappend sparetime_activities "play_anim wipenose"
	lappend sparetime_activities "play_anim cough"
	lappend sparetime_activities "play_anim teeter_w"
	lappend sparetime_activities "play_anim kneebend"
	lappend sparetime_activities "prod_waittime 2"
	lappend sparetime_activities "walk_around"
	//lappend sparetime_activities "interact_start"
	
	set sparetime_initialize 2
	set sparetime_is_on 0
	set sparetime_recent_places {}
	set sparetime_slpplaces {Zelt Mittelalterschlafzimmer Industrieschlafzimmer}
	set sparetime_eatplaces {Feuerstelle}
	set sparetime_eatclasses {Grillpilz Grillhamster Pilzbrot Raupensuppe Raupenschleimkuchen Gourmetsuppe Hamstershake}
	
	set sparetime_current_place 0
	set sparetime_current_place_ref 0
	set sparetime_reservation 0
	set sparetime_seat 0
	set sparetime_gotitem 0
	
	set spt_last_talk_fail 0.0
	set spt_last_place_fail 0.0
	set spt_last_home_fail 0.0
	set spt_last_sex_fail 0.0
	
	set spt_placefail_reason ""
	set spt_homefail_reason ""
	set spt_sexfail_reason ""
	
	set funloss_eatvariety 0.2
	set funloss_eatquality 0.2
	set funloss_placevariety 0.2
	set funloss_homequality 0.2
	set funloss_slpquality 0.1
	set funloss_bthquality 0.1
	set funloss_partnermeet 0.0
	set funloss_sex 0.0
	
	// nur fuer Timeline
	set tll_fl_eatvariety 0.0
	set tll_fl_eatquality 0.0
	set tll_fl_placevariety 0.0
	set tll_fl_homequality 0.0
	set tll_fl_slpquality 0.0
	set tll_fl_sex 0.0
	set tll_fl_bthquality 0.0
	set tll_fl_funstations 0.0
	set tll_fl_partnermeet 0.0
	set tll_fl_sex 0.0
	set tll_fl_common 0.0
	set tll_fl_hunger 0.0
	set tll_fl_tired 0.0
	set tll_last_sparelog [gettime]
	
	set declog 0

	proc sparetime_decide_occup {} {
		global at_Hi at_Nu at_Al at_Mo sparetime_emergency current_occupation current_wish_occupation
		global sparetime_remembered_scv sparetime_compare_value sparetime_goal sparetime_mingoal spt_fun_ignore
		global sparetime_goal_reached spt_fun_check spt_fun_stations civ_state spt_fun_needs spt_fun_portion
		global sparetime_future sparetime_history sparetime_emchange_initial spt_bath_desire has_bathed
		global declog
		if {$sparetime_goal_reached==2} {
			set sparetime_mingoal ""
		}
		//set at_Mo [hmin $at_Mo $at_FP]
		set funstations 0
		for {set i 1} {$i<17} {set i [expr {$i<<1}]} {
			if {$i&$spt_fun_stations} {
				incr funstations
			}
		}
		set funlack [expr {$spt_fun_needs-$funstations}]
		fun_log " funlack: $funlack ($spt_fun_stations - $spt_fun_needs)"
		set at_Fun [hmin $at_Mo [expr {1.0-$funlack*0.09}]]
		set emergency_tolerance [expr {0.3+$sparetime_goal_reached*0.1}]
		if {$sparetime_future==""&&!$sparetime_emergency&&$spt_bath_desire>6.0} {
			set sparetime_future bth
		}
		// fun sinkt unter slp (0.25<0.26), emto=0.3
		set eat_check0 [sparetime_eat_check]
		set maychange 0
		if {$at_Hi<0.97&&[sparetime_ill_check]} {
			set sparetime_emergencies [list "ill 0.0"]
		} else {
			if {$spt_fun_ignore&&$eat_check0&&$at_Nu<0.8&&($current_occupation=="fun"||$current_occupation=="eat")&&[lindex $sparetime_future 0]=="eat"} {
				set maychange 1
				set sparetime_goal ""
				set sparetime_goal_reached 2
			}
			if {$maychange||$at_Hi<0.8&&($at_Al<0.4||$at_Nu<0.4&&$eat_check0)} {
				if {$current_wish_occupation=="eat"} {
					set spt_fun_ignore 0
				}
				if {$at_Nu+0.1<$at_Al} {
					set sparetime_emergencies [list "eat $at_Nu" "slp $at_Al"]
				} else {
					set sparetime_emergencies [list "slp $at_Al" "eat $at_Nu"]
				}
			} else {
				set sparetime_emergencies [lsort -index 1 [list "eat $at_Nu" "slp $at_Al" "fun $at_Fun"]]
			}
		}
		if {$declog&&[is_selected this]} {log "sfi: $spt_fun_ignore se: $sparetime_emergency ec: $eat_check0 ses: $sparetime_emergencies"}
		//set spt_fun_ignore 0
		set sparetime_first_option "eat"
		set sparetime_emindex1 0
		set sparetime_emindex2 0
		set while_counter 0
		if {$sparetime_emergency} {
			set sparetime_emergency_tolerance [expr [lindex $sparetime_goal 1]-0.1]
		} else {
			set sparetime_emergency_tolerance 1
		}
		// in der Not alter Wert - 0.05 -> (0.2); sonst 1
		set eat_check 0
		set nextfuture 0
		set is_emergency 0
		while {($sparetime_first_option=="eat"&&!$eat_check||$nextfuture)&&$while_counter<100} {
			set nextfuture 0
			incr while_counter
			set is_emergency 1
			
			// Wenn erster Durchlauf, Essen checken
			if {!($sparetime_emindex1+$sparetime_emindex2)} {set eat_check $eat_check0}
			
			// Nächster Wert aus Emergency-Liste wird genommen
			set sparetime_first_option [lindex $sparetime_emergencies $sparetime_emindex1]
			if {$declog&&[is_selected this]} {log "sfo: ---------- $sparetime_first_option ($sparetime_emindex1)"}
			// sfo wird auf fun gesetzt, sev auf knapp niedriger als slp-Wert (0.25)
			set sparetime_emergency_value [lindex $sparetime_first_option 1]
			// sev ist der derzeitige Wert dieses Nofalls
			set sparetime_first_option [lindex $sparetime_first_option 0]
			if {$sparetime_first_option=="eat"} {incr sparetime_emindex1}
			
			if {$sparetime_first_option==$current_wish_occupation} {
				
				// Falls Notwert das ist, was Zwerg grad macht
				
				if {$sparetime_emchange_initial} {
					
					// Falls Notfall gerade erst eingeleitet
					
					set sparetime_emchange_initial 0
					set sparetime_compare_value [hmin $sparetime_emergency_tolerance $emergency_tolerance]
					if {$declog&&[is_selected this]} {log "sfo==cwo: scv: $sparetime_compare_value ($sparetime_emchange_initial,$sparetime_emergency_tolerance,$emergency_tolerance)"}
					
				} else {
					
					// Falls Notfall schon länger am abbauen
					
					if {!$sparetime_emergency} {
						set sparetime_compare_value [expr {$sparetime_emergency_tolerance+0.2-$sparetime_goal_reached*0.1}]
						if {$declog&&[is_selected this]} {log "se==1: scv: $sparetime_compare_value ($sparetime_emchange_initial,$sparetime_emergency_tolerance,$emergency_tolerance)"}
					} else {
						if {$declog&&[is_selected this]} {
							catch {log "se!=1: scv: $sparetime_compare_value ($sparetime_emchange_initial,$sparetime_emergency_tolerance,$emergency_tolerance)"} errMsg
							//log $errMsg
						}
					}
				}
			} else {
				
				// Falls neuer zu bearbeitender Notfall
				
				set sparetime_emchange_initial 1
				set sparetime_compare_value [hmin $sparetime_emergency_tolerance $emergency_tolerance]
		//		 {[is_selected this]} {log "sfo!=cwo: scv: $sparetime_compare_value ($sparetime_emchange_initial,$sparetime_emergency_tolerance,$emergency_tolerance)"}
			}
			
			if {$sparetime_emergency} {
				if {$declog&&[is_selected this]} {log "already emerged"}
				if {[subst [string trim [lindex $sparetime_goal 0] "-"]]>0.1&&$sparetime_compare_value<0.05} {
					set sparetime_compare_value 0.05
					if {$declog&&[is_selected this]} {log "scv set to: 0.05"}
				}
			}
			if {$declog&&[is_selected this]} {log "scv: $sparetime_emergency_value>[hmin $sparetime_compare_value 0.5] ($sparetime_compare_value) ? ($current_wish_occupation)"}
			// bei übereinstimmung mit bisher scv=0.2+0.2-0*0.1=0.4; sonst min(0.2,0.25)->0.2
			if {$sparetime_emergency_value>[hmin $sparetime_compare_value 0.5]} {
				set is_emergency 0
				set sparetime_emergency 0
				// 0.25>0.2 ->
				if {$sparetime_goal_reached==2||$sparetime_emindex2} {
					set sparetime_second_option [lindex $sparetime_future $sparetime_emindex2]
					set sparetime_emchange_initial 0
				} else {
					set sparetime_second_option $current_wish_occupation
				}
				if {$sparetime_goal_reached<2&&($current_wish_occupation!="eat"||$eat_check)} {
					set sparetime_first_option $current_wish_occupation
					set sparetime_second_option $current_wish_occupation
				} else {
					if {$sparetime_second_option==""} {
						set sparetime_second_option "fun"
						set sparetime_first_option "fun"
					} elseif {$sparetime_goal_reached==2} {
						switch $sparetime_second_option {
							"eat" {set spt_sc_value $at_Nu}
							"slp" {set spt_sc_value $at_Al}
							"fun" {set spt_sc_value $at_Fun}
							"bth" {set spt_sc_value [expr {1.0-$spt_bath_desire*0.01}]}
							default {set spt_sc_value 1.0}
						}
						if {$declog&&[is_selected this]} {log "sco: $sparetime_second_option,$spt_sc_value ($sparetime_future,$sparetime_emindex2)"}
						if {$spt_sc_value>0.9||$sparetime_second_option=="eat"&&$spt_sc_value>0.8} {
							if {$at_Nu<0.8&&[land "eat" $sparetime_future]!=""||$at_Al<0.9&&[land "slp" $sparetime_future]!=""} {
								incr sparetime_emindex2
								set nextfuture 1
								continue
							} elseif {$at_Nu>0.8&&$at_Al>0.9} {
								set sparetime_second_option "fun"
								set sparetime_first_option "fun"
							}
						} else {
							set sparetime_first_option $sparetime_second_option
							if {$sparetime_first_option=="eat"} {
								incr sparetime_emindex2
							}
						}
					}
				}
			} else {
				set sparetime_emergency 1
			}
			if {$declog&&[is_selected this]} {log "$sparetime_first_option ($current_wish_occupation) -$sparetime_emergency- $emergency_tolerance $sparetime_emergency_tolerance -$is_emergency-"}
		}
		if {$while_counter>10} {log "while_counter: $while_counter! ($current_wish_occupation,$sparetime_goal_reached)"}
		if {$is_emergency} {set sparetime_emergency 1} {set sparetime_emergency 0}
		if {$declog&&[is_selected this]} {log "$current_wish_occupation -$sparetime_emergency- $is_emergency"}
		//	log "[get_objname this] $state_code_counter: $sparetime_goal"
		if {$current_wish_occupation!=$sparetime_first_option} {
			if {$sparetime_mingoal!=""} {
				if "$sparetime_mingoal" {
					set sparetime_first_option $current_wish_occupation
					if {$declog&&[is_selected this]} {log "rechanging occup $current_wish_occupation ($sparetime_mingoal)"}
				}
			}
		}
		if {$current_wish_occupation!=$sparetime_first_option&&-1!=[lsearch {eat fun slp bth} $current_wish_occupation]&&$sparetime_goal!=""} {
			if "$sparetime_goal*0.7" {
				set sf_index [lsearch $sparetime_future $current_occupation]
				if {-1!=$sf_index} {
					lrem sparetime_future $sf_index
				}
			}
			lappend sparetime_history $current_occupation
			set sparetime_goal ""
			set goal_has_changed 0
		}
		if {""==$sparetime_goal} {
			//									      ^
			//									     / \
			//										/odd\
			//									   / code\
			//									  / ahead \
			//									 /____!____\
			set sparetime_mingoal ""
			if {$sparetime_emergency&&([lindex [lindex $sparetime_emergencies 1] 1]<$emergency_tolerance||$sparetime_compare_value!=$sparetime_remembered_scv)} {
				switch $sparetime_first_option {
					"eat" {
						if {$at_Al<0.4} {set reachfor [hmin 0.7 $sparetime_compare_value]} {set reachfor 0.88}
						fincr reachfor 0.1
						set sparetime_goal "\$at_Nu- $at_Nu >($reachfor-$at_Nu)"
						if {$at_Nu<0.5&&[hmin $at_Al $at_Mo]<$at_Nu+0.2} {
							set sparetime_mingoal "\$at_Nu<$at_Nu+0.2"
						}
					}
					"slp" {
						if {$at_Nu<0.5&&$at_Al<0.5} {set reachfor [hmin 0.7 $sparetime_compare_value]} {set reachfor 0.88}
						fincr reachfor 0.1
						set sparetime_goal "\$at_Al- $at_Al >($reachfor-$at_Al)"
						if {$at_Al<0.5&&[hmin $at_Mo $at_Nu]<$at_Al+0.2} {
							set sparetime_mingoal "\$at_Al<$at_Al+0.2"
						}
					}
					"fun" {
						set funposs 1.0
						if {$at_Mo>0.5} {
							if {$funlack+$spt_fun_needs>5} {
								set sparetime_goal "$at_Mo- $at_Mo >(\$funlack-$funlack)"
								set funposs [hmax 1.0 [expr {$funlack-1.0}]]
								set take 0
							} elseif {$at_Mo<0.95} {
								set sparetime_goal "\$at_Mo- $at_Mo >(0.98-$at_Mo)"
								set take 1
							} else {
								set sparetime_goal "$at_Mo- $at_Mo >(-1)"
								set take 2
							}
						} else {
							set sparetime_goal "\$at_Mo- $at_Mo >([hmin 0.7 $sparetime_compare_value]-$at_Mo+0.1)"
								set take 3
						}
						set spt_fun_portion [expr {(1.0-$at_Mo)/$funposs}]
						if {[lindex $sparetime_goal 1]>[get_attrib this atr_Mood]+0.01} {
							log "FEHLER in sparetime_goal:"
							log " [get_objname this] ($sparetime_goal) [get_attrib this atr_Mood] ($take)"
						}
						if {$at_Mo<0.5&&[hmin $at_Al $at_Nu]<$at_Mo+0.2} {
							set sparetime_mingoal "\$at_Mo<$at_Mo+0.2"
						}
					}
					"ill" {set sparetime_goal "\$at_Hi- $at_Hi >(0.98-$at_Hi)"}
					default {set sparetime_goal 1}
				}
				set sparetime_remembered_scv $sparetime_compare_value
			} else {
				set sparetime_mingoal ""
				if {-1==[lsearch $sparetime_future $sparetime_first_option]} {
					set sparetime_future [concat $sparetime_first_option $sparetime_future]
					if {$declog&&[is_selected this]} {log "adding $sparetime_first_option ($sparetime_future)"}
				}
				set sparetime_rest [get_remaining_sparetime this]
				set sparetime_defizit [expr {3-$at_Nu-$at_Al-$at_Mo+$sparetime_rest*0.1}]
				switch $sparetime_first_option {
					"eat" {
						if {([string last "eat" $sparetime_future]>0)&&$at_Nu<0.5} {
							set sparetime_goal [expr {0.80-$at_Nu}]
						//	set sparetime_goal [hmin [expr {0.95-$at_Nu}] [expr {(1-$at_Nu+$sparetime_rest*0.04)*0.12*$sparetime_rest/$sparetime_defizit}]]
						} else {
						//	set sparetime_goal [hmin [expr {0.95-$at_Nu}] [expr {(1-$at_Nu+$sparetime_rest*0.04)*0.2*$sparetime_rest/$sparetime_defizit}]]
							set sparetime_goal [expr {0.95-$at_Nu}]
						}
						if {[is_selected this]} {log [expr {$at_Nu+$sparetime_goal}]}
						set sparetime_goal "\$at_Nu- $at_Nu >=$sparetime_goal"
					}
					"slp" {
						if {$at_Nu<$at_Mo-0.2} {
							set sparetime_goal [hmin [expr {0.98-$at_Al}] [expr {(1-$at_Al+$sparetime_rest*0.03)*0.2*$sparetime_rest/$sparetime_defizit}]]
						} else {
							set sparetime_goal [expr {0.98-$at_Al}]
						}
						if {[is_selected this]} {log [expr {$at_Al+$sparetime_goal}]}
						set sparetime_goal "\$at_Al- $at_Al >=$sparetime_goal"}
					"bth" {set sparetime_goal "\$has_bathed>=5.0"}
					"fun" {
						set funposs 1.0
						if {$funlack+$spt_fun_needs>5} {
							set sparetime_goal "$at_Mo- $at_Mo >(\$funlack-$funlack)"
							set funposs [hmax 1.0 [expr {$funlack-1.0}]]
							set take 4
						} elseif {$at_Mo<0.95} {
							set sparetime_goal "\$at_Mo- $at_Mo >(0.98-$at_Mo)"
							set take 5
						} else {
							set sparetime_goal "$at_Mo- $at_Mo >(-1)"
							set take 6
						}
						if {[lindex $sparetime_goal 1]>[get_attrib this atr_Mood]+0.01} {
							log "FEHLER in sparetime_goal:"
							log " [get_objname this] ($sparetime_goal) [get_attrib this atr_Mood] ($take)"
						}
						if {[is_selected this]} {log $sparetime_goal}
						set spt_fun_portion [expr {(1.0-$at_Mo)/$funposs}]
					}
					default {set sparetime_goal 1}
				}
			}
			set sparetime_goal_reached 0
			set current_wish_occupation $sparetime_first_option
			if {[is_selected this]} {log "[get_objname this]: $current_wish_occupation $sparetime_goal"}
		} else {
			if "$sparetime_goal" {
				set sparetime_goal_reached 2
				set spt_fun_ignore 0
			} elseif "$sparetime_goal*0.5" {
				set sparetime_goal_reached 1
				set spt_fun_ignore 0
			} else {
				set sparetime_goal_reached 0
			}
			// if {[is_selected this]} {log "goal_reached: $sparetime_goal_reached"}
			if {$declog} {log "[get_objname this]: $sparetime_goal_reached $current_occupation"}
			if {2==$sparetime_goal_reached} {
				set sparetime_goal ""
	//			set goal_has_changed 1
				set sf_index [lsearch $sparetime_future $current_occupation]
				if {-1!=$sf_index} {
					lrem sparetime_future $sf_index
					if {$declog} {log "[get_objname this]: removing $current_occupation from future: $sf_index"}
				}
				set sparetime_emergency 0
				set current_wish_occupation "fun"
				return 1
			}
		}
		return 0
	}
	proc sparetime_state_end {} {
		global current_plan current_occupation stt_issue_reduce sparetime_fun_history
		global reprod_actionlock reprod_hitcnt reprod_hitrate willing_to_reprod reprod_sexratio
		global last_spareleave sparetime_initialize state_code_counter state_code_timeneed
		global state_code_diff sparetime_history time_count_start sparetime_is_on
		set current_plan "work"
		set sparetime_is_on 0
		if {[string first $current_occupation "eatfunslpbthill"]!=-1} {
			sparetime_${current_occupation}_end
			set current_occupation "work"
		}
		sparetime_check_in 0
		set reprod_actionlock 0
		set ctime [gettime]
		set daylength [expr {$ctime-$last_spareleave}]
		if {$daylength>200} {sparetime_talkissue_reduce $stt_issue_reduce}
		set reprod_hitrate [expr {$reprod_hitrate*0.2+$reprod_hitcnt*1440.0/$daylength}]
		lrep reprod_sexratio 0 100
		set reprod_hitcnt 0
		set last_spareleave $ctime
//		log "[get_objname this]: $state_code_counter mal sparetime_dispatch"
		if {$state_code_counter} {
			log "[get_objname this] Verbrauchte Zeit: $state_code_timeneed, [expr {$state_code_timeneed*1.0/$state_code_counter}] durchschnittlich ($state_code_counter Iterationen in [expr {[gettime]-$time_count_start}] Sek.)"
		} else {
			log "[get_objname this] Verbrauchte Zeit: keine"
		}
		log $state_code_diff
		log "Sparetime History: $sparetime_history $current_occupation"
		set willing_to_reprod 0
		set sparetime_initialize 1
		set sparetime_fun_history {}
//		log "change to work"
		state_triggerfresh this work_dispatch
	}
	proc event_sparewish_update {} {
		global civ_state gnome_gender spt_favplaces spt_fun_stations spt_fun_fail birthtime
		global current_workclass current_worktask parlympcs current_workplace work_strike at_Mo
		global spt_home_desire spt_bath_desire spt_sex_desire spt_prtn_desire spt_place_desire
		global spt_last_home spt_last_place spt_last_sex spt_talk_desire spt_fun_check spt_fun_needs
		global reprod_sexratio reprod_pregnancy current_babies childrencount spt_last_prtn
		set own [get_owner this]
		enable_digbrushes $own
		sparetime_check_funitems
		set bestexp [get_bestexp this]
		if {$bestexp==""} {
			set spt_favplaces {}
		} else {
			global stt_$bestexp
			set spt_favplaces [subst \$stt_$bestexp]
		}
		set civ_state [expr {([gamestats attribsum $own expsum]+[gamestats numbuiltprodclasses $own])*0.01}]
		set ctime [gettime]
		set popgnomes [hmax [gamestats numgnomes $own] 1]
		if {$gnome_gender=="female"} {
			//&&!$reprod_pregnancy&&$current_babies==""} {
			set popsoll [sparetime_get_popsoll $civ_state]
			set popfemales [hmax [gamestats numfemale $own] 1]
			set popist [expr {$popgnomes+[gamestats numbabies $own]+[gamestats numpregnant $own]}]
			set genderasym [hmax [expr {(abs([gamestats nummale $own]-$popfemales)-2.0)/$popist}] 0.0]
			set delay [expr {atan($ctime*0.001-[get_owner_attrib $own LastBirth]-0.2)*0.5}]
			set childrenasym [expr {([gamestats avgchildren $own]*$popgnomes/$popfemales-$childrencount)*($popfemales-1)}]
			set kidneed [expr {$popsoll-$popist+$delay+$genderasym}]
			if {$childrenasym<0.0} {
				fincr kidneed [expr {$childrenasym*$kidneed*0.1}]
			}
			//log "kidneed [get_objname this] $popsoll-$popist+$delay+$genderasym+$childrenasym"
			if {abs([lindex $reprod_sexratio 0]-$kidneed)>0.1} {
				sparetime_calc_sexwish $kidneed
			}
		}
		if {$parlympcs} {
			set work_strike 1
		} else {
			set strike [expr {$at_Mo-[gamestats attribavg $own atr_Mood]*0.1}]
			set maxstriker [hmin [expr {$popgnomes-2.5}] [expr {$popgnomes*(1.0-$strike*5.0)}]]
			set cstriker [gamestats attribsum $own GnomeStrike]
			//log "[get_objname this]: s $strike ms $maxstriker cs $cstriker"
			if {$maxstriker>$cstriker} {set work_strike 1} {set work_strike 0}
		}
		set civ_state [hmax $civ_state 0.05]
		set spt_fun_needs [hmax [expr {int($civ_state*10)}] 2]
		set imode 1
		foreach mode {place home sex prtn} {
			set timedist [expr {$ctime-[subst \$spt_last_$mode]}]
			if {$timedist<100} {
				set desval 0.0
			} elseif {$timedist<300} {
				set desval [expr {($timedist-100)*0.15}]
			} elseif {$timedist<1000} {
				set desval 30.0
			} elseif {$timedist<1700} {
				set desval [expr {($timedist-700)*0.1}]
			} else {
				set desval 100.0
			}
			if {$mode!="prtn"&&$desval>30.0} {
				global spt_last_${mode}_fail
				if {$ctime-[subst \$spt_last_${mode}_fail]>300&&$ctime-[subst \$spt_last_${mode}]>300} {
					set spt_fun_stations [expr {~(1<<$imode)&$spt_fun_stations}]
					set spt_fun_fail [expr {~(1<<$imode)&$spt_fun_fail}]
				}
			}
			set spt_$mode\_desire [expr {$desval*0.5*(1.0+$civ_state)}]
			incr imode
		}
		set spt_fun_check [sparetime_fun_check]
		// Funverluste festlegen
		sparetime_update_disapp
		//set spt_disappointment [expr {-0.000001 * (1.0 + $civ_state * 0.1)}]
		//// Schmutz abbekommen
		if {$spt_bath_desire<10.0} {
			if {$current_workclass!=""&&$current_workclass!=0&&[string range $current_workclass 0 1]!="Bp"} {
				set dirttype [get_class_category $current_workclass]
			} elseif {$current_worktask=="walk"} {
				set dirttype transport
			} elseif {$current_workplace=="dig"} {
				set dirttype stone
			} elseif {[string first "pack" $current_worktask]!=-1} {
				set dirttype wood
			} elseif {[state_get this]=="fight_dispatch"} {
				set dirttype fight
			} else {
				set dirttype none
			}
			switch $dirttype {
				"food" {set dirt 0.04}
				"wood" {set dirt 0.1}
				"stone" {set dirt 0.25}
				"fight" {set dirt 0.4}
				"metal" {set dirt 0.15}
				"transport" {set dirt 0.03}
				default {set dirt 0.01}
			}
			fincr spt_bath_desire $dirt
			fincr birthtime [expr {([hmin $dirt 0.1]-0.05)*-10.0}]
		}
	}
	proc sparetime_get_popsoll {civ} {
		if {$civ<0.15} {
			return [expr {7.0+$civ*20.0}]
		} elseif {$civ<0.4} {
			return [expr {5.2+$civ*32.0}]
		} else {
			return [hmin [expr {10.0+$civ*20.0}] 22.0]
		}
	}
	proc sparetime_calc_sexwish {reprod_goal} {
		global reprod_hitrate reprod_sexratio sexwish_recount
		incr sexwish_recount
		set n [hmin [hmax [hfloor $reprod_hitrate] 1] 300]
		if {$reprod_goal<0.0} {
			set reprod_sexratio [list $reprod_goal [expr {pow(10.0,$reprod_goal-3)/$n}]]
			return
		}
		if {$reprod_goal>0.999} {
			set goal 0.999
			set factor $reprod_goal
		} else {
			set goal $reprod_goal
			set factor 1.0
		}
		set chance [expr {(1-pow(1-$goal,1.0/$n))*$factor}]
		set reprod_sexratio [list $reprod_goal $chance]
		return
	}
	proc sparetime_check_funitems {} {
		global spt_fun_items
		if {[inv_find this Gold]!=-1} {
			set spt_fun_items 1
			return
		}
		if {[inv_find this Amulett_1]!=-1} {
			set spt_fun_items 1
			return
		}
		if {[inv_find this Amulett_2]!=-1} {
			set spt_fun_items 1
			return
		}
		if {[inv_find this Amulett_3]!=-1} {
			set spt_fun_items 1
			return
		}
		set spt_fun_items 0
	}
	proc sparetime_update_quality {name place} {
		set change_var funloss_${name}quality
		global $change_var
		global stt_${name}civ_$place
		set $change_var [expr {[subst \$$change_var]*0.3+([subst \$stt_${name}civ_$place]+0.2)*0.7}]
	}	
	proc sparetime_eat_variety {} {
		global funloss_eatvariety
		global sparetime_recent_food sparetime_eatclasses
		set val [expr {(10-[llength $sparetime_recent_food])*0.04+0.1}]
		foreach item $sparetime_eatclasses {
			set cnt [lcount $sparetime_recent_food $item]
			if {$cnt} {
				fincr val [expr {(15-$cnt)*0.01}]
			}
		}
		set funloss_eatvariety $val
	}
	proc sparetime_place_variety {} {
		global funloss_placevariety spt_favplaces sparetime_recent_fun
		set val [expr {(10-[llength $sparetime_recent_fun])*0.01+0.2}]
		set places {pub tht dsc fit bwl}
		foreach item [concat $places $spt_favplaces] {
			set cnt [lcount $sparetime_recent_fun $item]
			if {$cnt} {
				fincr val [expr {(15-$cnt)*0.008}]
			}
		}
		set funloss_placevariety $val
	}
	proc sparetime_update_disapp {} {
		sparetime_eat_variety
		sparetime_place_variety
		global spt_disappointment	civ_state
		global spt_fun_stations		spt_fun_needs			spt_fun_fail
		global funloss_eatvariety	funloss_homequality		funloss_placevariety
		global funloss_eatquality	funloss_slpquality		funloss_bthquality
		global tll_fl_eatvariety	tll_fl_homequality		tll_fl_placevariety
		global tll_fl_eatquality	tll_fl_slpquality		tll_fl_bthquality
		global tll_fl_funstations
		set sumloss 0.0
		set moodfactor 0.003
		if {$civ_state>$funloss_eatvariety} {
			set moodloss [expr {$civ_state-$funloss_eatvariety}]
			sparetime_talkissue_entry "eat" $moodloss 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_eatvariety $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_placevariety} {
			set moodloss [expr {$civ_state-$funloss_placevariety}]
			sparetime_talkissue_entry "fun" $moodloss 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_placevariety $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_eatquality} {
			set moodloss [expr {($civ_state-$funloss_eatquality)*0.5}]
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_eatquality $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_slpquality} {
			set moodloss [expr {$civ_state-$funloss_slpquality}]
			sparetime_talkissue_entry "slp" $moodloss 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_slpquality $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_homequality} {
			set moodloss [expr {($civ_state-$funloss_homequality)*0.5}]
			sparetime_talkissue_entry "fun" [expr {$moodloss*0.4}] 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_homequality $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_bthquality} {
			set moodloss [expr {$civ_state-$funloss_bthquality}]
			sparetime_talkissue_entry "bth" $moodloss 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_bthquality $moodloss
			fincr sumloss $moodloss
		}
		if {$civ_state>$funloss_slpquality} {
			set moodloss [expr {$civ_state-$funloss_slpquality}]
			sparetime_talkissue_entry "slp" $moodloss 0
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_slpquality $moodloss
			fincr sumloss $moodloss
		}
		set funstations 0
		for {set i 1} {$i<17} {set i [expr {$i<<1}]} {
			if {$i&$spt_fun_stations} {
				incr funstations
			}
		}
		if {$spt_fun_needs-$funstations} {
			set moodloss [expr {$spt_fun_needs-$funstations}]
			set reasons {}
			if {($spt_fun_stations&1)==0} {lappend reasons ""}
			if {($spt_fun_stations&8)==0} {lappend reasons ""}
			if {($spt_fun_stations&16)==0} {
				lappend reasons "ttp"
			}
			if {$spt_fun_needs>2} {
				if {[llength $reasons]<$moodloss} {
					if {($spt_fun_stations&6)!=6} {lappend reasons "fun"}
				}
			}
			set reasons [join $reasons]
			set moodloss [expr {$moodloss*0.1}]
			set rl [llength $reasons]
			if {$rl} {
				foreach item $reasons {
					sparetime_talkissue_entry $item [expr {$moodloss/$rl}] 0
				}
			}
			set moodloss [expr {$moodfactor*$moodloss}]
			fincr tll_fl_funstations $moodloss
			fincr sumloss $moodloss
		}
		fun_log " funloss: $sumloss"
		set spt_disappointment [expr {$sumloss*-0.1}]
	}
	// nur fuer Timeline
	proc sparetime_time_log {mode} {
		global spt_disappointment	spt_fun_stations		civ_state
		global tll_fl_eatvariety	tll_fl_homequality		tll_fl_placevariety
		global tll_fl_eatquality	tll_fl_slpquality		tll_fl_bthquality
		global tll_fl_funstations	tll_last_sparelog
		global tll_fl_common		tll_fl_hunger			tll_fl_tired
		set passedtime [expr {[gettime]-$tll_last_sparelog}]
		set tll_last_sparelog [gettime]
		set passedtime [string range $passedtime 0 [expr {[string first "." $passedtime]+2}]]
		if {[im_in_campaign]} {
			time_line_log ""
			time_line_log "-------- [clock format [clock seconds] -format "%d-%m-%y %X"] ---------"
			time_line_log "---- [get_objname this] ---- Ende [lindex {Freizeit Arbeitszeit} $mode] nach $passedtime Sekunden"
			time_line_log " CIV_STATE: $civ_state"
		}
		foreach loss {eatvariety eatquality placevariety homequality slpquality bthquality funstations common hunger tired} {
			if {[im_in_campaign]} {
				set lossval [subst \$tll_fl_$loss]
				if {$lossval>0.01} {
					set str "Verluste wegen $loss:"
					append str [string repeat " " [expr {32-[string length $str]}]]
					set lossval [subst \$tll_fl_$loss]
					append str [string range $lossval 0 [expr {[string first "." $lossval]+4}]]
					time_line_log $str
				}
			}
			set tll_fl_$loss 0.0
		}
		if {[im_in_campaign]} {
			set leerlist ""
			foreach item [talkissue this list] {
				set val [talkissue this get $item]
				if {$val>=1.0} {
					time_line_log "$item [string range $val 0 [expr {[string first {.} $val]+2}]]"
				} else {
					lappend leerlist $item
				}
			}
			time_line_log "weitere Themen: $leerlist"
		}
	}
}