/obj/machinery/door
	name = "\improper Door"
	desc = "It opens and closes."
	icon = 'icons/obj/doors/Doorint.dmi'
	icon_state = "door1"
	anchored = TRUE
	opacity = TRUE
	density = TRUE
	allow_pass_flags = NONE
	move_resist = MOVE_FORCE_VERY_STRONG
	layer = DOOR_OPEN_LAYER
	explosion_block = 2
	resistance_flags = DROPSHIP_IMMUNE
	minimap_color = MINIMAP_DOOR
	soft_armor = list(MELEE = 30, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 10, BIO = 100, FIRE = 80, ACID = 70)
	var/open_layer = DOOR_OPEN_LAYER
	var/closed_layer = DOOR_CLOSED_LAYER
	var/id
	var/secondsElectrified = 0
	var/visible = TRUE
	var/operating = FALSE
	var/autoclose = FALSE
	var/glass = FALSE
	/// Unrestricted sides. A bitflag for which direction (if any) can open the door with no access
	var/unres_sides = NONE
	var/normalspeed = TRUE
	var/locked = FALSE
	var/welded = FALSE
	var/not_weldable = FALSE // stops people welding the door if true
	var/openspeed = 10 //How many seconds does it take to open it? Default 1 second. Use only if you have long door opening animations
	var/list/fillers
	///used for determining emergency access
	var/emergency = FALSE
	///bool for determining linked state
	var/cyclelinkeddir = FALSE
	///what airlock we are linked with
	var/obj/machinery/door/airlock/cycle_linked_airlock

	/// Do we need to keep track of a filler panel with the airlock
	var/multi_tile
	/// A filler object used to fill the space of multi-tile airlocks
	var/obj/structure/fluff/airlock_filler/filler

	//Multi-tile doors
	dir = EAST

/obj/machinery/door/Initialize(mapload)
	. = ..()
	if(multi_tile)
		set_bounds()
		set_filler()
		update_overlays()
	if(density)
		layer = closed_layer
		update_heat_protection_flags(get_turf(src))
	else
		layer = open_layer

	var/turf/current_turf = get_turf(src)
	current_turf.atom_flags &= ~ AI_BLOCKED

	if(glass)
		allow_pass_flags |= PASS_GLASS

/obj/machinery/door/Destroy()
	for(var/o in fillers)
		qdel(o)
	return ..()

/obj/machinery/door/Move()
	if(multi_tile)
		set_filler()
	return ..()

/**
 * Sets the bounds of the airlock. For use with multi-tile airlocks.
 * If the airlock is multi-tile, it will set the bounds to be the size of the airlock.
 * If the airlock doesn't already have a filler object, it will create one.
 * If the airlock already has a filler object, it will move it to the correct location.
 */
/obj/machinery/door/proc/set_filler()
	if(!multi_tile)
		return
	if(!filler)
		filler = new(get_step(src, get_adjusted_dir(dir)))
		filler.pair_airlock(src)
	else
		filler.loc = get_step(src, get_adjusted_dir(dir))

	filler.density = density
	filler.set_opacity(opacity)

/**
 * Checks which way the airlock is facing and adjusts the direction accordingly.
 * For use with multi-tile airlocks.
 *
 * @param dir direction to adjust
 * @return adjusted direction
 */
/obj/machinery/door/proc/get_adjusted_dir(dir)
	if(dir in list(NORTH, SOUTH))
		return EAST
	else
		return NORTH

/obj/machinery/door/Bumped(atom/AM)
	if(CHECK_BITFIELD(machine_stat, PANEL_OPEN) || operating)
		return

	if(ismob(AM))
		var/mob/M = AM
		if(TIMER_COOLDOWN_CHECK(M, COOLDOWN_BUMP))
			return	//This is to prevent shock spam.
		TIMER_COOLDOWN_START(M, COOLDOWN_BUMP, openspeed)
		if(!M.restrained() && M.mob_size > MOB_SIZE_SMALL)
			bumpopen(M)
		return

	if(isuav(AM))
		try_to_activate_door(AM)
		return

	if(isobj(AM))
		var/obj/O = AM
		for(var/m in O.buckled_mobs)
			Bumped(m)

/obj/machinery/door/proc/bumpopen(mob/user as mob)
	if(operating)
		return

	if(!src.requiresID())
		user = null

	if(density)
		if(allowed(user) || emergency || unrestricted_side(user))
			if(cycle_linked_airlock)
				if(!emergency && !cycle_linked_airlock.emergency && allowed(user))
					cycle_linked_airlock.close()
			open()
		else
			flick("door_deny", src)

///Allows for specific sides of airlocks to be unrestricted (IE, can exit maint freely, but need access to enter)
/obj/machinery/door/proc/unrestricted_side(mob/opener)
	return get_dir(src, opener) & unres_sides

/obj/machinery/door/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	return try_to_activate_door(user)

/obj/machinery/door/proc/try_to_activate_door(atom/user)
	if(operating)
		return
	var/can_open = !Adjacent(user) || !requiresID() || ismob(user) && allowed(user)
	if(!Adjacent(user))
		can_open = TRUE
	if(!requiresID())
		can_open = TRUE
	if(ismob(user) && allowed(user))
		can_open = TRUE
	if(isuav(user))
		can_open = TRUE
	if(can_open)
		if(density)
			open()
		else
			close()
	else if(density)
		flick("door_deny", src)


/obj/machinery/door/emp_act(severity)
	. = ..()
	if(prob(30/severity) && (istype(src,/obj/machinery/door/airlock) || istype(src,/obj/machinery/door/window)) )
		open()
	if(prob(60/severity))
		if(secondsElectrified == 0)
			secondsElectrified = -1
			spawn(300)
				secondsElectrified = 0

/obj/machinery/door/ex_act(severity)
	if(CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE))
		return
	switch(severity)
		if(EXPLODE_DEVASTATE)
			qdel(src)
		if(EXPLODE_HEAVY)
			if(prob(25))
				qdel(src)
		if(EXPLODE_LIGHT)
			if(prob(80))
				var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
				s.set_up(2, 1, src)
				s.start()

/obj/machinery/door/set_density(new_value)
	. = ..()
	if(new_value)
		explosion_block = initial(explosion_block)
	else
		explosion_block = 0

/obj/machinery/door/update_icon_state()
	. = ..()
	if(density)
		icon_state = "door1"
	else
		icon_state = "door0"

/obj/machinery/door/proc/do_animate(animation)
	switch(animation)
		if("opening")
			if(CHECK_BITFIELD(machine_stat, PANEL_OPEN))
				flick("o_doorc0", src)
			else
				flick("doorc0", src)
		if("closing")
			if(CHECK_BITFIELD(machine_stat, PANEL_OPEN))
				flick("o_doorc1", src)
			else
				flick("doorc1", src)
		if("deny")
			flick("door_deny", src)


/obj/machinery/door/proc/open()
	SIGNAL_HANDLER_DOES_SLEEP
	if(operating || welded || locked || !loc)
		return FALSE
	operating = TRUE
	do_animate("opening")
	icon_state = "door0"
	set_opacity(FALSE)
	for(var/t in fillers)
		var/obj/effect/opacifier/O = t
		O.set_opacity(FALSE)
	addtimer(CALLBACK(src, PROC_REF(finish_open)), openspeed)
	return TRUE

/obj/machinery/door/proc/finish_open()
	layer = open_layer
	density = FALSE
	update_icon()

	if(operating)
		operating = FALSE

	if(autoclose)
		addtimer(CALLBACK(src, PROC_REF(autoclose)), normalspeed ? 150 + openspeed : 5)

/obj/machinery/door/proc/close()
	SIGNAL_HANDLER_DOES_SLEEP
	if(density)
		return TRUE
	if(operating)
		return FALSE
	operating = TRUE

	density = TRUE
	layer = closed_layer
	do_animate("closing")
	addtimer(CALLBACK(src, PROC_REF(finish_close)), openspeed)

/obj/machinery/door/proc/finish_close()
	update_icon()
	if(visible && !glass)
		set_opacity(TRUE)	//caaaaarn!
		for(var/t in fillers)
			var/obj/effect/opacifier/O = t
			O.set_opacity(TRUE)
	operating = FALSE

///Checks for mobs and prevents closing if found
/obj/machinery/door/proc/CheckForMobs()
	for(var/turf/checked_turf in locs)
		if(locate(/mob/living) in checked_turf)
			sleep(0.1 SECONDS)
			open()

///Crush anything in the door
/obj/machinery/door/proc/crush()
	for(var/turf/checked_turf in locs)
		for(var/mob/living/crushed_mob in checked_turf)
			crushed_mob.visible_message(span_warning("[src] closes on [crushed_mob], crushing [crushed_mob.p_them()]!"), span_userdanger("[src] closes on you and crushes you!"))
			crushed_mob.apply_damage(DOOR_CRUSH_DAMAGE, BRUTE, blocked = MELEE, updating_health = TRUE)
			crushed_mob.Paralyze(10 SECONDS)
			if(iscarbon(crushed_mob))
				var/mob/living/carbon/carbon_mob = crushed_mob
				var/datum/species/carbon_species = carbon_mob.species
				if(carbon_species?.species_flags & NO_PAIN)
					INVOKE_ASYNC(crushed_mob, TYPE_PROC_REF(/mob/living, emote), "pain")
				checked_turf.add_mob_blood(crushed_mob)

/obj/machinery/door/proc/requiresID()
	return TRUE

/obj/machinery/door/proc/hasPower()
	return !CHECK_BITFIELD(machine_stat, NOPOWER)

/obj/machinery/door/proc/update_heat_protection_flags(turf/source)

/obj/machinery/door/proc/autoclose()
	if(!QDELETED(src) && !density && !operating && !locked && !welded && autoclose)
		close()

/// Private proc that runs a series of checks to see if we should forcibly open the door. Returns TRUE if we should open the door, FALSE otherwise. Implemented in child types.
/// In case a specific behavior isn't covered, we should default to TRUE just to be safe (simply put, this proc should have an explicit reason to return FALSE).
/obj/machinery/door/proc/try_to_force_door_open(force_type = DEFAULT_DOOR_CHECKS)
	return TRUE // the base "door" can always be forced open since there's no power or anything like emagging it to prevent an open, not even invoked on the base type anyways.

/// Private proc that runs a series of checks to see if we should forcibly shut the door. Returns TRUE if we should shut the door, FALSE otherwise. Implemented in child types.
/// In case a specific behavior isn't covered, we should default to TRUE just to be safe (simply put, this proc should have an explicit reason to return FALSE).
/obj/machinery/door/proc/try_to_force_door_shut(force_type = DEFAULT_DOOR_CHECKS)
	return TRUE // the base "door" can always be forced shut

/obj/machinery/door/proc/autoclose_in(wait)
	addtimer(CALLBACK(src, PROC_REF(autoclose)), wait, TIMER_UNIQUE | TIMER_NO_HASH_WAIT | TIMER_OVERRIDE)

//multitile filler
/obj/structure/fluff/airlock_filler
	name = "airlock fluff"
	desc = "You shouldn't be able to see this fluff!"
	icon = null
	icon_state = null
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_MAXIMUM
	/// The door/airlock this fluff panel is attached to
	var/obj/machinery/door/filled_airlock


///Create a ref to our parent airlock so we qdel when it does
/obj/structure/fluff/airlock_filler/proc/pair_airlock(obj/machinery/door/parent_airlock)
	if(isnull(parent_airlock))
		stack_trace("Attempted to pair an airlock filler with no parent airlock specified!")
		return

	filled_airlock = parent_airlock
	RegisterSignal(filled_airlock, COMSIG_QDELETING, PROC_REF(no_airlock))

///Multi-tile airlocks pair with a filler panel, if one goes so does the other.
/obj/structure/fluff/airlock_filler/proc/no_airlock()
	SIGNAL_HANDLER
	qdel(src)

/obj/machinery/door/morgue
	icon = 'icons/obj/doors/doormorgue.dmi'
