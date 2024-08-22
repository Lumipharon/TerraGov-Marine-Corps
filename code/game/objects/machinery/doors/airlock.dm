//tg wallening
/// Overlay cache.  Why isn't this just in /obj/machinery/door/airlock?  Because its used just a
/// tiny bit in door_assembly.dm  Refactored so you don't have to make a null copy of airlock
/// to get to the damn thing
/// Someone, for the love of god, profile this.  Is there a reason to cache mutable_appearance
/// if so, why are we JUST doing the airlocks when we can put this in mutable_appearance.dm for
/// everything
/proc/get_airlock_overlay(icon_state, icon_file, atom/offset_spokesman, em_block)
	var/static/list/airlock_overlays = list()

	var/base_icon_key = "[icon_state][REF(icon_file)]"
	if(!(. = airlock_overlays[base_icon_key]))
		. = airlock_overlays[base_icon_key] = mutable_appearance(icon_file, icon_state)
	if(isnull(em_block))
		return

	var/em_block_key = "[base_icon_key][em_block]"
	var/mutable_appearance/em_blocker = airlock_overlays[em_block_key]
	if(!em_blocker)
		em_blocker = airlock_overlays[em_block_key] = mutable_appearance(icon_file, icon_state, plane = EMISSIVE_PLANE, appearance_flags = EMISSIVE_APPEARANCE_FLAGS)
		em_blocker.color = em_block ? GLOB.em_block_color : GLOB.emissive_color

	return list(., em_blocker)

// Before you say this is a bad implmentation, look at what it was before then ask yourself
// "Would this be better with a global var"

// Wires for the airlock are located in the datum folder, inside the wires datum folder.

#define AIRLOCK_FRAME_CLOSED "closed"
#define AIRLOCK_FRAME_CLOSING "closing"
#define AIRLOCK_FRAME_OPEN "open"
#define AIRLOCK_FRAME_OPENING "opening"
/// The amount of time for the airlock deny animation to show
#define AIRLOCK_DENY_ANIMATION_TIME (0.6 SECONDS)
/// Time before a door closes, if not overridden
#define DOOR_CLOSE_WAIT 60
//

/obj/machinery/door/airlock
	name = "\improper Airlock"
	icon = 'icons/obj/doors/Doorint.dmi'
	icon_state = "door_closed"
	soft_armor = list(MELEE = 20, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 100, ACID = 0)
	power_channel = ENVIRON
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 360
	atom_flags = HTML_USE_INITAL_ICON_1
	obj_flags = CAN_BE_HIT
	smoothing_groups = list(SMOOTH_GROUP_AIRLOCK)

	var/aiControlDisabled = 0 //If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
	var/hackProof = 0 // if 1, this door can't be hacked by the AI
	var/secondsMainPowerLost = 0 //The number of seconds until power is restored.
	var/secondsBackupPowerLost = 0 //The number of seconds until power is restored.
	var/spawnPowerRestoreRunning = 0
	var/lights = 1 // bolt lights show by default
	secondsElectrified = 0 //How many seconds remain until the door is no longer electrified. -1 if it is permanently electrified until someone fixes it.
	var/aiDisabledIdScanner = 0
	var/aiHacking = 0
	var/list/signalers[12]
	var/lockdownbyai = 0
	autoclose = 1
	var/assembly_type = /obj/structure/door_assembly
	var/mineral = null
	var/justzap = 0
	var/safe = 1
	normalspeed = 1
	var/obj/item/circuitboard/airlock/electronics = null
	var/hasShocked = 0 //Prevents multiple shocks from happening
	var/secured_wires = 0	//for mapping use
	var/no_panel = 0 //the airlock has no panel that can be screwdrivered open
	///used to determine various abandoned door effects
	var/abandoned = FALSE
	///The current state of the airlock, used to construct the airlock overlays
	var/airlock_state
	///Overlay DMI
	var/overlays_file = 'icons/obj/doors/airlocks/tall/overlays.dmi'
	/// TRUE means the door will automatically close the next time it's opened.
	var/delayed_close_requested = FALSE
	/// Cyclelinking for airlocks that aren't on the same x or y coord as the target.
	var/closeOtherId
	///Linked airlock
	var/obj/machinery/door/airlock/closeOther
	///Door open sound
	var/open_sound = 'sound/machines/airlock.ogg'
	///Door open sound
	var/close_sound = 'sound/machines/airlock.ogg'
	///Door open sound
	var/deny_sound = 'sound/machines/deniedbeep.ogg'
	///Door open sound
	var/bolt_up_sound = 'sound/machines/boltsup.ogg'
	///Door open sound
	var/bolt_down_sound = 'sound/machines/boltsdown.ogg'
	///Door open sound
	var/no_power_sound = 'sound/machines/doorclick.ogg'

/obj/machinery/door/airlock/bumpopen(mob/living/user) //Airlocks now zap you when you 'bump' them open when they're electrified. --NeoFite
	if(issilicon(user))
		return ..(user)
	if(iscarbon(user) && isElectrified() && isturf(user.loc))
		if(!justzap)
			if(shock(user, 100))
				justzap = TRUE
				spawn (openspeed)
					justzap = FALSE
				return
		else
			return
	else if(ishuman(user) && user.hallucination > 50 && prob(10) && !operating)
		var/mob/living/carbon/human/H = user
		if(!H.gloves || H.gloves.siemens_coefficient)
			to_chat(H, span_danger("You feel a powerful shock course through your body!"))
			H.adjustStaminaLoss(200)
			return
	return ..(user)

/obj/machinery/door/airlock/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door/airlock/LateInitialize()
	. = ..()
	if(cyclelinkeddir)
		cyclelinkairlock()
	if(!abandoned)
		return
	var/outcome = rand(1,40)
	switch(outcome)
		if(1 to 9)
			var/turf/here = get_turf(src)
			for(var/turf/closed/T in range(2, src))
				here.PlaceOnTop(T.type)
				return
			here.PlaceOnTop(/turf/closed/wall)
			return
		if(9 to 11)
			lights = FALSE
			locked = TRUE
		if(12 to 15)
			locked = TRUE
		if(16 to 23)
			welded = TRUE
		if(24 to 30)
			machine_stat ^= PANEL_OPEN

/obj/machinery/door/airlock/update_icon(updates=ALL, state=0, override=FALSE)
	if(operating && !override)
		return

	if(!state)
		state = density ? AIRLOCK_CLOSED : AIRLOCK_OPEN
	airlock_state = state

	. = ..()

/obj/machinery/door/airlock/update_icon_state()
	. = ..()
	switch(airlock_state)
		if(AIRLOCK_OPEN)
			icon_state = "open_top"
		if(AIRLOCK_CLOSED, AIRLOCK_DENY, AIRLOCK_EMAG)
			icon_state = "closed"
		if(AIRLOCK_OPENING)
			icon_state = "opening"
		if(AIRLOCK_CLOSING)
			icon_state = "closing"


/obj/machinery/door/airlock/update_overlays()
	. = ..()

	var/frame_state
	var/light_state
	switch(airlock_state)
		if(AIRLOCK_CLOSED)
			frame_state = AIRLOCK_FRAME_CLOSED
			if(locked)
				light_state = AIRLOCK_LIGHT_BOLTS
			else if(emergency)
				light_state = AIRLOCK_LIGHT_EMERGENCY
		if(AIRLOCK_DENY)
			frame_state = AIRLOCK_FRAME_CLOSED
			light_state = AIRLOCK_LIGHT_DENIED
		if(AIRLOCK_EMAG)
			frame_state = AIRLOCK_FRAME_CLOSED
		if(AIRLOCK_CLOSING)
			frame_state = AIRLOCK_FRAME_CLOSING
			light_state = AIRLOCK_LIGHT_CLOSING
		if(AIRLOCK_OPEN)
			frame_state = AIRLOCK_FRAME_OPEN
			// If we're open we layer the bit below us "above" any mobs so they can walk through
			. += mutable_appearance(icon, "open_bottom", ABOVE_MOB_LAYER, appearance_flags = KEEP_APART)
		if(AIRLOCK_OPENING)
			frame_state = AIRLOCK_FRAME_OPENING
			light_state = AIRLOCK_LIGHT_OPENING

	if(lights && hasPower())
		. += get_airlock_overlay("lights_[light_state]", overlays_file, src, em_block = FALSE)

	if(machine_stat & PANEL_OPEN)
		. += get_airlock_overlay("panel_[frame_state]", overlays_file, src, em_block = TRUE)
	if(frame_state == AIRLOCK_FRAME_CLOSED && welded)
		. += get_airlock_overlay("welded", overlays_file, src, em_block = TRUE)

	if(airlock_state == AIRLOCK_EMAG)
		. += get_airlock_overlay("sparks", overlays_file, src, em_block = FALSE)

	if(hasPower())
		if(frame_state == AIRLOCK_FRAME_CLOSED)
			if(obj_integrity < integrity_failure * max_integrity)
				. += get_airlock_overlay("sparks_broken", overlays_file, src, em_block = FALSE)
			else if(obj_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_damaged", overlays_file, src, em_block = FALSE)
		else if(frame_state == AIRLOCK_FRAME_OPEN)
			if(obj_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_open", overlays_file, src, em_block = FALSE)

	//update_greyscale() //todo: do we use this?

/obj/machinery/door/airlock/do_animate(animation)
	switch(animation)
		if("opening")
			update_icon(ALL, AIRLOCK_OPENING)
		if("closing")
			update_icon(ALL, AIRLOCK_CLOSING)
		if("deny")
			if(!machine_stat)
				update_icon(ALL, AIRLOCK_DENY)
				playsound(src,deny_sound,50,FALSE,3)
				addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_icon), ALL, AIRLOCK_CLOSED), AIRLOCK_DENY_ANIMATION_TIME)

/obj/machinery/door/airlock/open(forced = DEFAULT_DOOR_CHECKS)
	if( operating || welded || locked)
		return FALSE

	if(!density)
		return TRUE

	// Since we aren't physically held shut, do extra checks to see if we should open.
	if(!try_to_force_door_open(forced))
		return FALSE

	if(autoclose)
		autoclose_in(normalspeed ? 8 SECONDS : 1.5 SECONDS)

	if(closeOther != null && istype(closeOther, /obj/machinery/door/airlock))
		addtimer(CALLBACK(closeOther, PROC_REF(close)), BYPASS_DOOR_CHECKS)

	operating = TRUE
	update_icon(ALL, AIRLOCK_OPENING, TRUE)
	sleep(0.1 SECONDS)
	set_opacity(0)
	if(multi_tile)
		filler.set_opacity(FALSE)
	sleep(0.4 SECONDS)
	set_density(FALSE)
	if(multi_tile)
		filler.set_density(FALSE)
	//flags_1 &= ~PREVENT_CLICK_UNDER_1 //todo: this is useful, should port
	sleep(0.1 SECONDS)
	layer = DOOR_OPEN_LAYER
	update_icon(ALL, AIRLOCK_OPEN, TRUE)
	operating = FALSE
	if(delayed_close_requested)
		delayed_close_requested = FALSE
		addtimer(CALLBACK(src, PROC_REF(close)), FORCING_DOOR_CHECKS)
	return TRUE

/// Additional checks depending on what we want to happen to door (should we try and open it normally, or do we want this open at all costs?)
/obj/machinery/door/airlock/try_to_force_door_open(force_type = DEFAULT_DOOR_CHECKS)
	switch(force_type)
		if(DEFAULT_DOOR_CHECKS) // Regular behavior.
			if(!hasPower() || wires.is_cut(WIRE_OPEN))
				return FALSE
			use_power(50)
			playsound(src, open_sound, 30, TRUE)
			return TRUE

		if(FORCING_DOOR_CHECKS) // Only one check.
			use_power(50)
			playsound(src, open_sound, 30, TRUE)
			return TRUE

		if(BYPASS_DOOR_CHECKS) // No power usage, special sound, get it open.
			playsound(src, open_sound, 30, TRUE)
			return TRUE

		else
			stack_trace("Invalid forced argument '[force_type]' passed to open() on this airlock.")

	// If we got here, shit's fucked, hope parent can help us out here
	return ..()

/obj/machinery/door/airlock/close(forced = DEFAULT_DOOR_CHECKS, force_crush = FALSE)
	if(operating || welded || locked)
		return FALSE
	if(density)
		return TRUE
	if(forced == DEFAULT_DOOR_CHECKS) // Do this up here and outside of try_to_force_door_shut because if we don't have power, we shouldn't be doing any dangerous_close stuff.
		if(!hasPower() || wires.is_cut(WIRE_BOLTS))
			return FALSE

	var/dangerous_close = !safe || force_crush
	if(!dangerous_close)
		for(var/turf/checked_turf in locs)
			for(var/atom/movable/blocking in checked_turf)
				if(blocking.density && blocking != src)
					autoclose_in(DOOR_CLOSE_WAIT)
					return FALSE

	if(!try_to_force_door_shut(forced))
		return FALSE

	var/obj/structure/window/killthis = (locate(/obj/structure/window) in get_turf(src))
	killthis?.ex_act(EXPLODE_HEAVY)
	operating = TRUE
	update_icon(ALL, AIRLOCK_CLOSING, 1)
	layer = DOOR_CLOSED_LAYER
	set_density(TRUE)
	if(multi_tile)
		filler.density = TRUE
	//flags_1 |= PREVENT_CLICK_UNDER_1
	sleep(0.5 SECONDS)
	if(dangerous_close)
		crush()
	if(visible && !glass)
		set_opacity(TRUE)
		if(multi_tile)
			filler.set_opacity(TRUE)
	sleep(0.1 SECONDS)
	update_icon(ALL, AIRLOCK_CLOSED, 1)
	operating = FALSE
	delayed_close_requested = FALSE
	if(!dangerous_close)
		CheckForMobs()
	return TRUE

/obj/machinery/door/airlock/try_to_force_door_shut(force_type = DEFAULT_DOOR_CHECKS)
	switch(force_type)
		if(DEFAULT_DOOR_CHECKS to FORCING_DOOR_CHECKS)
			use_power(50)
			playsound(src, close_sound, 30, TRUE)
			return TRUE

		if(BYPASS_DOOR_CHECKS)
			playsound(src, close_sound, 30, TRUE)
			return TRUE

		else
			stack_trace("Invalid forced argument '[force_type]' passed to close() on this airlock.")

	// shit's fucked, let's hope parent has something to handle it.
	return ..()

/obj/machinery/door/airlock/emp_act(severity)
	. = ..()
	if(prob(75 / severity))
		set_electrified(MACHINE_DEFAULT_ELECTRIFY_TIME)
	if(prob(30 / severity))
		open()

///connect potential airlocks to each other for cycling
/obj/machinery/door/airlock/proc/cyclelinkairlock()
	if (cycle_linked_airlock)
		cycle_linked_airlock.cycle_linked_airlock = null
		cycle_linked_airlock = null
	if (!cyclelinkeddir)
		return
	var/limit = world.view
	var/turf/T = get_turf(src)
	var/obj/machinery/door/airlock/FoundDoor
	do
		T = get_step(T, cyclelinkeddir)
		FoundDoor = locate() in T
		if (FoundDoor && FoundDoor.cyclelinkeddir != get_dir(FoundDoor, src))
			FoundDoor = null
		limit--
	while(!FoundDoor && limit)
	if (!FoundDoor)
		return
	FoundDoor.cycle_linked_airlock = src
	cycle_linked_airlock = FoundDoor

/obj/machinery/door/airlock/proc/isElectrified()
	if(secondsElectrified != MACHINE_NOT_ELECTRIFIED)
		return TRUE
	return FALSE


/obj/machinery/door/airlock/proc/canAIControl(mob/user)
	if(hackProof)
		return
	if(z != user.z)
		return
	return ((aiControlDisabled != 1) && !isAllPowerCut())


/obj/machinery/door/airlock/proc/canAIHack()
	return ((aiControlDisabled==1) && (!hackProof) && (!isAllPowerCut()));


/obj/machinery/door/airlock/hasPower()
	return ((!secondsMainPowerLost || !secondsBackupPowerLost) && !(use_power & NO_POWER_USE))


/obj/machinery/door/airlock/requiresID()
	return !(wires.is_cut(WIRE_IDSCAN) || aiDisabledIdScanner)


/obj/machinery/door/airlock/proc/isAllPowerCut()
	if((wires.is_cut(WIRE_POWER1) || wires.is_cut(WIRE_POWER2)) && (wires.is_cut(WIRE_BACKUP1) || wires.is_cut(WIRE_BACKUP2)))
		return TRUE


/obj/machinery/door/airlock/proc/regainMainPower()
	if(secondsMainPowerLost > 0)
		secondsMainPowerLost = 0
	update_icon()


/obj/machinery/door/airlock/proc/handlePowerRestore()
	var/cont = TRUE
	while(cont)
		sleep(1 SECONDS)
		if(QDELETED(src))
			return
		cont = FALSE
		if(secondsMainPowerLost > 0)
			if(!wires.is_cut(WIRE_POWER1) && !wires.is_cut(WIRE_POWER2))
				secondsMainPowerLost -= 1
				updateUsrDialog()
			cont = TRUE
		if(secondsBackupPowerLost > 0)
			if(!wires.is_cut(WIRE_BACKUP1) && !wires.is_cut(WIRE_BACKUP2))
				secondsBackupPowerLost -= 1
				updateUsrDialog()
			cont = TRUE
	spawnPowerRestoreRunning = FALSE
	updateUsrDialog()
	update_icon()


/obj/machinery/door/airlock/proc/loseMainPower()
	if(secondsMainPowerLost <= 0)
		secondsMainPowerLost = 60
		if(secondsBackupPowerLost < 10)
			secondsBackupPowerLost = 10
	if(!spawnPowerRestoreRunning)
		spawnPowerRestoreRunning = TRUE
	INVOKE_ASYNC(src, PROC_REF(handlePowerRestore))
	update_icon()


/obj/machinery/door/airlock/proc/loseBackupPower()
	if(secondsBackupPowerLost < 60)
		secondsBackupPowerLost = 60
	if(!spawnPowerRestoreRunning)
		spawnPowerRestoreRunning = TRUE
	INVOKE_ASYNC(src, PROC_REF(handlePowerRestore))
	update_icon()


/obj/machinery/door/airlock/proc/regainBackupPower()
	if(secondsBackupPowerLost > 0)
		secondsBackupPowerLost = 0
	update_icon()

// shock user with probability prb (if all connections & power are working)
// returns 1 if shocked, 0 otherwise
// The preceding comment was borrowed from the grille's shock script
/obj/machinery/door/airlock/shock(mob/user, prb)
	if(!hasPower())
		return 0
	if(hasShocked)
		return 0	//Already shocked someone recently?
	if(..())
		hasShocked = 1
		sleep(1 SECONDS)
		hasShocked = 0
		return 1
	else
		return 0


//Prying open doors
/obj/machinery/door/airlock/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, armor_type = MELEE, effects = TRUE, armor_penetration = xeno_attacker.xeno_caste.melee_ap, isrightclick = FALSE)
	if(xeno_attacker.status_flags & INCORPOREAL)
		return FALSE

	var/turf/cur_loc = xeno_attacker.loc
	if(isElectrified())
		if(shock(xeno_attacker, 70))
			return
	if(locked)
		to_chat(xeno_attacker, span_warning("\The [src] is bolted down tight."))
		return FALSE
	if(welded)
		to_chat(xeno_attacker, span_warning("\The [src] is welded shut."))
		return FALSE
	if(!istype(cur_loc))
		return FALSE //Some basic logic here
	if(!density)
		to_chat(xeno_attacker, span_warning("\The [src] is already open!"))
		return FALSE

	if(xeno_attacker.do_actions)
		return FALSE

	playsound(loc, 'sound/effects/metal_creaking.ogg', 25, 1)

	if(hasPower())
		xeno_attacker.visible_message(span_warning("\The [xeno_attacker] digs into \the [src] and begins to pry it open."), \
		span_warning("We dig into \the [src] and begin to pry it open."), null, 5)
		if(!do_after(xeno_attacker, 4 SECONDS, IGNORE_HELD_ITEM, src, BUSY_ICON_HOSTILE) && !xeno_attacker.lying_angle)
			return FALSE
	if(locked)
		to_chat(xeno_attacker, span_warning("\The [src] is bolted down tight."))
		return FALSE
	if(welded)
		to_chat(xeno_attacker, span_warning("\The [src] is welded shut."))
		return FALSE

	if(density) //Make sure it's still closed
		open(TRUE)
		xeno_attacker.visible_message(span_danger("\The [xeno_attacker] pries \the [src] open."), \
			span_danger("We pry \the [src] open."), null, 5)

/obj/machinery/door/airlock/attack_larva(mob/living/carbon/xenomorph/larva/M)
	for(var/atom/movable/AM in get_turf(src))
		if(AM != src && AM.density && !AM.CanPass(M, M.loc))
			to_chat(M, span_warning("\The [AM] prevents you from squeezing under \the [src]!"))
			return
	if(locked || welded) //Can't pass through airlocks that have been bolted down or welded
		to_chat(M, span_warning("\The [src] is locked down tight. You can't squeeze underneath!"))
		return
	M.visible_message(span_warning("\The [M] scuttles underneath \the [src]!"), \
	span_warning("You squeeze and scuttle underneath \the [src]."), null, 5)
	M.forceMove(loc)


/obj/machinery/door/airlock/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!issilicon(user) && isElectrified())
		shock(user, 100)

/obj/machinery/door/airlock/projectile_hit(obj/projectile/proj, cardinal_move, uncrossing)
	. = ..()
	if(. && is_mainship_level(z)) //log shipside greytiders
		log_attack("[key_name(proj.firer)] shot [src] with [proj] at [AREACOORD(src)]")
		if(SSmonitor.gamestate != SHIPSIDE)
			msg_admin_ff("[ADMIN_TPMONTY(proj.firer)] shot [src] with [proj] in [ADMIN_VERBOSEJMP(src)].")

/obj/machinery/door/airlock/attacked_by(obj/item/I, mob/living/user, def_zone)
	. = ..()
	if(. && is_mainship_level(z))
		log_attack("[src] has been hit with [I] at [AREACOORD(src)] by [key_name(user)]")
		if(SSmonitor.gamestate != SHIPSIDE)
			msg_admin_ff("[ADMIN_TPMONTY(user)] hit [src] with [I] in [ADMIN_VERBOSEJMP(src)].")

/obj/machinery/door/airlock/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(istype(I, /obj/item/clothing/mask/cigarette) && isElectrified())
		var/obj/item/clothing/mask/cigarette/L = I
		L.light("<span class='notice'>[user] lights their [L] on an electrical arc from the [src]")

	else if(!issilicon(user) && isElectrified())
		shock(user, 75)

	if(iswelder(I) && !operating && density)
		var/obj/item/tool/weldingtool/W = I

		if(not_weldable)
			to_chat(user, span_warning("\The [src] would require something a lot stronger than [W] to weld!"))
			return

		if(user.a_intent != INTENT_HELP)
			if(!W.tool_start_check(user, amount = 0))
				return

			user.visible_message(span_notice("[user] is [welded ? "unwelding":"welding"] the airlock."), \
							span_notice("You begin [welded ? "unwelding":"welding"] the airlock..."), \
							span_italics("You hear welding."))

			if(!W.use_tool(src, user, 40, volume = 50, extra_checks = CALLBACK(src, PROC_REF(weld_checks))))
				return

			welded = !welded
			user.visible_message("[user.name] has [welded? "welded shut":"unwelded"] [src].", \
								span_notice("You [welded ? "weld the airlock shut":"unweld the airlock"]."))
			update_icon()
		else
			if(obj_integrity >= max_integrity)
				to_chat(user, span_notice("The airlock doesn't need repairing."))
				return

			if(!W.tool_start_check(user, amount=0))
				return

			user.visible_message(span_notice("[user] is welding the airlock."), \
							span_notice("You begin repairing the airlock..."), \
							span_italics("You hear welding."))

			if(!W.use_tool(src, user, 40, volume = 50, extra_checks = CALLBACK(src, PROC_REF(weld_checks))))
				return

			repair_damage(max_integrity, user)
			DISABLE_BITFIELD(machine_stat, BROKEN)
			user.visible_message(span_notice("[user.name] has repaired [src]."), \
								span_notice("You finish repairing the airlock."))
			update_icon()

	else if(iswirecutter(I))
		return attack_hand(user)

	else if(ismultitool(I))
		return attack_hand(user)

	else if(istype(I, /obj/item/assembly/signaler))
		return attack_hand(user)

	else if(!I.pry_capable)
		return

	else if(I.pry_capable == IS_PRY_CAPABLE_CROWBAR && CHECK_BITFIELD(machine_stat, PANEL_OPEN) && (operating == -1 || (density && welded && operating != 1 && !hasPower() && !locked)))
		if(user.skills.getRating(SKILL_ENGINEER) < SKILL_ENGINEER_ENGI)
			user.visible_message(span_notice("[user] fumbles around figuring out how to deconstruct [src]."),
			span_notice("You fumble around figuring out how to deconstruct [src]."))

			var/fumbling_time = 50 * ( SKILL_ENGINEER_ENGI - user.skills.getRating(SKILL_ENGINEER) )
			if(!do_after(user, fumbling_time, NONE, src, BUSY_ICON_UNSKILLED))
				return

		if(multi_tile)
			to_chat(user, span_warning("Large doors seem impossible to disassemble."))
			return

		playsound(loc, 'sound/items/crowbar.ogg', 25, 1)
		user.visible_message("[user] starts removing the electronics from the airlock assembly.", "You start removing electronics from the airlock assembly.")

		if(!do_after(user, 40, NONE, src, BUSY_ICON_BUILD))
			return

		to_chat(user, span_notice("You removed the airlock electronics!"))

		var/obj/structure/door_assembly/DA = new assembly_type(loc)
		if(istype(DA, /obj/structure/door_assembly/multi_tile))
			DA.setDir(dir)
			DA.anchored = TRUE

		if(mineral)
			DA.glass = mineral

		else if(glass && !DA.glass)
			DA.glass = TRUE

		DA.state = 1
		DA.created_name = name
		DA.update_state()

		var/obj/item/circuitboard/airlock/AE
		if(!electronics)
			AE = new(loc)
			if(!req_access)
				check_access()
			if(length(req_access))
				AE.conf_access = req_access
			else if(length(req_one_access))
				AE.conf_access = req_one_access
				AE.one_access = TRUE

		if(operating == -1)
			AE.icon_state = "door_electronics_smoked"
			operating = FALSE
		qdel(src)

	else if(hasPower() && I.pry_capable != IS_PRY_CAPABLE_FORCE)
		to_chat(user, span_warning("The airlock's motors resist your efforts to force it."))

	else if(locked)
		to_chat(user, span_warning("The airlock's bolts prevent it from being forced."))

	else if(welded)
		to_chat(user, span_warning("The airlock is welded shut."))

	else if(I.pry_capable == IS_PRY_CAPABLE_FORCE)
		return FALSE //handled by the item's afterattack

	else if(!operating)
		if(density)
			open(1)
		else
			close(1)

	return TRUE

/obj/machinery/door/airlock/screwdriver_act(mob/user, obj/item/I)
	. = ..()
	if(no_panel)
		to_chat(user, span_warning("\The [src] has no panel to open!"))
		return

	machine_stat ^= PANEL_OPEN
	if(machine_stat & PANEL_OPEN)
		to_chat(user, span_notice("You open [src]'s panel."))
		playsound(loc, 'sound/items/screwdriver2.ogg', 25, 1)
	else
		to_chat(user, span_notice("You close [src]'s panel."))
		playsound(loc, 'sound/items/screwdriver.ogg', 25, 1)
	update_icon()

/obj/machinery/door/airlock/proc/lock(forced = FALSE)
	if ((operating && !forced) || locked)
		return

	locked = TRUE
	audible_message("You hear a click from the bottom of the door.", null, 1)
	update_icon()

/obj/machinery/door/airlock/proc/unlock(forced = FALSE)
	if ((operating && !forced) || !locked)
		return

	if(forced || hasPower()) //only can raise bolts if power's on
		locked = FALSE
		audible_message("You hear a click from the bottom of the door.", null, 1)
		update_icon()
		return TRUE
	return FALSE


/obj/machinery/door/airlock/Destroy()
	QUEUE_SMOOTH_NEIGHBORS(loc)
	QDEL_NULL(wires)
	return ..()


/obj/machinery/door/airlock/proc/prison_open()
	unlock()
	open()
	lock()



/obj/machinery/door/airlock/proc/update_nearby_icons()
	QUEUE_SMOOTH_NEIGHBORS(src)


/obj/machinery/door/airlock/proc/set_electrified(seconds, mob/user)
	secondsElectrified = seconds
	if(secondsElectrified > MACHINE_NOT_ELECTRIFIED)
		INVOKE_ASYNC(src, PROC_REF(electrified_loop))

	if(user)
		var/message
		switch(secondsElectrified)
			if(MACHINE_ELECTRIFIED_PERMANENT)
				message = "permanently shocked"
			if(MACHINE_NOT_ELECTRIFIED)
				message = "unshocked"
			else
				message = "temp shocked for [secondsElectrified] seconds"
		LAZYADD(shockedby, "\[[time_stamp()]\] [key_name(user)] - ([uppertext(message)])")
		log_combat(user, src, message)


/obj/machinery/door/airlock/proc/electrified_loop()
	while(secondsElectrified > MACHINE_NOT_ELECTRIFIED)
		sleep(1 SECONDS)
		if(QDELETED(src))
			return

		secondsElectrified--
		updateUsrDialog()
	// This is to protect against changing to permanent, mid loop.
	if(secondsElectrified == MACHINE_NOT_ELECTRIFIED)
		set_electrified(MACHINE_NOT_ELECTRIFIED)
	else
		set_electrified(MACHINE_ELECTRIFIED_PERMANENT)
	updateUsrDialog()


/obj/machinery/door/airlock/proc/user_toggle_open(mob/user)
	if(!canAIControl(user))
		return

	if(welded)
		to_chat(user, span_warning("The airlock has been welded shut."))
		return

	if(locked)
		to_chat(user, span_warning("The door bolts are down."))
		return

	if(!density)
		close()
	else
		open()


/obj/machinery/door/airlock/proc/shock_restore(mob/user)
	if(!canAIControl(user))
		return

	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("The electrification wire is cut."))
		return

	if(isElectrified())
		set_electrified(MACHINE_NOT_ELECTRIFIED, user)


/obj/machinery/door/airlock/proc/shock_temp(mob/user)
	if(!canAIControl(user))
		return

	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("The electrification wire is cut."))
		return

	set_electrified(MACHINE_DEFAULT_ELECTRIFY_TIME, user)


/obj/machinery/door/airlock/proc/shock_perm(mob/user)
	if(!canAIControl(user))
		return

	if(wires.is_cut(WIRE_SHOCK))
		to_chat(user, span_warning("The electrification wire is cut."))
		return

	set_electrified(MACHINE_ELECTRIFIED_PERMANENT, user)


/obj/machinery/door/airlock/proc/emergency_on(mob/user)
	if(!canAIControl(user))
		return

	if(emergency)
		to_chat(user, span_warning("Emergency access is already enabled."))
		return

	emergency = TRUE
	update_icon()



/obj/machinery/door/airlock/proc/emergency_off(mob/user)
	if(!canAIControl(user))
		return

	if(!emergency)
		to_chat(user, span_warning("Emergency access is already disabled."))
		return

	emergency = FALSE
	update_icon()


/obj/machinery/door/airlock/proc/bolt_raise(mob/user)
	if(!canAIControl(user))
		return

	if(wires.is_cut(WIRE_BOLTS))
		to_chat(user, span_warning("The door bolt wire is cut."))
		return

	if(!locked)
		to_chat(user, span_warning("The door bolts are already up."))
		return

	if(!hasPower())
		to_chat(user, span_warning("Cannot raise door bolts due to power failure."))
		return

	unbolt()



/obj/machinery/door/airlock/proc/bolt_drop(mob/user)
	if(!canAIControl(user))
		return

	if(wires.is_cut(WIRE_BOLTS))
		to_chat(user, span_warning("The door bolt wire is cut."))
		return

	bolt()


/obj/machinery/door/airlock/proc/bolt()
	if(locked)
		return

	locked = TRUE
	playsound(src, 'sound/machines/boltsdown.ogg', 30, 0, 3)
	audible_message(span_notice("You hear a click from the bottom of the door."), null,  1)
	update_icon()


/obj/machinery/door/airlock/proc/unbolt()
	if(!locked)
		return

	locked = FALSE
	playsound(src, 'sound/machines/boltsup.ogg', 30, 0, 3)
	audible_message(span_notice("You hear a click from the bottom of the door."), null,  1)
	update_icon()


/obj/machinery/door/airlock/proc/weld_checks()
	return !operating && density
