/obj/effect/elevator
	name = "\improper empty space"
	desc = "There seems to be an awful lot of machinery down below"
	icon = 'icons/effects/160x160.dmi'
	icon_state = "supply_elevator_lowered"
	resistance_flags = RESIST_ALL
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = LOWER_FLOOR_LAYER
	plane = FLOOR_PLANE
	appearance_flags = KEEP_TOGETHER
	pixel_w = -64
	pixel_z = -64
	///Used to mirrors the turfs (and their contents) on the elevator when raising/lowering, so they don't instantly teleport or vanish.
	var/obj/effect/elevator/animation_overlay/elevator_animation

/obj/effect/elevator/Initialize(mapload)
	. = ..()
	elevator_animation = new()
	vis_contents += elevator_animation

/obj/effect/elevator/Destroy(force)
	if(!force)
		return QDEL_HINT_LETMELIVE
	return ..()

// Don't move with the elevator.
/obj/effect/elevator/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	return
/obj/effect/elevator/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	return
/obj/effect/elevator/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	return

/obj/effect/elevator/proc/shuttle_arriving()
	icon_state = "supply_elevator_raised"
	flick("supply_elevator_raising", src)

/obj/effect/elevator/proc/shuttle_departing()
	icon_state = "supply_elevator_lowered"
	flick("supply_elevator_lowering", src)

/obj/effect/elevator/animation_overlay
	blend_mode = BLEND_INSET_OVERLAY
	appearance_flags = KEEP_TOGETHER

/obj/effect/elevator/vehicle
	icon_state = "vehicle_elevator_lowered"
