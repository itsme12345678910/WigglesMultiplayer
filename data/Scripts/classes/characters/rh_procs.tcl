proc walk_pos {pos} {
	state_disable this
	set pos [vector_fix $pos]
	action this walk "-target \{$pos\} -canclimb 0 -animsets 0" {state_enable this}
	return true
}


proc walk_random {plength} {
	if {[mp_active]} {
		# Multiplayer: Zielpunkt vom Host statt Zufallspfad der Engine, ohne Host kurz warten
		set place [mp_random_target walkrandom $plength]
		if {$place == ""} {return [wait_time 1.0]}
		return [walk_pos $place]
	}
	state_disable this
	action this walk "-canclimb 0 -animsets \{0 0 0 0\}  -randompath $plength -randomz 5" {state_enable this}
	return true
}


proc run_pos {pos} {
	state_disable this
	set pos [vector_fix $pos]
	action this walk "-target \{$pos\} -canclimb 0 -animsets \{1 1 1 0\}" {state_enable this}
	return true
}


proc run_random {plength} {
	if {[mp_active]} {
		# Multiplayer: Zielpunkt vom Host statt Zufallspfad der Engine, ohne Host kurz warten
		set place [mp_random_target runrandom $plength]
		if {$place == ""} {return [wait_time 1.0]}
		return [run_pos $place]
	}
	state_disable this
	action this walk "-canclimb 0 -animsets 1 -randompath $plength -randomz 5" {state_enable this}
	return true
}


proc run_pos_obj {pos obj {dist 1.8}} {
	state_disable this
	set pos [vector_fix $pos]
	action this walk "-target \{$pos\} -objbreak \{$obj $dist\} -animsets 1" "state_enable this;run_pos_stop $obj"
	return true
}

proc wait_time {time} {
	state_disable this
	action this wait $time { state_enable this }
}

proc play_anim {anim} {
	state_disable this
	action this anim $anim {state_enable this}
	return true
}


proc waiting {time} {
	global ANIM_LOOP
	set_anim this standanim 0 $ANIM_LOOP
	wait_time $time
}


proc cleaning {time} {
	for {set i 0} {$i < $time} {incr i} {
		tasklist_add this "play_anim clean"
	}
}

proc sleeping {time} {
	tasklist_add this "play_anim sleep_start"
	for {set i 0} {$i < $time} {incr i} {
		tasklist_add this "play_anim sleep_loop"
	}
	tasklist_add this "play_anim sleep_end"
}

proc rotate_toright {} {state_disable this;action this rotate 4.71 {state_enable this}}
proc rotate_toleft {}  {state_disable this;action this rotate 1.57 {state_enable this}}
proc rotate_toback {}  {state_disable this;action this rotate 3.14 {state_enable this}}
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


proc set_idle_anim {} {
	global ANIM_LOOP
	set_anim this riesenhamster.standanim 0 $ANIM_LOOP
}


proc loop_anim {anim min max} {
	set reps [hf2i [mp_random loopreps 0.0 [expr $max - $min]]]
	incr reps $min
	for {set i 0} {$i < $reps} {incr i} {
		tasklist_add this "play_anim $anim"
	}
}


// sucht nach Zwergen zum Angreifen
// returns:		0 - niemand gefunden
// 				1 - Angriff eingeleitet

proc find_enemy {} {
	global scan_range attack_behaviour attack_item look_dir new_fight_pos approach
	set mindist 1000
	set attack_item 0
	set fzwerg_list [obj_query this "-range $scan_range -class Zwerg -owner 0"]
	if { $fzwerg_list == 0 } {
		return 0
	}

	set ownpos [get_pos this]
	foreach fzwerg $fzwerg_list {
		set enemypos [get_pos $fzwerg]
		set dist [vector_dist $ownpos $enemypos]
		if { $dist < $mindist } {
			set mindist $dist					;# nahen zwerg suchen
		}

		set attack_behaviour "offensive"
		set attack_item $fzwerg

		if { [state_get $attack_item] == "fight_dispatch"  } {
			continue
		}

		log "[get_objname this]: [get_objname $attack_item]has [get_attrib $attack_item atr_Hitpoints] HP"
		if { [get_attrib $attack_item atr_Hitpoints] < 0.01 } {
			continue
		}

		if { [get_attack_pos this $attack_item] == 0 } { continue }
		set approach 1
		fight_startfight
		return 1
	}
	return 0
}

proc beamto_inv {item} {
	inv_add this $item
	set_rotx $item 0.0
	set_rotz $item 0.0
	set_owner $item [get_owner this]
	return true
}
