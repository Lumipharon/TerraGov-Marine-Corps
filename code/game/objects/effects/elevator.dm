/obj/effect/elevator
	name = "\improper empty space"
	desc = "There seems to be an awful lot of machinery down below"
	icon = 'icons/effects/160x160.dmi'
	icon_state = "supply_elevator_raised"
	resistance_flags = RESIST_ALL
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = LOWER_RUNE_LAYER
	plane = FLOOR_PLANE
	appearance_flags = KEEP_TOGETHER
	pixel_w = -64
	pixel_z = -64

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

/obj/effect/elevator_animation_overlay //cm has this as a child of the main visual for some reason??
	blend_mode = BLEND_INSET_OVERLAY
	appearance_flags = KEEP_TOGETHER
	icon = 'icons/effects/160x160.dmi'
	icon_state = ""
	resistance_flags = RESIST_ALL
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = LOWER_FLOOR_LAYER
	plane = FLOOR_PLANE
	pixel_x = 160 //Matches the slope on the sprite.
	pixel_y = -80
