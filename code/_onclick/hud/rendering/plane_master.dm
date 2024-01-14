/atom/movable/screen/plane_master
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	plane = LOWEST_EVER_PLANE
	var/show_alpha = 255
	var/hide_alpha = 0

	//--rendering relay vars--
	///integer: what plane we will relay this planes render to
	var/render_relay_plane = RENDER_PLANE_GAME
	///bool: Whether this plane should get a render target automatically generated
	var/generate_render_target = TRUE
	///integer: blend mode to apply to the render relay in case you dont want to use the plane_masters blend_mode
	var/blend_mode_override
	///reference to render relay screen object to avoid backdropping multiple times
	var/atom/movable/render_plane_relay/relay

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob)
	SHOULD_CALL_PARENT(TRUE)
	if(!isnull(render_relay_plane))
		relay_render_to_plane(mymob, render_relay_plane)

///Things rendered on "openspace"; holes in multi-z
/atom/movable/screen/plane_master/openspace_backdrop
	name = "open space backdrop plane master"
	plane = OPENSPACE_BACKDROP_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
	alpha = 255
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/openspace
	name = "open space plane master"
	plane = OPENSPACE_PLANE
	appearance_flags = PLANE_MASTER
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/openspace/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("first_stage_openspace", 1, drop_shadow_filter(color = "#04080FAA", size = -10))
	add_filter("second_stage_openspace", 2, drop_shadow_filter(color = "#04080FAA", size = -15))
	add_filter("third_stage_openspace", 3, drop_shadow_filter(color = "#04080FAA", size = -20))

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/floor/backdrop(mob/living/mymob)
	. = ..()
	clear_filters()
	if(!istype(mymob) || !mymob.eye_blurry || SEND_SIGNAL(mymob, COMSIG_LIVING_UPDATE_PLANE_BLUR) & COMPONENT_CANCEL_BLUR)
		return
	add_filter("eye_blur", 1, gauss_blur_filter(clamp(mymob.eye_blurry * 0.1, 0.6, 3)))

/atom/movable/screen/plane_master/wall
	name = "wall plane master"
	plane = WALL_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

///Floors inverse-masking frills.
#define FRILL_FLOOR_CUT "frill floor cut"
///Game plane inverse-masking frills.
#define FRILL_GAME_CUT "frill game cut"

#define FRILL_MOB_MASK "frill mob mask"

/atom/movable/screen/plane_master/frill_mask
	name = "frill mask plane master"
	plane = FRILL_MASK_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_target = FRILL_MASK_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/frill_under
	name = "frill under plane master"
	plane = UNDER_FRILL_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/frill_under/backdrop(mob/mymob)
	. = ..()
	if(!mymob)
		CRASH("Plane master backdrop called without a mob attached.")
	remove_filter(FRILL_MOB_MASK)
	add_filter(FRILL_MOB_MASK, 1, alpha_mask_filter(render_source = FRILL_MASK_RENDER_TARGET, flags = MASK_INVERSE))

/atom/movable/screen/plane_master/frill
	name = "frill plane master"
	plane = FRILL_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/frill_over
	name = "frill under plane master"
	plane = OVER_FRILL_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/frill/backdrop(mob/mymob)
	. = ..()
	if(!mymob)
		CRASH("Plane master backdrop called without a mob attached.")
	remove_filter(FRILL_FLOOR_CUT)
	remove_filter(FRILL_GAME_CUT)
	remove_filter(FRILL_MOB_MASK)
	if(!mymob.client?.prefs)
		return
	//add_filter(FRILL_GAME_CUT, 1, alpha_mask_filter(render_source = EMISSIVE_BLOCKER_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter(FRILL_MOB_MASK, 1, alpha_mask_filter(render_source = FRILL_MASK_RENDER_TARGET, flags = MASK_INVERSE))

/datum/keybinding/client/toggle_frills_over_floors
	hotkey_keys = list("`")
	name = "toggle_frills_over_floors"
	full_name = "Toggle Frills over Floors"
	description = "Toggles the Frill-over-Floors preference"
	keybind_signal = COMSIG_KB_CLIENT_MINIMALHUD_DOWN

/datum/keybinding/client/toggle_frills_over_floors/down(client/user)
	. = ..()
	if(. || !user.prefs)
		return
	if(length(user?.screen))
		var/atom/movable/screen/plane_master/frill/frill = locate(/atom/movable/screen/plane_master/frill) in user.screen
		frill.backdrop(user.mob)
	return TRUE

///Contains most things in the game world
/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/game_world/backdrop(mob/living/mymob)
	. = ..()
	clear_filters()
	add_filter("AO", 1, drop_shadow_filter(x = 0, y = -2, size = 4, color = "#04080FAA"))
	if(!istype(mymob) || !mymob.eye_blurry || SEND_SIGNAL(mymob, COMSIG_LIVING_UPDATE_PLANE_BLUR) & COMPONENT_CANCEL_BLUR)
		return
	add_filter("eye_blur", 1, gauss_blur_filter(clamp(mymob.eye_blurry * 0.1, 0.6, 3)))

/**
 * Plane master handling byond internal blackness
 * vars are set as to replicate behavior when rendering to other planes
 * do not touch this unless you know what you are doing
 */
/atom/movable/screen/plane_master/blackness
	name = "darkness plane master"
	plane = BLACKNESS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR | PIXEL_SCALE
	//byond internal end
	render_relay_plane = RENDER_PLANE_GAME


/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */

///Contains all lighting objects
/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	blend_mode_override = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	. = ..()
	mymob.overlay_fullscreen("lighting_backdrop", /atom/movable/screen/fullscreen/lighting_backdrop/backplane)
	mymob.overlay_fullscreen("lighting_backdrop_lit_secondary", /atom/movable/screen/fullscreen/lighting_backdrop/lit_secondary)

/atom/movable/screen/plane_master/lighting/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("emissives", 1, alpha_mask_filter(render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("object_lighting", 2, alpha_mask_filter(render_source = O_LIGHTING_VISUAL_RENDER_TARGET, flags = MASK_INVERSE))

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "emissive plane master"
	plane = EMISSIVE_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = EMISSIVE_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/emissive/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("em_block_masking", 1, color_matrix_filter(GLOB.em_mask_matrix))

/atom/movable/screen/plane_master/above_lighting
	name = "above lighting plane master"
	plane = ABOVE_LIGHTING_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/parallax_white
	name = "parallax whitifier plane master"
	plane = PLANE_SPACE

/atom/movable/screen/plane_master/camera_static
	name = "camera static plane master"
	plane = CAMERA_STATIC_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/o_light_visual
	name = "overlight light visual plane master"
	plane = O_LIGHTING_VISUAL_PLANE
	render_target = O_LIGHTING_VISUAL_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	blend_mode_override = BLEND_MULTIPLY

/atom/movable/screen/plane_master/fullscreen
	name = "fullscreen alert plane"
	plane = FULLSCREEN_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	render_target = GRAVITY_PULSE_RENDER_TARGET
	blend_mode = BLEND_ADD
	blend_mode_override = BLEND_ADD
	render_relay_plane = null

/atom/movable/screen/plane_master/balloon_chat
	name = "balloon alert plane"
	plane = BALLOON_CHAT_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME
