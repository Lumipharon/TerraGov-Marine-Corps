//wallening style walls. Eventually replace all walls with this type, then just fold this into base wall/closed turf behavior.
/turf/closed/wall/tall
	icon_state = "wall-0"
	walltype = "wall"
	base_icon_state = "wall"
	icon = 'icons/turf/walls/metal.dmi'
	///Top section of the wall sprite
	var/icon/frill_icon = 'icons/turf/walls/metal_frill.dmi'

/turf/closed/wall/tall/Initialize(mapload)
	. = ..()
	if(frill_icon)
		AddElement(/datum/element/frill, frill_icon)

//Framed windows

/obj/structure/window/framed/tall
	name = "reinforced window"
	desc = "A glass window with a special rod matrice inside a wall frame. It looks rather strong. Might take a few good hits to shatter it."
	icon = 'icons/obj/smooth_objects/tall_windows/normal_window.dmi' //these are named improperly for tgmc
	icon_state = "window-reinforced"
	basestate = "ship_window"
	base_icon_state = "ship_window"
	max_integrity = 100 //Was 600
	reinf = TRUE
	dir = 5
	window_frame = /obj/structure/window_frame/mainship
	///Top section of the wall sprite
	var/icon/frill_icon = 'icons/obj/smooth_objects/tall_windows/window_normal_frill.dmi'

/obj/structure/window/framed/tall/Initialize(mapload)
	. = ..()
	if(frill_icon)
		AddElement(/datum/element/frill, frill_icon)

//airlock test
/obj/machinery/door/airlock/tall
	name = "airlock"
	icon = 'icons/obj/doors/airlocks/tall/security.dmi'
	icon_state = "closed"

///frill element

GLOBAL_LIST_EMPTY(frill_objects)


/proc/get_frill_object(icon_path, junction, alpha = 255, pixel_x = 0, pixel_y = 0, plane = FRILL_PLANE)
	. = GLOB.frill_objects["[icon_path]-[junction]-[alpha]-[pixel_x]-[pixel_y]-[plane]"]
	if(.)
		return
	var/mutable_appearance/mut_appearance = mutable_appearance(icon_path, "frill-[junction]", ABOVE_MOB_LAYER, plane, alpha)
	mut_appearance.pixel_x = pixel_x
	mut_appearance.pixel_y = pixel_y
	return GLOB.frill_objects["[icon_path]-[junction]-[alpha]-[pixel_x]-[pixel_y]-[plane]"] = mut_appearance

/**
  * Attached to smoothing atoms. Adds a globally-cached object to their vis_contents and updates based on junction changes.
  ** ATTENTION: This element was supposed to be for atoms, but since only movables and turfs actually have vis_contents hacks have to be done.
  ** For now it treats all of its targets as turfs, but that will runtime if an invalid variable access happens.
  ** Yes, this is ugly. The alternative is making two different elements for the same purpose.
  */
/datum/element/frill
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2
	var/icon_path


/datum/element/frill/Attach(datum/target, icon_path)
	if(!isturf(target) && !ismovable(target)) // Turfs and movables have vis_contents. Atoms don't. Pain.
		return ELEMENT_INCOMPATIBLE
	. = ..()
	src.icon_path = icon_path

	var/atom/atom_target = target

	on_junction_change(atom_target, atom_target.smoothing_junction)
	RegisterSignal(target, COMSIG_ATOM_SET_SMOOTHED_ICON_STATE, .proc/on_junction_change)

/datum/element/frill/Detach(turf/target)

	target.cut_overlay(get_frill_object(icon_path, target.smoothing_junction, pixel_y = 32))
	target.cut_overlay(get_frill_object(icon_path, target.smoothing_junction, plane = WALL_PLANE, pixel_y = 32))
	UnregisterSignal(target, COMSIG_ATOM_SET_SMOOTHED_ICON_STATE)
	return ..()


/datum/element/frill/proc/on_junction_change(atom/source, new_junction)
	SIGNAL_HANDLER
	var/turf/turf_or_movable = source
	if(!(source.smoothing_junction & NORTH))
		turf_or_movable.cut_overlay(get_frill_object(icon_path, source.smoothing_junction, pixel_y = 32))
	else
		turf_or_movable.cut_overlay(get_frill_object(icon_path, source.smoothing_junction, plane = WALL_PLANE, pixel_y = 32))

	if(!(new_junction & NORTH))
		turf_or_movable.add_overlay(get_frill_object(icon_path, new_junction, pixel_y = 32))
	else
		turf_or_movable.add_overlay(get_frill_object(icon_path, new_junction, plane = WALL_PLANE, pixel_y = 32))
