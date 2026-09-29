proc event_talkissue_update {} {
	global sparetime_talkevents current_workplace current_worktask last_workplace
	global current_plan at_Nu at_Al at_Mo reprod_partner reprod_pregnancy
	global spt_brtl_desire spt_prtn_desire spt_talk_desire is_old
	sparetime_update_issues $sparetime_talkevents
	set sparetime_talkevents [list]
	sparetime_judge_ways
	if {$current_workplace!=0||$current_worktask=="harvest"} {
		sparetime_talkissue_entry "wtm" 1 1 0
		if {[prod_gnome_get_preferred_workplace this]} {
			if {[prod_gnome_get_preferred_workplace this]!=$current_workplace} {
				sparetime_talkissue_entry "npw" 1 1 0
			}
		}
		if {$current_workplace!=0} {
			if {$current_workplace==$last_workplace} {
				sparetime_talkissue_entry "asw" 1 1 0
			} else {
				sparetime_talkissue_entry "ocw" 1 1 0
			}
		}
		if {$current_plan=="sparetime"} {
			sparetime_talkissue_entry "wis" 1 1 0
		}
		if {[get_attrib this atr_Hitpoints]<0.8} {sparetime_talkissue_entry "wil" 1 1 0}
		if {$at_Nu<0.4} {sparetime_talkissue_entry "whu" 1 1 0}
		if {$at_Al<0.5} {sparetime_talkissue_entry "wti" 1 1 0}
		if {$at_Mo<0.6} {sparetime_talkissue_entry "wmm" 1 1 0}
		set last_workplace $current_workplace
	}
	//if {$reprod_partner} {
	//	sparetime_talkissue_entry "ttp" 1 1 0
	//	set ttp [hmax [talkissue this get ttp] 0.0]
	//	set spt_prtn_desire [expr {sqrt($ttp)}]
	//} else {
	//	sparetime_talkissue_entry "fli" 1 1 0
	//	set spt_prtn_desire 0.0
	//}
	if {[state_get this]=="fight_dispatch"} {sparetime_talkissue_entry "fgt" 1 1 0}
	if {$reprod_pregnancy} {sparetime_talkissue_entry "prgn" 0.5 1 0}
	if {$is_old} {sparetime_talkissue_entry "old" [expr {$is_old*0.5}] 1 0}
	set spt_talk_desire [talkissue this sum]
}

proc sparetime_update_issues {evt_list} {
	set thrulist [list]
	foreach evt $evt_list {
		if {[lsearch $thrulist $evt]==-1} {
			lappend thrulist $evt
			sparetime_talkissue_entry $evt [expr {1<<[lcount $evt_list $evt]}] 1 0
		}
	}
}
proc sparetime_talkissue_entry {name value {reduce 1} {recalc 1}} {
	global stt_talk_issues spt_talk_desire
	if {$reduce} {
		if {[string first $name $stt_talk_issues]!=-1} {
			global stt_talkweight_$name
		} else {
			set stt_talkweight_$name 1
		}
		set value [expr {[subst \$stt_talkweight_$name]*$value}]
	}
	talkissue this add $name $value
	if {$recalc} {
		set spt_talk_desire [talkissue this sum]
	}
}
proc sparetime_talkissue_reduce {factor} {
	global spt_talk_desire
	talkissue this reduce $factor
	set spt_talk_desire [talkissue this sum]
}
proc sparetime_talkissue_delete {name} {
	talkissue this delete $name
	set spt_talk_desire [talkissue this sum]
}
proc sparetime_talkissue_set {name value} {
	global spt_talk_desire
	talkissue this set $name $value
	set spt_talk_desire [talkissue this sum]
}
proc sparetime_talkissue_get {name} {
	return [talkissue this get $name]
}
proc sparetime_judge_ways {} {
	global planned_pathlength
	set pl [expr int(sqrt($planned_pathlength))]
	if {$pl<1.5} {return}
	if {[state_get this]=="sparetime_dispatch"} {
		sparetime_talkissue_entry "tlw" $pl 1 0
	} else {
		sparetime_talkissue_entry "wal" $pl 1 0
	}
	set planned_pathlength 0.0
}
proc sparetime_talk_entry {name} {
	global talk_issue_history
	lappend talk_issue_history $name
	if {[llength $talk_issue_history]>9} {set talk_issue_history [lrange $talk_issue_history 1 end]}
}
proc sparetime_fun_relief {value} {
	global civ_state stt_issue_relief spt_fun_portion
	set reduce [expr {$value*(1.0-$civ_state)}]
	sparetime_talkissue_reduce [expr {1.0-$reduce*$stt_issue_relief}]
	set reduce [expr {$reduce*5.0*$spt_fun_portion}]
	fun_log "Moodgain by Listening: $reduce"
	add_attrib this atr_Mood $reduce
}
proc sparetime_talk_find {} {
	global reprod_partner gnome_gender sparetime_fun_history at_Mo spt_talk_desire
	global sparetime_fun_log
	//fun_log " spare_talk_find"
	if {[lindex $sparetime_fun_history end]=="talk"} {return ""}
	set glist [obj_query this -class Zwerg -owner own -range 10]
	//fun_log "glist: $glist"
	if {$glist==0} {return ""}
	set qglist [list]
	//fun_log " search for talkers"
	foreach g $glist {
		if {[call_method $g get_current_occupation]=="fun"} {
			if {[set aft [call_method $g ask_for_talk]]} {
				// Wie gern will der reden?
				incr aft [call_method $g check_is_talking]
				// Der redet ja schon! Da will ich mitmachen.
				//fincr jm [expr {abs(0.5-$at_Mo)*abs(0.5-[get_attrib $g atr_Mood])*4}]
				if {$g==$reprod_partner} {
					//fincr jm 1
					incr aft 2
				} else {
					if {$gnome_gender!=[call_method $g get_gender]} {
						incr aft 2 ;# flirten
					}
				}
				fincr aft [expr {($spt_talk_desire+[call_method $g get_talk_desire])*0.05}]
				fun_log " verbindet ein Redewunsch von [string range $aft 0 4] mit [get_objname $g]."
				if {$aft>3.0} {lappend qglist [list $g $aft]}
			} else {
				// log "[get_objname $g] returned $aft ([ref_get $g sparetime_talkanswer])"
			}
		} else {
		//	log "[get_objname $g] ist in [call_method $g get_current_occupation]"
		}
	}
	//fun_log "found talkers: $qglist"
	if {$qglist==""} {return ""}
	set best [lindex [lsort -index 1 -decreasing -real $qglist] 0]
	if {[isunderwater [get_pos [lindex $best 0]]]} {return ""}
	return $best
}

proc sparetime_talk_start {starter self} {
	global sparetime_fun_mode sparetime_talkanswer is_talking myref spt_talk_count
	global talk_step talk_partner talk_leader talk_listener spt_talk_urge
	global spt_talkfind_counter spt_talk_fail
	set spt_talk_urge "undef"
	if {!$self} {
		switch $sparetime_fun_mode {
			"place" {sparetime_place_end}
			"home" {sparetime_home_end}
			"sex" {sparetime_sex_end}
		}
	}
	set sparetime_fun_mode "talk"
	//sparetime_fun_entry "talk"
	if {$self} {
		set talk_partner [call_method $starter get_talk_partner]
		foreach tpitem $talk_partner {
			if {[lcount $talk_partner $tpitem]>1} {
				log "FEHLER in talk_start [get_objname this]: ($talk_partner)"
				break
			}
		}
		if {[land $starter $talk_partner]!=""} {
			log "FEHLER in talk_start [get_objname this]: ($talk_partner) starter: $starter"
		}
		lappend talk_partner $starter
		set talk_step 0
		if {[llength $talk_partner]<2} {
			set talk_leader $starter
			set talk_listener $myref
		} else {
			set talk_leader [call_method $starter get_talk_leader]
			set talk_listener [call_method $starter get_talk_listener]
		}
		set spt_talk_count 0
	} else {
		if {[land $starter $talk_partner]!=""} {
			log "FEHLER in talk_start [get_objname this]: ($talk_partner) starter2: $starter"
		}
		lappend talk_partner $starter
		tasklist_add this "rotate_towards $starter"
		set talk_step 0
		set talk_leader $myref
		set talk_listener $starter
	}
	//log "$myref [get_objname this] startet talk: ($talk_partner) $talk_leader $talk_listener [tasklist_cnt this]"
	set is_talking 1
	set spt_talk_fail 0
	set spt_talkfind_counter 0
	set sparetime_talkanswer 1
}

proc sparetime_talk_setminstep {step} {
	global talk_step
	if {$talk_step<$step} {set talk_step $step}
}

proc sparetime_talk_loop {} {
	global talk_step talk_partner talk_leader talk_listener spt_talk_desire
	global myref willing_to_reprod reprod_partner spt_talk_count
	sparetime_check_prtn
	if {$talk_partner==""||$spt_talk_desire<3.0&&$talk_listener==$myref&&$spt_talk_count>3||![obj_valid $talk_partner]} {
		log "talk_end;($talk_partner) $talk_listener-$myref $spt_talk_desire"
		sparetime_talk_end
		return
	}
	set new_tps {}
	while {$talk_partner!=""} {
		set ftp [lindex $talk_partner 0]
		if {$ftp!=$myref&&[obj_valid $ftp]} {lappend new_tps $ftp}
		set talk_partner [lnand $ftp $talk_partner]
	}
	set talk_partner $new_tps
	if {[lsearch $talk_partner $reprod_partner]!=-1} {set willing_to_reprod 1}
	switch $talk_step {
		0 {
			// zum Gesprächspartner gehen
			if {$talk_leader==$myref} {
				//log "[get_objname this] increasing to 1: ($talk_partner) $talk_leader $myref"
				set mypos [get_pos this]
				set myz [lindex $mypos 2]
				set zn [expr {10-$myz}]
				set zp [expr {15-$myz}]
				set pos [get_place -center $mypos -rect -6 $zn 6 $zp -rimdist 2.5 -walldist 1 -except this -nearpos $mypos]
				tasklist_add this "walk_pos \{$pos\}"
				tasklist_add this "rotate_towards $talk_listener"
				incr talk_step
			} else {
				set centerpos {0.0 0.0 0.0}
				set leaderpos [get_pos $talk_leader]
				set i 0
				foreach g $talk_partner {
					set gpos [get_pos $g]
					if {[vector_dist3d $leaderpos $gpos]<1.5} {
						set centerpos [vector_add $centerpos $gpos]
						incr i
						//log "centerpos: $centerpos ($i)"
					}
				}
				if {!$i} {wait_time 1;return}
				set centerpos [vector_mul $centerpos [expr {1.0/$i}]]
				//log "centerpos: $centerpos"
				if {$i==1} {
					set pos [get_place -center $centerpos -rect -2 -4 2 4 -mindist 0.8 -except this -nearpos [get_pos this]]
				} else {
					set pos [get_place -center $centerpos -rect -2 -4 2 4 -mindist 0.8 -except this]
				}
				if {[vector_abs [vector_sub [get_pos this] $pos]]<0.5} {
					incr talk_step 2
				//	log "[get_objname this] increasing to 2: ($talk_partner) $talk_leader $myref ($i)"
				//	foreach g $talk_partner {
				//		if {[call_method $g get_talk_status]==1} {
					call_method $talk_leader set_talk_step 2
					if {$i==1} {call_method $talk_leader set_talk_status 2 $talk_leader $myref 0}
				//		}
				//	}
					return
				}
				// log "[get_objname this]: goes to \{$pos\} ([get_pos $talk_leader]) ($i)"
				tasklist_add this "walk_pos \{$pos\}"
			}
		}
		1 { ;# auf Gesprächspartner warten
			sparetime_idle_loop
		}
		2 {
			// zum Gesprächspartner drehen
			// log "[get_objname this] ($myref).($talk_leader).($talk_listener)"
			if {$talk_leader==$myref} {
				tasklist_add this "rotate_towards $talk_listener"
			} else {
				tasklist_add this "rotate_towards $talk_leader"
			}
			sparetime_talk_anim 3 ""
			set greettext [sparetime_talk_answer "g"]
			if {[string length $greettext]>40} {
				set greetlength 3
				sparetime_talk_anim 4 "p"
			} else {
				set greetlength 1.5
			}
			global is_counterwiggle
			speechicon this add $greettext $greetlength [expr {!$is_counterwiggle}]
			sparetime_talk_anim 4 "p"
			incr talk_step
		}
		3 {
			// Leader festlegen
			if {$talk_leader==$myref} {
				if {[sparetime_talk_change]==2} {
					sparetime_talk_end
				}
			} else {
				sparetime_filler_loop
			}
		}
		4 {
		// Leader spricht
			sparetime_talk_tell
		}
		5 { ;# Leader spricht
			sparetime_talk_listen
		}
		6 { ;# Leader spricht
			sparetime_talk_listen
		}
	}
}
proc sparetime_talk_end {{byself 1}} {
	global talk_step talk_partner talk_leader talk_listener talk_history talk_current_phrase
	global sparetime_fun_mode sparetime_talkanswer myref talk_listener_away current_occupation
	global partner_preference_list reprod_partner talk_issue_history is_talking spt_talk_count
	set implant_issues [list]
	if {$spt_talk_count} {
		sparetime_fun_entry "talk"
	}
	foreach issue $talk_issue_history {
		if {[string is integer [string index $issue 0]]} {
			lappend implant_issues $issue
		}
	}
	if {$reprod_partner} {
		sparetime_talkissue_entry "mnf" [expr {[llength $talk_partner]*2}]
	} else {
		foreach tp $talk_partner {
			if {[set ind [lsearch -glob $partner_preference_list "$tp *"]]!=-1&&[lindex [lindex $partner_preference_list $ind] 1]>2000} {
				sparetime_talkissue_entry "mnc" 2.0
			} else {
				sparetime_talkissue_entry "mnf" 1.0
			}
		}
	}
	if {$byself} {
		if {$talk_leader==$myref} {set erg [sparetime_talk_change 1]} {set erg 1}
		//log "[get_objname this] talkend ($talk_partner) $talk_leader $talk_listener"
		foreach partner $talk_partner {
			//log "[get_objname $partner] ([ref_get $partner talk_partner]) ([ref_get $partner talk_leader]) ([ref_get $partner talk_listener])"
			if {[obj_valid $partner]&&[get_objclass $partner]=="Zwerg"} {
				if {$erg==1} {
					call_method $partner finish_talk [get_ref this]
				} else {
					call_method $partner end_talk_too
				}
				foreach issue $implant_issues {
					if {![call_method $partner talk_issue_exist $issue]} {
						call_method $partner talk_issue_implant $issue [expr {[sparetime_talkissue_get $issue]*0.8}]
					}
				}
			} else {
				//log "partner: $partner"
			}
			//log "[get_objname $partner] ([ref_get $partner talk_partner]) ([ref_get $partner talk_leader]) ([ref_get $partner talk_listener])"
		}
		if {$talk_step>3&&[string first $current_occupation "funslpeat"]!=-1||$current_occupation=="reprod"&&$talk_partner!=$reprod_partner} {
			sparetime_talk_bye
		}
	}
	set sparetime_talkanswer 0
	set sparetime_fun_mode ""
	set talk_step 0
	set spt_talk_count 0
	set talk_partner ""
	set talk_leader 0
	set talk_listener 0
	set talk_listener_away 0
	set talk_history {4}
	set talk_current_phrase ""
	set is_talking 0
	set_eye_focus 0
}
proc sparetime_talk_change {{leave 0}} {
	global sparetime_fun_log
	// Wortführer und Hauptzuhörer festlegen
	global talk_partner talk_leader talk_listener talk_history talk_step myref gnome_gender
	set vorher [list $talk_partner $talk_leader $talk_listener $talk_history $talk_step $myref $leave]
	//log "[get_objname this] passing stc"
	if {$leave} {set qlist [list]} {set qlist [list [list $myref [sparetime_talk_urge]]]}
	foreach g $talk_partner {
		if {[dist_between this $g]>2} {
			lappend qlist [list $g -10]
		} else {
			lappend qlist [list $g [call_method $g get_talk_urge]]
		}
	}
	set qlist [lsort -index 1 -decreasing -real $qlist]
	if {[lindex [lindex $qlist 0] 1]<1.0} {return 2}
	set talk_leader [lindex [lindex $qlist 0] 0]
	set changing [expr {$talk_leader==$myref}]
	if {[llength $qlist]>1} {
		set talk_listener [lindex [lindex $qlist 1] 0]
	} else {
		set talk_listener 0
	}
	fun_log " ($myref,$leave): new leader ($talk_leader) and listener ($talk_listener) $qlist"
	set i 4
	foreach qg $qlist {
		set g [lindex $qg 0]
		set status [hmin 6 $i]
		if {$g==$myref} {
			set talk_step $status
		} else {
			//log "$myref telling new status to $g: $talk_leader $talk_listener $changing"
			call_method $g set_talk_status $status $talk_leader $talk_listener $changing
		}
		incr i
	}
	if {$changing} {set talk_history [concat $talk_step [lrange $talk_history 0 4] 4]}
	set nachher [list $talk_partner $talk_leader $talk_listener $talk_history $talk_step $myref $leave]
	set checklist [concat $talk_partner $myref]
	foreach entry $checklist {
		if {[lcount $checklist $entry]>1} {
			log "FEHLER in sparetime_talk_change [get_objname this]:"
			log $vorher
			log $nachher
			break
		}
	}
	if {$talk_step==4} {return 0} {return 1}
}
proc sparetime_talk_next {} {
	global sparetime_talkissues talk_partner talk_issue_history gnome_gender reprod_partner
	foreach tp $talk_partner {
		if {$tp==$reprod_partner} {
			sparetime_talkissue_delete "ttp"
		}
	}
	set ris ""
	set cv -100.0
	set rv 0.0
	set st [expr {10-[llength $talk_issue_history]}]
	foreach entry [talkissue this list] {
		set val [talkissue this get $entry]
		if {$val>50.0} {log "WARNING: talkissue get returned value greater than 50.0!!! (this=[get_ref this] entry=$entry val=$val) "}
		if {$val<3.0} {continue}
		set name [lindex $entry 0]
		if {[lindex $talk_issue_history 0]==$name} {continue}
		set i $st
		set red 50
		foreach elem $talk_issue_history {
			if {$elem==$name} {incr red -$i}
			incr i
		}
		set red [expr {$red * 0.02}]
		if {$red<0.9} {set nv [expr {$val * $red * $red * 0.6}]} {set nv $val}
		// log "$name -> $val ($talk_issue_history)"
		if {$nv<3.0} {continue}
		if {$nv>$cv} {set cv $nv; set ris $name; set rv $val}
	}
	if {$cv<1.0} {
		set sm_issues [lindex [smalltalk get "smt"] 0]
		set sg 1
		//log "[get_objname this] passing stn ($talk_partner)"
		foreach g $talk_partner {
			//set err [catch {log "[get_objname $g] ($g) $gnome_gender"} errMsg]
			//if {$err} {log "Fehler1 in stn [get_objname this]: $errMsg"}
			set gen [call_method $g get_gender]
			//if {$err} {log "Fehler2 in stn [get_objname this]: $errMsg";set gen male}
			if {$gen!=$gnome_gender} {
				set sg 0
				break
			}
		}
		if {$sg} {lappend sm_issues "amng"}
		set rem_iss [list]
		foreach issue $sm_issues {
			if {[lsearch $talk_issue_history $issue]==-1} {
				lappend rem_iss $issue
			}
		}
		if {[get_attrib this atr_Nutrition]<0.6} {lappend rem_iss "hun"}
		if {[get_attrib this atr_Alertness]<0.5} {lappend rem_iss "tir"}
		if {[get_attrib this atr_Hitpoints]<0.8} {lappend rem_iss "ill"}
		if {$rem_iss!=""} {
			set issue [lindex $rem_iss [irandom [llength $rem_iss]]]
			sparetime_talkissue_entry $issue 4.0 0
			set ris $issue
			set rv 4.0
			set cv 4.0
		}
	}
	return [list $ris $rv $cv]
}
proc sparetime_talk_urge {{self 1}} {
	global spt_talk_desire talk_history talk_step spt_talk_urge
	if {$talk_step<3} {return -50.0}
	set last_lead [lsearch $talk_history 4]
	if {$self||$spt_talk_urge=="undef"} {
		set myissue [sparetime_talk_next]
		set val [lindex $myissue 2]
		//log "stu: $spt_talk_desire $last_lead $val"
		if {$spt_talk_desire<0.1} {set spt_talk_desire 0.0}
		//log "Rückgabewert stu: [expr {sqrt($spt_talk_desire)*$val*(1<<$last_lead)}] ([get_objname this])"
		set spt_talk_urge [expr {sqrt($spt_talk_desire)*$val}]
	}
	return [expr {$spt_talk_urge*(1<<$last_lead)}]
}
proc sparetime_talk_tell {} {
	global spt_talk_desire sparetime_talkissues
	global talk_step talk_listener gnome_gender at_Mo spt_talk_count spt_fun_portion
	global talk_current_phrase talk_leader myref talk_issue_relief talk_mood_relief
	global talk_listener_away talk_sign talk_current_issue talk_imthe_leader talk_current_length
	global sparetime_fun_log
	set talk_sign ""
	if {$talk_current_phrase==""} {
		set talk_current_issue ""
		if {$talk_imthe_leader} {
			set change_result 0
		} else {
			set change_result [sparetime_talk_change]
		}
		if {$change_result} {
			if {$change_result==2} {sparetime_talk_end}
			return
		}
		incr spt_talk_count
		if {$spt_talk_count>3} {
			sparetime_fun_entry "talk"
		} elseif {$spt_talk_count>1} {
			global sparetime_goal at_Mo at_Nu at_Al
			if {($at_Mo-[lindex $sparetime_goal 1]>0.1)||($at_Nu<0.8)||($at_Al<0.9)} {
				sparetime_fun_entry "talk"
			}
		}
		set nextissue [sparetime_talk_next]
		set talk_current_issue [lindex $nextissue 0]
		set value [lindex $nextissue 1]
		if {$talk_current_issue==""} {set talk_current_issue ooi; set value 5.0}
		fun_log "std $spt_talk_desire"
		if {$value>$spt_talk_desire} {
			log "WARNING: issue_value($value)>talk_desire!!! ($talk_current_issue, $spt_talk_desire)"
			set value $spt_talk_desire
		}
		set morel [expr {[hmin [hmax 0.1 [expr {$value/$spt_talk_desire}]] 0.3] * $spt_fun_portion}]
		set orel [expr {(1-$value/$spt_talk_desire)*$value}]
		set relief -[hmax $orel 2.0]
		set morel [hmax $morel 0.01]
		if {[string is integer [string index $talk_current_issue 0]]} {
			set relief -1.0
		}
		set animcnt 0
		set original_phrase [sparetime_talk_phrase $talk_current_issue $value]
		if {rand()<$change_result*0.3+0.2} {
			set original_phrase [concat [list [sparetime_talk_answer "t"]] $original_phrase]
		}
		set talk_current_phrase {}
		set talk_current_length 0
		set listener_phrase {}
		set who_is_multiple 0
		set opl [llength $original_phrase]
		for {set i 0} {$i<$opl} {} {
			set entry [lindex $original_phrase $i]
			incr i
			if {([string index $entry 0]==":")^$who_is_multiple} {
				lappend listener_phrase $entry
				if {$i==$opl||([string index [lindex $original_phrase $i] 0]!=":")^$who_is_multiple} {
					set entry [lindex $listener_phrase [irandom [llength $listener_phrase]]]
					set listener_phrase {}
					set who_is_multiple [expr {!$who_is_multiple}]
				} else {
					continue
				}
			}
			incr talk_current_length [expr {([string length $entry]+[llength $entry])/10+1}]
			lappend talk_current_phrase $entry
		}
		set talk_issue_relief $relief
		set talk_mood_relief $morel
		fun_log "[get_objname this]: $morel ($orel->$relief / $value) $at_Mo $talk_current_issue $talk_issue_relief $talk_mood_relief"
		fun_log "[get_objname this]: $talk_current_phrase"
		set_eye_focus $talk_listener
		sparetime_talk_entry $talk_current_issue
	} else {
		if {$talk_listener_away} {
			set talk_listener_away 0
			set talk_current_phrase [sparetime_talk_phrase "lra" 10.0]
			set talk_current_length [expr {([string length $talk_current_phrase]+[llength [join $talk_current_phrase]])/10+1}]
			set talk_issue_relief 0.0
			set talk_mood_relief 0.0
			sparetime_talk_change
		}
	}
	rotate_towards $talk_listener
	set next_phrase [lindex $talk_current_phrase 0]
	lrem talk_current_phrase 0
	set speechcnt [expr {([string length $next_phrase]+[llength $next_phrase])/10+1}]
	set animcnt [expr {$speechcnt*0.6}]
	//set phrase [lindex $next_phrase 1]
	//set animcnt [lindex $next_phrase 0]
	speechicon this clear
	set last_sign [string index $next_phrase end]
	if {[string index $talk_current_phrase 1]==":"} {
		set talk_sign ""
	} elseif {[string first $last_sign "!.?"]!=-1&&[string index $next_phrase [expr {[string length $next_phrase]-2}]]!="."} {
		//log "TALKSIGN $phrase -> $last_sign ([string index $phrase [expr {[string length $phrase]-2}]])"
		set talk_sign $last_sign
	}
	global is_counterwiggle
	if {[string index $next_phrase 0]==":"} {
		set next_phrase [string trimleft $next_phrase ":"]
		if {$talk_sign!=""} {set talk_sign "s$talk_sign"}
		speechicon $talk_listener clear
		speechicon $talk_listener add $next_phrase $speechcnt [expr {!$is_counterwiggle}]
		for {set i 0} {$i<$animcnt} {incr i} {
			sparetime_talk_anim 5 ""
		}
	} else {
		speechicon this add $next_phrase $speechcnt [expr {!$is_counterwiggle}]
		for {set i 1} {$i<$animcnt} {incr i} {
			sparetime_talk_anim 4 "p"
		}
		sparetime_talk_anim 4 $talk_sign
	}
	set part [expr {1.0*$speechcnt/$talk_current_length}]
	tasklist_add this "sparetime_talk_relief $part"
}
proc sparetime_talk_bye {} {
	global is_counterwiggle
	set byetext [sparetime_talk_answer "b"]
	if {[string length $byetext]>40} {
		set byelength 3
		sparetime_talk_anim 4 "p"
	} else {
		set byelength 1.5
	}
	speechicon this clear
	speechicon this add $byetext $byelength [expr {!$is_counterwiggle}]
	sparetime_talk_anim 4 "p"
}
proc sparetime_talk_relief {part} {
	global talk_issue_relief talk_mood_relief talk_current_issue
	global spt_talk_desire
	add_attrib this atr_Mood [expr {$talk_mood_relief*$part}]
	if {[lsearch [talkissue this list] $talk_current_issue]==-1} {return}
	set od $spt_talk_desire
	sparetime_talkissue_entry $talk_current_issue $talk_issue_relief 0
	set relief [expr {$spt_talk_desire-$od}]
}
proc sparetime_talk_listen {} {
	global talk_step talk_leader spt_talk_desire myref
	global sparetime_fun_log
	set waitcnt [expr {int(1.1+0.5*[tasklist_cnt $talk_leader])}]
	rotate_towards $talk_leader
	set_eye_focus $talk_leader
	if {$talk_step==6||$myref==$talk_leader} {
		set step 6
		set sign ""
		for {set i 0} {$i<$waitcnt} {incr i} {
			sparetime_talk_anim $step ""
		}
	} else {
		set endsign [call_method $talk_leader get_talk_sign]
		if {$endsign==""} {
			set step 5
			set sign ""
		} elseif {[string length $endsign]==1} {
			if {$waitcnt<2} {
				global is_counterwiggle
				set step 4
				set sign "p"
				set phrase [sparetime_talk_answer $endsign]
				speechicon this clear
				speechicon this add $phrase 5 [expr {!$is_counterwiggle}]
			} else {
				set step 5
				set sign ""
				set endsign ""
			}
		} else {
			set step 4
			set endsign [string index $endsign 1]
			set sign "p"
		}
		for {set i 0} {$i<$waitcnt-1} {incr i} {
			sparetime_talk_anim $step $sign
		}
		sparetime_talk_anim $step $endsign
	}
	sparetime_fun_relief 0.00$waitcnt
	fun_log "[get_objname this]: $step $sign (talklisten) $waitcnt"
	if {$waitcnt<3} {fun_log "[get_objname this]: [tasklist_list $talk_leader] ([get_objname $talk_leader])"}
	if {[is_selected this]} {fun_log "[get_objname this]: [get_attrib this atr_Mood] $spt_talk_desire"}
}
proc sparetime_talk_anim {step sign} {
	global talk_partner
	set orsign $sign
	set at_Mo [get_attrib this atr_Mood]
	if {$at_Mo<0.4} {set mood ng} elseif {$at_Mo<0.7} {set mood nt} else {set mood po}
	if {$step<4} {set varia ""} {set varia [mp_pick talkvaria {a b c} a]}
	set sign [string map {"!" e "?" q "." p} $sign]
	if {$sign=="s"} {set sign ""}
	if {$sign==""&&$step==4} {set sign "p"}
	set step [lindex {_ _ _ gr ac re pa} $step]
	set anim talk${step}${mood}${varia}$sign
	//global talk_step;log "[get_objname this] ($talk_step $step $orsign) $anim"
	tasklist_add this "play_anim $anim"
}
proc sparetime_talk_phrase {issue value} {
	global reprod_partner talk_partner talk_listener gnome_gender civ_state
	global sparetime_fun_log
	if {$talk_listener==0} {set talk_listener [obj_query this "-class Zwerg -owner own -range 20 -limit 1"]}
	if {$talk_listener==0} {return {"Kein Zwerg zu sehen!\nMit wem rede ich eigentlich?"}}
	if {$gnome_gender=="male"} {set gen 1} {set gen 2}
	if {[call_method $talk_listener get_gender]==$gnome_gender} {incr gen 4} {incr gen 8}
	if {[string is alpha [string index $issue 0]]} {
		if {$talk_listener==$reprod_partner} {set pat 2} {
			if {[lsearch $talk_partner $reprod_partner]==-1} {set pat 1} {set pat 4}
		}
		// 1: Partner woanders, 2: Partner direkt gegenüber, 4: Partner daneben
	} else {
		if {[call_method $talk_listener talk_issue_exist $issue]} {set pat 2} {
			foreach tp $talk_partner {
				if {[call_method $tp talk_issue_exist $issue]} {
					set pat 4
					break
				}
				set pat 1
			}
		}
		// 1: keiner weiß was, 2: Gegenüber weiß es schon, 4: jemand hier weiß es schon
	}
	set phrase_list {}
	if {$issue=="fli"} {
		global partner_preference_list
		set value 5.0
		foreach entry $partner_preference_list {
			if {[lindex $entry 0]==$talk_listener} {
				set value [hmax 5.0 [expr {[lindex $entry 1]*0.01}]]
				break
			}
		}
	} elseif {$issue=="prgn"} {
		global spt_last_sex
		set value [expr {([gettime]-$spt_last_sex)*0.03333}]
	} elseif {$issue=="old"} {
		global birthtime
		set value [expr {([gettime]-$birthtime-22*1800)*0.01389}]
	}
	set value [hmin 50.0 $value]
	set mood [get_attrib this atr_Mood]
	fun_log "[get_objname this]: $issue ($gen,$pat,[string range $value 0 4],[string range $civ_state 0 4],$mood)"
	foreach entry [smalltalk get $issue] {
		//log $entry
		if {([lindex $entry 0]&$gen)!=$gen} {continue}
		if {([lindex $entry 1]&$pat)!=$pat} {continue}
		if {[lindex $entry 2]>$value+1.0} {continue}
		if {[lindex $entry 3]<$value-0.5} {continue}
		if {[lindex $entry 4]>$civ_state+0.01} {continue}
		if {[lindex $entry 5]>$mood+0.01} {continue}
		if {[lindex $entry 6]<$mood-0.01} {continue}
		//log $entry
		set begin 7
		set evtl [lindex $entry 7]
		if {[string is double $evtl]} {
			if {$evtl<$civ_state-0.01} {continue}
			set begin 8
		}
		lappend phrase_list [lrange $entry $begin end]
	}
	if {$phrase_list==""} {return "\{$issue ($gen,$pat,[string range $value 0 4],[string range $civ_state 0 4])\nnicht eingetragen!\}"}
	return [lindex $phrase_list [irandom [llength $phrase_list]]]
}
proc sparetime_talk_answer {sign} {
	set sign [string map {"." p "?" q "!" e} $sign]
	global sparetime_fun_log
	set phrase_list {}
	set mood [get_attrib this atr_Mood]
	foreach entry [smalltalk get "xx$sign"] {
		if {[lindex $entry 0]>$mood+0.02} {continue}
		if {[lindex $entry 1]<$mood-0.02} {continue}
		lappend phrase_list [lindex $entry 2]
	}
	if {$phrase_list==""} {return "answer ($sign,[string range $mood 0 4])nicht eingetragen!"}
	return [lindex $phrase_list [irandom [llength $phrase_list]]]
}
proc sparetime_talk_remove {ref} {
	global talk_partner
	foreach entry $talk_partner {
		if {[lcount $talk_partner $entry]>1} {
			log "FEHLER in talk_remove1 [get_objname this]: ($talk_partner) $ref"
		}
	}
	set talk_partner [lnand $ref $talk_partner]
	foreach entry $talk_partner {
		if {[lcount $talk_partner $entry]>1} {
			log "FEHLER in talk_remove2 [get_objname this]: ($talk_partner) $ref"
		}
	}
}
proc sparetime_add_partner {ref {firstone 1}} {
	global talk_partner
	if {[land $ref $talk_partner]!=""} {
		log "FEHLER in add_partner [get_objname this]: ($talk_partner) $ref ($firstone)"
	}
	if {$firstone} {
		foreach g $talk_partner {
			call_method $g add_talk_partner $ref
		}
	}
	lappend talk_partner $ref
}
