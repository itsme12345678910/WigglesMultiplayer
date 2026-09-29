// Fun-Aktivitäten in der Freizeit
// Auflistung:
// Prügeln * struggle, 									str *
// Trösten * comfort, 									cmf *
// Flirten * flirt, 									fli *
// Schmusen * smooch, 									smo *
// Erzählen * tell, 									tll *
// Zuhören * listen, 									lis *
// Versöhnen - console, 								cns
// Irgendwas tun * default, 							dft *
// Arbeitenden zusehen - watchworkers, 					waw
// Hamsterreiten - hamsterride, 						hrd
// Hamsterjagen - hamserhunt, 							hht
// Raupen in die Länge ziehen - wormtearing, 			wtr
// Schmetterlingjagen - flyhunting						fly
// Selbstbeschäftigung - pastime, 						pst
// Schnüffeltuch * sniff, 								snf
// Barbesuch * 											pub *
// Theaterbesuch * theater, 							tht *
// Wohnaktivitäten * noch aufschlüsseln
// Um Kind kümmern * careforchild, 						cfc
// Badbesuch * bath, 									bth
// Discobesuch * disco, 								dsc *
// Krafttraining * fitness, 							fit *
// Bowlingabend * bowling, 								bow *
// Bordellbesuch * brothel,								brl *
// Verabreden zur Gemeinsamen Aktion - appointment, 	app
// Die mit Sternchen bedeuten Wünsche VOR dem Entschluss für Fun
// die anderen können sich daraus ergeben

// Gesprächsthemen
// Unqualifiziert gearbeitet (Unfallgefahr) -			uqw *
// Immer am selben gearbeitet -							asw *
// Ständig woanders -									ocw *
// Nicht beim zugewiesenen -							npw *
// Viel gelaufen -										wal *
// Viel gearbeitet -									wtm *
// In Freizeit gearbeitet -								wis *
// Gekämpft -											fgt
// Es fehlt an ... -									lof
// Abbruch durch Spieler -								ubw/ubt/ubr/ubs *
// Ich musste hungrig/müde/launig/krank arbeiten -		whu/wti/wmm/wil *
// Ich mag dich./Magst du mich? -						ilu/ulm
// Habe jemanden kennengelernt/geheiratet -				mnf/mar
// Habe ein Kind gezeugt/bekommen/groß werden sehen -	mlv/gch/cgu
// netter Ausflug zum ... -								pub/brl/dsc/bow/fit/tht
// ... war nicht in Betrieb weil ... -					nos/nmt
// zu lange Wege in Freizeit -							tlw
// Was wollen wir unternehmen? -						wdd
// Wollen wirs tun? -									sex
// Ich möchte mit jemandem flirten						fli *
// Ich möchte mit meinem Partner reden					ttp *

set sparetime_fun_log 0
set fss 0
set fsl 0
proc fun_log {str} {
	global sparetime_fun_log
	if {$sparetime_fun_log} {
		log [get_objname this]:$str
	}
}

proc sparetime_translate_name {name dir} {
	switch $dir {
		"cv" { return [string map {Bar pub Disco dsc Theater tht Bordell brl Fitnessstudio fit Bowlingbahn bwl} $name] }
		"vc" { return [string map {pub Bar dsc Disco tht Theater brl Bordell fit Fitnessstudio bwl Bowlingbahn} $name] }
	}
}
proc sparetime_fun_check {} {
	global reprod_partner 
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	if {[obj_query this -class Zwerg -owner own -range 20 -limit 1]} {
		set result 1
	} else {
		set result 0
	}
	set bitwert 2
	foreach occup {fun home sex} {
		set plist [sparetime this queryrect $occup -$max_search_range -$half_search_range $max_search_range $half_search_range]
		if {$plist!=""} {
			incr result $bitwert
			set bitwert [expr {$bitwert<<1}]
		}
	}
	if {$reprod_partner} {
		if {[dist_between this $reprod_partner]<200} {
			set result [expr {$result|8+16}]
		}
	}
	return $result
}
proc sparetime_fun_entry {name} {
	global sparetime_fun_history spt_fun_stations spt_fun_fail
	lappend sparetime_fun_history $name
	if {[llength $sparetime_fun_history]>17} {set sparetime_fun_history [lrange $sparetime_fun_history 1 end]}
	fun_log " fun_entry $name"
	if {$name=="none"||$name=="self"} {return}
	set idx [lsearch {talk place home sex prtn} $name]
	if {$idx!=-1} {
		set bitwert [expr {1<<$idx}]
		set spt_fun_stations [expr {$bitwert|$spt_fun_stations}]
		set spt_fun_fail [expr {~$bitwert&$spt_fun_fail}]
	}
	global spt_last_$name spt_$name\_desire
	set spt_last_$name [gettime]
	fun_log " spt_fun_stations after entry $name: $spt_fun_stations"
	if {$name=="talk"} {return}
	set spt_$name\_desire 0.0
}
proc sparetime_check_funhistory {name cnt} {
	global sparetime_fun_history
	set len [llength $sparetime_fun_history]
	incr len
	incr len -$cnt
	if {[lsearch [lrange $sparetime_fun_history $len end] $name]!=-1} {
		return 1
	} else {
		return 0
	}
}
proc sparetime_fun_start {} {
	global sparetime_fun_mode sparetime_talkanswer spt_place_desire
	global spt_prtn_desire myref willing_to_reprod spt_talk_desire spt_fun_needs
	global spt_home_desire spt_sex_desire sparetime_seat spt_fun_stations spt_fun_ignore
	set oldmode $sparetime_fun_mode
	//if {$sparetime_fun_mode=="self"} {log "talk: $spt_talk_desire place: $spt_place_desire home: $spt_home_desire sex: $spt_sex_desire"}
	set statmask $spt_fun_stations
	set qgnome 0
	set qplace 0
	set qhome 0
	set qprtn 0
	set qsex 0
	set pass 0
	set neednothing 0
	while {$pass<2} {
		if {($statmask&16)==0} {
			if {$qprtn==0} {set qprtn [sparetime_prtn_find]} {set qprtn ""}
			if {$qprtn==""} {
				set statmask [expr {$statmask|16}]
			} else {
				set spt_fun_ignore 0
				sparetime_visit_partner $qprtn
				return 1
			}
		}
		fun_log " $neednothing [expr {$spt_talk_desire>5.0}] [expr {$spt_talk_desire+10>$spt_place_desire}] [expr {($spt_fun_stations&3)==2}] [expr {$spt_talk_desire+10>$spt_home_desire}] [expr {($spt_fun_stations&5)==4}]"
		if {$spt_talk_desire>5.0&&($neednothing+(($statmask&1)==0)>1||((($statmask&7)&6)||$spt_talk_desire+10>[hmax $spt_place_desire $spt_home_desire]))} {
			//fun_log "qgnome: $qgnome"
			if {$qgnome==0} {set qgnome [sparetime_talk_find]} {set qgnome ""}
			if {$qgnome==""} {
				set statmask [expr {$statmask|1}]
			} else {
				set gnome [lindex $qgnome 0]
				set spt_fun_ignore 0
				sparetime_talk_start $gnome 1
				call_method $gnome start_talk $myref
				log "[get_objname this] starts talk with [get_objname $gnome] ($gnome). ($oldmode,$sparetime_fun_mode) [tasklist_cnt this]"
				set willing_to_reprod 0
				if {$oldmode!=$sparetime_fun_mode} {return 1} {return 0}
			}
		}
		if {$spt_place_desire>80.0||($neednothing+(($statmask&2)==0)>1||($spt_fun_stations&6)!=4)&&$spt_place_desire>30.0} {
			if {$qplace==0} {set qplace [sparetime_place_find]} {set qplace ""}
			//if {$sparetime_fun_mode=="talk"} {return $qplace}
			if {$qplace==""} {
				set statmask [expr {$statmask|2}]
			} else {
				set place [lindex $qplace 0]
				set spt_fun_ignore 0
				if {[lindex $qplace 3]} {
					global sparetime_current_place_ref sparetime_reservation sparetime_disappointment
					global sparetime_current_place
					set link [call_method $place reserve_seat $myref]
					set sparetime_current_place_ref $place
					set sparetime_current_place [get_objclass $place]
					if {!$link} {set link [call_method $place default_link]}
					set sparetime_reservation 1
					log "[get_objname this] checking in reserved at $link"
				} else {
					if {[check_method [get_objclass $place] get_random_seat]} {
						sparetime_check_in $place -1
					} else {
						sparetime_check_in $place
					}
					global sparetime_seat
					set link $sparetime_seat
					set sparetime_reservation 0
					log "[get_objname this] checking in directly at $link"
				}
				set dummy [prod_guest getlink $place $link]
				tasklist_add this "walk_dummy $place $dummy"
				if {$spt_talk_desire>$spt_place_desire+30} {
					set sparetime_talkanswer 1
				} else {
					set sparetime_talkanswer 0
				}
				set sparetime_disappointment [lindex $qplace 2]
				set sparetime_fun_mode "place"
				set willing_to_reprod 0
				if {$oldmode!=$sparetime_fun_mode} {return 1} {return 0}
			}
		}
		if {$spt_home_desire>70.0||($neednothing+(($statmask&4)==0)>1)&&$spt_home_desire>30.0} {
			if {$qhome==0} {set qhome [sparetime_home_find]} {set qhome ""}
			fun_log "HomeFind: $qhome"
			if {$qhome==""} {
				set statmask [expr {$statmask|4}]
			} else {
				set spt_fun_ignore 0
				sparetime_home_start $qhome
				if {$oldmode!=$sparetime_fun_mode} {return 1} {return 0}
			}
		}
		if {$spt_sex_desire>80.0} {
			if {$qsex==0} {set qsex [sparetime_sex_find]} {set qsex ""}
			if {$qsex==""} {
				set statmask [expr {$statmask|8}]
			} else {
				set spt_fun_ignore 0
				set place [lindex $qsex 0]
				sparetime_check_in $place
				set dummy [prod_guest getlink $place 0]
				tasklist_add this "walk_dummy $place $dummy"
				set sparetime_fun_mode "sex"
				set willing_to_reprod 0
				if {$oldmode!=$sparetime_fun_mode} {return 1} {return 0}
			}
		}
		if {$pass==0} {
			set fundone 0
			for {set i 1} {$i<17} {set i [expr {$i<<1}]} {
				if {$i&$spt_fun_stations} {
					incr fundone
				}
			}
			if {$fundone==$spt_fun_needs-1} {
				set neednothing 1
			} elseif {$fundone>=$spt_fun_needs} {
				set neednothing 2
			} else {
				set neednothing 0
			}
		}
		incr pass
	}
	set willing_to_reprod 1
	set sparetime_talkanswer 1
	set sparetime_fun_mode "none"
	return 0
}

proc sparetime_fun_loop {} {
	global sparetime_talkissues sparetime_fun_mode sparetime_fun_history
	global myref at_Mo spt_fun_ignore
	global sparetime_fun_log
	switch $sparetime_fun_mode {
		"talk" {
			sparetime_talk_loop
			return
		}
		"self" {
			if {[get_gnomeposition this]} {sparetime_climb_somewhere;return}
			//fun_log "act?"
			if {[act_when_idle]} {return}
			//fun_log "start?"
			if {[sparetime_fun_start]} {return}
			//fun_log "find?"
			if {[sparetime_find_talker]} {return}
			set deer [obj_query this -class {Schmetterling} -visibility own -range 10 -flagneg {contained locked} -limit 1]
			if {$deer} {
				switch [get_objclass $deer] {
					"Schmetterling" {if {[sptfun_flyhunting]} {return} }
				}
			}
			set cpos [get_pos this]
			set selfactlist {}
			if {[set wpos [sptfun_check_writing $cpos]]!=""} {
				lappend selfactlist "sptfun_wallwriting \{$wpos\} \{$cpos\}"
			}
			if {[sptfun_check_wheeling $cpos]} {
				lappend selfactlist "sptfun_cartwheeling \{$cpos\}"
			}
			lappend selfactlist "sptfun_footbagging"
			lappend selfactlist "sptfun_jumproping"
			lappend selfactlist "sptfun_pressup"
			lappend selfactlist "sptfun_pipesmoking"
		//	log $selfactlist
			tasklist_add this "sparetime_fun_relief 0.02"
			eval [lindex $selfactlist [irandom [llength $selfactlist]]]
			set sparetime_fun_mode "none"
			sparetime_fun_entry "none"
			set spt_fun_ignore 1
		}
		"none" {
			if {[get_gnomeposition this]} {sparetime_climb_somewhere;return}
			global civ_state stt_fun_idleloss
			tasklist_add this {play_anim standloop[string index abcd [irandom 4]]}
			tasklist_add this "sparetime_idle_loop"
			tasklist_add this {play_anim standloop[string index abcd [irandom 4]]}
			tasklist_add this {play_anim standloop[string index abcd [irandom 4]]}
			tasklist_add this "sparetime_idle_loop"
			set loss [hmax [expr {-$stt_fun_idleloss}] [expr {-0.03*$civ_state}] -0.01]
			tasklist_add this "add_attrib this atr_Mood $loss"
			tasklist_add this {play_anim standloop[string index abcd [irandom 4]]}
			tasklist_add this "sparetime_idle_loop"
			if {[is_selected this]} {fun_log " ml $loss"}
			set sparetime_fun_mode "self"
		}
		"place" {
			global sparetime_current_place_ref sparetime_current_place sparetime_reservation
			sparetime_check_prtn
			set place $sparetime_current_place_ref
			if {$place} {
				if {[obj_valid $place]} {
					if {[get_buildupstate $place]&&![get_prod_pack $place]&&![call_method $place get_inactive]} {
						if {[check_method $sparetime_current_place get_next_action]} {
							set first 1
							foreach cmd [call_method $place get_next_action $myref] {
								if {$first} {eval $cmd} {tasklist_add this $cmd}
								set first 0
							}
							//log "tl: [tasklist_list this]"
							return
						}
					}
				}
			}
			sparetime_place_end
			set sparetime_fun_mode "none"
		}
		"home" {
			sparetime_home_loop
		}
		"sex" {
			sparetime_sex_loop
		}
		default {sparetime_fun_start;return}
	}
}

proc sparetime_fun_end {} {
	global sparetime_talkanswer sparetime_fun_mode willing_to_reprod talk_issue_history
	switch $sparetime_fun_mode {
		"talk" {sparetime_talk_end}
		"place" {sparetime_place_end}
		"home" {sparetime_home_end}
		"sex" {sparetime_sex_end}
	}
	set sparetime_talkanser 0
	set sparetime_fun_mode ""
	set willing_to_reprod 0
	set talk_issue_history {}
}
proc sparetime_find_talker {} {
	global spt_talk_desire spt_talkfind_counter spt_talk_fail sparetime_talkanswer
	global spt_last_talk_fail spt_fun_fail
	//fun_log "spare_find_talker $spt_talkfind_counter"
	if {$spt_talkfind_counter&1} {
		incr spt_talkfind_counter
		return 0
	}
	if {$spt_talk_desire<5.0} {return 0}
	if {$spt_talkfind_counter%10==0} {
		set searchrange [sparetime_searchrange]
	} else {
		set searchrange 25
	}
	set glist [obj_query this "-class Zwerg -owner own -range $searchrange"]
	//fun_log " search for talkers: $glist ($searchrange)"
	if {$glist==0} {set glist {}}
	set found 0
	foreach g $glist {
		if {[get_walkresult $g]==2} {continue}
		if {[dist_between this $g]<10} {continue}
		set nearplace 0
		foreach name {sleep fun home eat bath} {
			if {[sparetime $g queryrange $name 8]!=""} {
				set nearplace 1
				break
			}
		}
		if {$nearplace&&[call_method $g get_current_occupation]=="fun"} {
			if {[call_method $g ask_for_talk]} {
				set found 1;break
			} elseif {$spt_talkfind_counter>9&&($nearplace||[call_method $g get_current_occupation]=="fun")} {
				set found 1;break
			} elseif {$spt_talkfind_counter>19&&[call_method $g get_current_occupation]=="fun"} {
				set found 1;break
			}
		}
	}
	if {$found} {
		if {![isunderwater [get_pos $g]]} {
			set pos [get_place -center [get_pos $g] -rect -6 -8 6 8 -except this -nearpos [get_pos this]]
			if {[lindex $pos 0]>0} {
				log "[get_objname this] talkfind [get_objname $g]"
				set sparetime_talkanswer 0
				tasklist_add this "walk_pos \{$pos\}"
				set spt_last_talk_fail [gettime]
				set spt_fun_fail [expr {$spt_fun_fail|1}]
				set spt_talk_fail 0
				set spt_talkfind_counter 0
				return 1
			}
		}
	}
	if {$spt_talkfind_counter>29} {
		global spt_fun_stations
		set spt_fun_stations [expr {$spt_fun_stations|1}]
		log "TalkFind-Abbruch [get_objname this]"
		set spt_talk_fail 1
	}
	incr spt_talkfind_counter
	return 0
}
proc sparetime_break_bytalk {} {
	global current_occupation sparetime_fun_mode
	if {$current_occupation!="fun"} {return}
	if {$sparetime_fun_mode=="none"||$sparetime_fun_mode=="self"} {
		set taskcnt [tasklist_cnt this]
		set lasttask [tasklist_get this [expr {$taskcnt-1}]]
		tasklist_clear this
		if {[lindex $lasttask 0]=="play_anim"&&[string first "stop" $lasttask]!=-1} {
			tasklist_add this $lasttask
		}
	}
}
proc sparetime_place_find {} {
	global sparetime_recent_places reprod_partner sparetime_avoid_place
	global stt_maxsearch_range spt_favplaces spt_place_desire spt_placefind_counter
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set plist [sparetime this queryrect fun -$max_search_range -$half_search_range $max_search_range $half_search_range]
	if {$plist!=""} {
		//log "placelist: $plist"
		set qplist [list]
		set fplist [list]
		incr spt_placefind_counter
		if {($spt_placefind_counter%5)==0} {
			set found 0
		} else {
			set found 1
		}
		foreach place $plist {
			if {[get_prod_pack $place]} {continue}
			if {$place==[lindex $sparetime_avoid_place 0]} {
				if {[gettime]-[lindex $sparetime_avoid_place 1]<50} {
					continue
				} else {
					set sparetime_avoid_place {0 0.0}
				}
			}
			if {[call_method $place get_inactive]} {continue}
			set placename [sparetime_translate_name [get_objclass $place] cv]
			if {!$found&&[prod_guest guestfree $place]==-1} {
				log "no seat free at $place"
				set placefail 1
			} elseif {$placename=="pub"&&[get_prod_materialneed $place]} {
				set placefail 2
			} else {
				set placefail 0
			}
			set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*3.0}]
			if {$pathcosts<15||[check_method [get_objclass $place] reserve_seat]==0} {
				if {![call_method $place ask_for_seat]} {
					if {[call_method $place ask_for_reserve]} {
						set pathcosts [expr {10-$pathcosts}]
						set reserve 1
					} else {log "[get_objname this] no reservation possible ($place)";continue}
				} else {
					set reserve 0
				}
			} else {
				set reserve 1
			}
			log "pl: pc $pathcosts, afs [call_method $place ask_for_seat], afr [call_method $place ask_for_reserve] $reserve"
			set da [expr {$spt_place_desire*0.2}]
			set da [expr {$da+(1-$da)*0.05*[lcount $sparetime_recent_places $placename]}]
			if {$reprod_partner&&[obj_valid $reprod_partner]} {
				if {$place == [call_method $reprod_partner get_sparetime_place]} {
					set pathcosts [expr {$pathcosts*0.5}]
					set da [expr {$da*0.5}]
				}
			}
			if {[lsearch $spt_favplaces $placename]!=-1} {set da [expr {$da * 2.0}]}
			set jm [expr {1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$da)}]
			if {$placefail} {
				lappend fplist [list $place $jm $placename $placefail]
			} else {
				lappend qplist [list $place $jm $da $reserve [call_method $place ask_seat_cnt]]
			}
			set found 1
		}
		if {$qplist==""} {
			if {$fplist!=""} {
				set bestfull [lindex [lsort -index 1 -real $fplist] 0]
				if {[lindex $bestfull 3]<2} {
					set reason "[string index [lindex $bestfull 2] 0]fl"
				} else {
					set reason "pnb"
				}
				sparetime_place_fail $reason
			}
			return ""
		}
		return [lindex [lsort -index 1 -real $qplist] 0]
	}
	return ""
}
proc sparetime_home_find {} {
	global reprod_partner sparetime_fun_history sparetime_avoid_place
	global stt_maxsearch_range spt_home_desire
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set plist [sparetime this queryrect home -$max_search_range -$half_search_range $max_search_range $half_search_range]
	fun_log "Homefind: $max_search_range $half_search_range ($plist)"
	if {$plist!=""} {
		//log "placelist: $plist"
		set qplist [list]
		foreach place $plist {
			if {[get_prod_pack $place]} {continue}
			if {[prod_guest guestfree $place]==-1} {log "no seat free at $place";continue}
			if {$place==[lindex $sparetime_avoid_place 0]} {
				if {[gettime]-[lindex $sparetime_avoid_place 1]<50} {
					continue
				} else {
					set sparetime_avoid_place {0 0.0}
				}
			}
			set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*3.0}]
			set da [expr {$spt_home_desire*0.2}]
			if {$reprod_partner&&[obj_valid $reprod_partner]} {
				if {$place == [call_method $reprod_partner get_sparetime_place]} {
					set pathcosts [expr {$pathcosts*0.5}]
					set da [expr {$da*0.5}]
				}
			}
			set jm [expr {1-(1-($pathcosts*$pathcosts)/($stt_maxsearch_range*$stt_maxsearch_range))*(1-$da)}]
			lappend qplist [list $place $jm $da]
		}
		if {$qplist==""} {return ""}
		return [lindex [lsort -index 1 -real $qplist] 0]
	}
	return ""
}
proc sparetime_take_seat {place {meth 0} {gst 0}} {
	global sparetime_reservation sparetime_seat myref
	call_method $place remove_from_guestlist $myref
	sparetime_check_in 0
	sparetime_check_in $place $meth
	if {$gst} {
		call_method $place guest_stateset $sparetime_seat $gst
	} else {
		call_method $place guest_stateset $sparetime_seat 9
	}
	set dummy [prod_guest getlink $place $sparetime_seat]
	//set roty [lindex [get_linkrot $place $dummy] 1]
	tasklist_add this "walk_dummy $place $dummy"
	//tasklist_add this "rotate_toangle $roty"
	//tasklist_add this "play_anim sitdown_chair"
}
proc sparetime_place_talk {} {
	play_anim sitchairbeertalk[string index "abc" [irandom 3]]
	log "[get_objname this] place_talking"
}
proc sparetime_place_end {} {
	global sparetime_current_place_ref myref sparetime_avoid_place sparetime_reservation
	global sparetime_fun_mode
	if {$sparetime_current_place_ref&&[obj_valid $sparetime_current_place_ref]} {
		foreach entry [call_method $sparetime_current_place_ref remove_from_guestlist $myref] {
			if {[string first "sparetime_place_" $entry]!=-1} {
				eval $entry
			} else {
				tasklist_add this $entry
			}
		}
	}
	set sparetime_avoid_place [list $sparetime_current_place_ref [gettime]]
	sparetime_check_in 0
	set sparetime_reservation 0
	set sparetime_fun_mode ""
}

proc sparetime_place_relief {anim mood} {
	global spt_place_desire spt_fun_portion
	add_attrib this atr_Mood [expr {$spt_fun_portion*$mood}]
	//fincr $spt_place_desire -$des
	play_anim $anim
}

proc sparetime_place_fail {reason} {
	global spt_placefail_reason spt_fun_fail sparetime_avoid_place sparetime_current_place_ref
	global spt_last_place_fail
	set ctime [gettime]
	set spt_fun_fail [expr {2|$spt_fun_fail}]
	set sparetime_avoid_place [list $sparetime_current_place_ref $ctime]
	set spt_last_place_fail $ctime
	set spt_placefail_reason $reason
	sparetime_talkissue_entry $reason 5.0
}

proc sparetime_place_finished {} {
	global sparetime_current_place sparetime_current_place_ref sparetime_avoid_place
	global sparetime_recent_fun spt_last_place
	if {[gettime]-$spt_last_place>50.0} {
		sparetime_fun_entry "place"
		lappend sparetime_recent_fun [sparetime_translate_name $sparetime_current_place "cv"]
		if {[llength $sparetime_recent_fun]>10} {lrem sparetime_recent_fun 0}
		set sparetime_avoid_place [list $sparetime_current_place_ref [gettime]]
	}
}

proc sparetime_home_start {qhome} {
	global sparetime_seat spt_talk_desire spt_home_desire sparetime_talkanswer
	global sparetime_fun_mode willing_to_reprod spt_home_counter
	set place [lindex $qhome 0]
	sparetime_check_in $place -1
	set spt_home_counter 0
	set link $sparetime_seat
	set dummy [prod_guest getlink $place $link]
	tasklist_add this "walk_dummy $place $dummy"
	if {$spt_talk_desire>$spt_home_desire+30} {
		set sparetime_talkanswer 1
	} else {
		set sparetime_talkanswer 0
	}
	set sparetime_fun_mode "home"
	set willing_to_reprod 1
}

proc sparetime_home_loop {} {
	global sparetime_current_place_ref sparetime_current_place
	global sparetime_seat spt_home_counter
	if {$spt_home_counter==0} {
		sparetime_update_quality home $sparetime_current_place
	}
	sparetime_check_prtn
	set place $sparetime_current_place_ref
	if {!$place||![obj_valid $place]} {
		sparetime_check_in 0
		return
	}
	if {![get_buildupstate $place]||[get_prod_pack $place]} {
		sparetime_home_end
		return
	}
	set alist [call_method $place get_next_action $sparetime_seat]
	set first 1
	foreach act $alist {
		if {$first} {
			eval $act
			set first 0
		} else {
			tasklist_add this $act
		}
	}
}

proc sparetime_home_relief {anim mood {countup 0}} {
	global spt_fun_portion spt_home_counter
	if {$countup} {
		incr spt_home_counter
	}
	//log "homerelief [get_objname this]: $mood $spt_fun_portion -> [expr {$spt_fun_portion*$mood}]"
	add_attrib this atr_Mood [expr {$spt_fun_portion*$mood*1.3}]
	play_anim $anim
}

proc sparetime_home_change_seat {} {
	global sparetime_current_place_ref sparetime_seat spt_home_counter
	if {$spt_home_counter>5} {sparetime_home_end;return}
	if {!$sparetime_current_place_ref} {
		log "[get_objname this] is not at home, so no change seat!"
		return
	}
	set newseat [call_method $sparetime_current_place_ref get_new_seat $sparetime_seat]
	if {$newseat==-1} {sparetime_home_end;return}
	sparetime_check_in $sparetime_current_place_ref $newseat
	set link $sparetime_seat
	set dummy [prod_guest getlink $sparetime_current_place_ref $link]
	tasklist_add this "walk_dummy $sparetime_current_place_ref $dummy"
}
	
proc sparetime_home_end {} {
	global sparetime_fun_mode sparetime_current_place_ref spt_home_counter
	log "[get_objname this] home end"
	if {$spt_home_counter>1} {
		sparetime_fun_entry "home"
	}
	set sparetime_avoid_place [list $sparetime_current_place_ref [gettime]]
	sparetime_check_in 0
	set sparetime_fun_mode ""
}
proc sparetime_prtn_find {} {
	return 1
}
proc sparetime_visit_partner {val} {
	global spt_fun_stations
	set spt_fun_stations [expr {$spt_fun_stations|16}]
}

proc sparetime_sex_find {} {
	global stt_maxsearch_range gnome_gender sparetime_avoid_place
	set max_search_range [sparetime_searchrange]
	set half_search_range [expr {$max_search_range*0.5}]
	set plist [sparetime this queryrect sex -$max_search_range -$half_search_range $max_search_range $half_search_range]
	if {$plist!=""} {
		set qplist [list]
		foreach place $plist {
			if {$place==[lindex $sparetime_avoid_place 0]} {
				if {[gettime]-[lindex $sparetime_avoid_place 1]<50} {
					log "not again $place";continue
				} else {
					set sparetime_avoid_place {0 0.0}
				}
			}
			if {[prod_guest guestfree $place]==-1} {log "no seat free at $place";continue}
			if {[get_prod_slot_cnt $place _Liebesdienst]==0} {log "no service at $place";continue}
			set worker [call_method $place get_current_worker]
			if {$worker!=0} {
				if {[call_method $worker get_gender]==$gnome_gender} {log "wrong gender at $place";continue}
			}
			set pathcosts [expr {abs([get_posx this]-[get_posx $place])+abs([get_posy this]-[get_posy $place])*3.0}]
			if {$pathcosts<$stt_maxsearch_range} {
				lappend qplist [list $place $pathcosts]
			}
		}
		if {$qplist!=""} {return [lindex [lsort -index 1 -real $qplist] 0]}
	}
	return ""
}
proc sparetime_sex_loop {} {
	global sparetime_current_place_ref myref
	set place $sparetime_current_place_ref
	set first 1
	foreach cmd [call_method $place guest_action $myref] {
		log "sexcmd: $cmd"
		if {$first} {
			eval $cmd
			set first 0
		} else {
			tasklist_add this $cmd
		}
	}
}
proc sparetime_sex_end {} {
	global sparetime_current_place_ref sparetime_fun_mode myref
	set place $sparetime_current_place_ref
	set first 1
	foreach cmd [call_method $place guest_end_action $myref] {
		if {$first} {
			eval $cmd
			set first 0
		} else {
			tasklist_add this $cmd
		}
	}
	log "sexcmd: checkout from $place"
	sparetime_check_in 0
	set sparetime_fun_mode ""
}
proc sparetime_sex_relief {quality} {
	sparetime_fun_entry "sex"
	add_attrib this atr_Mood [hmax [expr {$quality-0.4}] 0.05]
}
proc sptfun_check_writing {cpos} {
	set z [get_hmap [lindex $cpos 0] [expr {[lindex $cpos 1]-0.5}]]
	if {$z>[lindex $cpos 2]-5&&[get_material [vector_add $cpos {0 -0.5 0}]]<3} {
		set pos [get_place -center [lreplace $cpos 2 2 $z] -rect -2 -4 2 4 -except this -nearpos $cpos]
		if {[lindex $pos 0]>0} {
			return $pos
		}
	}
	return ""
}
proc sptfun_wallwriting {pos cpos} {
	if {[vector_abs [vector_sub $pos $cpos]]>0.5} {
		walk_pos $pos
	}
	tasklist_addfront this "play_anim boardwrite"
	tasklist_addfront this "play_anim boardwrite"
	tasklist_addfront this "rotate_toback"
	tasklist_add this "play_anim boardwrite"
	tasklist_add this "play_anim boardwrite"
}
proc sptfun_check_wheeling {cpos} {
	return [get_place -checkfree -center $cpos -rect -2 -1 0 1 -except this]
}
proc sptfun_cartwheeling {cpos} {
	global myref
	placelock_set [vector_add $cpos {-1.5 0 0}] 5 $myref
	rotate_tofront
	tasklist_addfront this "play_anim cartwheel"
	tasklist_addfront this "play_anim cartwheel"
	tasklist_add this "play_anim cartwheel;placelock_rem $myref"
}
proc sptfun_pipesmoking {} {
	tasklist_addfront this "play_anim smokepipeloop"
	tasklist_addfront this "play_anim smokepipeloop"
	tasklist_addfront this "play_anim smokepipeloop"
	tasklist_addfront this "play_anim smokepipeloop"
	tasklist_addfront this "play_anim smokepipestart"
	tasklist_add this "play_anim smokepipeloop"
	tasklist_add this "play_anim smokepipestop"
	tasklist_add this "play_anim cough"
}	
proc sptfun_pressup {} {
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressuploop"
	tasklist_addfront this "play_anim pressupstart"
	tasklist_add this "play_anim pressuploop"
	tasklist_add this "play_anim pressuploop"
	tasklist_add this "play_anim pressupstop"
	tasklist_add this "play_anim tired"
}
proc sptfun_jumproping {} {
	tasklist_addfront this "play_anim jumproping"
	tasklist_addfront this "play_anim jumproping"
	tasklist_addfront this "play_anim jumproping"
	tasklist_addfront this "play_anim jumproping"
	tasklist_addfront this "play_anim jumproping"
	tasklist_add this "play_anim jumproping"
	tasklist_add this "play_anim jumproping"
	tasklist_add this "play_anim wait"
	tasklist_add this "play_anim tired"
}
proc sptfun_footbagging {} {
	tasklist_addfront this "play_anim footbagc"
	tasklist_addfront this "play_anim footbaga"
	tasklist_addfront this "play_anim footbaga"
	tasklist_addfront this "play_anim footbagc"
	tasklist_addfront this "play_anim footbagb"
	tasklist_addfront this "play_anim footbaga"
	tasklist_addfront this "play_anim footbaga"
	tasklist_addfront this "play_anim footbagstart"
	tasklist_add this "play_anim footbagb"
	tasklist_add this "play_anim footbagc"
	tasklist_add this "play_anim footbaga"
	tasklist_add this "play_anim footbagstop"
}
proc sptfun_flyhunting {} {
	set flylist [obj_query this "-class Schmetterling -visibility own -flagneg \{contained locked\} -range 10 -limit 5"]
	if {$flylist==0} {return 0}
	set mypos [get_pos this]
	set myx [lindex $mypos 0]
	set myy [lindex $mypos 1]
	set myz [lindex $mypos 2]
	set found 0
	foreach fly $flylist {
		set flyy [get_posy $fly]
		if {$myy-$flyy>2.0||$myy<$flyy} {continue} {set found 1;break}
	}
	if {!$found} {return 0}
	set pos [get_place -center [spt_groundfix [get_pos $fly]] -rect -2 -3 2 3 -except this -nearpos $mypos]
	if {[lindex $pos 0]<1} {return 0}
	lock_item $fly
	set flyx [lindex $pos 0]
	set flyz [lindex $pos 2]
	set dist [expr {($flyx-$myx)*($flyx-$myx)+($flyz-$myz)*($flyz-$myz)*4.0}]
	if {$dist>12.0} {
		walk_pos $pos
	} elseif {$dist>1.0} {
		run_pos $pos
		sparetime_fun_relief 0.02
	} elseif {$dist>0.2} {
		tasklist_add this "rotate_towards $fly"
		switch [hmax 0 [expr {int(($myy-$flyy)/0.5)}]] {
			0 {tasklist_add this "play_anim butterflyc"}
			1 {tasklist_add this "play_anim butterflyb"}
			2 {tasklist_add this "play_anim butterflya"}
			3 {tasklist_add this "play_anim butterflya"}
			default {tasklist_add this "play_anim digup"}
		}
		tasklist_add this "sparetime_fun_relief 0.03"
	}
	tasklist_add this "unlock_item"
	return 1
}

proc spt_groundfix {pos} {
	set posy [lindex $pos 1]
	set posy [expr {(int($posy+1.49)/4)*4+2.5}]
	return [lreplace $pos 1 1 $posy]
}