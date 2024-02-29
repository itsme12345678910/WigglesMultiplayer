log "parse systeminit script"
log "minimal:[minimalrun]"

# log_mask -* +system +tclerror +gui

;# logmod Tcl								;# print only Tcl logs
logdebug off

if { ![minimalrun] } {
call scripts/init/customcommands.tcl
}

//# IF FULL
set info "[lmsg Language] Full version"
//# ELSE
set info "[lmsg Language] Demo version"
//# ENDIF
log "Loading $info"
set_run_info $info

;# useful procedures
proc ? { args } { print [eval {$args}] }

call scripts/init/shader.tcl
call scripts/init/txtinit.tcl
call scripts/init/animinit.tcl
call scripts/init/classinit.tcl
load_info "[lmsg "Classes done"]"

if { ![minimalrun] } {
call scripts/init/soundinit.tcl
load_info "[lmsg "Soundinit done"]"
call scripts/init/adaptiveinit.tcl
load_info "[lmsg "Musicinit done"]"

call scripts/init/lginit.tcl
load_info "[lmsg "LGInit done"]"

call scripts/init/talkinit.tcl

call scripts/init/claninit.tcl

call scripts/init/makettree.tcl
init_techtree scripts/gameplay/gen_tt.tcl
load_info "[lmsg "Techtree done"]"
}

if { ![minimalrun] } {
call scripts/init/fight.tcl
load_info "[lmsg "Fightinit done"]"
}

#log "initializing artificial inteligence"
ai init 0 data/scripts/ai/std_ai.tcl
set aideflevel [perfoptions playeraidefault]
if { $aideflevel != 0 } {
	log "ai enabled"
	ai enable 0
}
#log "AI initialized"

;# create map and excute procedure gameinit
# map create 128 128 {  }
map create 64 64 {  }

# call data/gamesave/preset_Urwald.tcl
# call data/gamesave/preset_Urwald_a.tcl

if { [file exists data/userstartup.tcl] } {
	call userstartup.tcl
} else {
	if { ![minimalrun] && ![get_mapedit] } {
//# IFNDEF NOSTARTSEQ
		call data/templates/unq_menue.tcl
		MapTemplateSet 25 28

	        call templates/urw_gng_021_a.tcl
	        MapTemplateSet 21 40

	        call templates/urw_gng_022_a.tcl
	        MapTemplateSet 45 40

	    	//map_template data/templates/hol_001.pmp 25 28
	    	set_view 32.368 40.858 1.38 -0.355 0.165		;# set inital camera view (x y zoom)
	    	sel /obj
			set FR [new FogRemover]
			set pos { 32.368 39.5 10 }
			set_pos $FR [vector_add $pos {0 0 0}]
			call_method $FR fog_remove 0 50 50
			call_method $FR timer_delete -1
			adaptive_sound marker menue $pos
			adaptive_sound primary menue

	    	sel /obj
	    	set ts [new Trigger_StartScreen]
	    	call_method $ts validate
	    	call_method $ts disable_logging

//# ENDIF
	} else {
		perfoptions simplecontrol 0
	}
   	gui_new_game
}


call ./data/setupmpconnection.tcl

show_loading no
gametime start
load_done
log "systeminit script succesfully parsed"
