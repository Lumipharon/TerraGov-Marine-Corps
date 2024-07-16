///Deployitem implant, holds a item that can then be placed inhand to do whatever with
/obj/item/implant/deployitem
	name = "item implants"
	desc = "you shouldnt be seeing this"
	allowed_limbs = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	///Held item we want to be put in hand when the implant is activated
	var/obj/item/helditem = /obj/item/healthanalyzer

/obj/item/implant/deployitem/Initialize(mapload)
	. = ..()
	helditem = new helditem(src)

/obj/item/implant/deployitem/activate()
	. = ..()
	if(!.)
		return
	if(malfunction == MALFUNCTION_PERMANENT)
		return FALSE
	if(helditem.loc != src)
		fetch_item()
		return
	put_in_slots()
	RegisterSignal(helditem, COMSIG_ITEM_DROPPED, PROC_REF(fetch_item))

///Takes the held item and puts it into it's predestined slot
/obj/item/implant/deployitem/proc/put_in_slots()
	switch(part.name)
		if(BODY_ZONE_R_ARM)
			implant_owner.put_in_r_hand(helditem)
		if(BODY_ZONE_L_ARM)
			implant_owner.put_in_l_hand(helditem)

///grabs the held item when it changes equip or is dropped
/obj/item/implant/deployitem/proc/fetch_item()
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	UnregisterSignal(helditem, COMSIG_ITEM_DROPPED)
	implant_owner.temporarilyRemoveItemFromInventory(helditem)
	helditem.forceMove(src)


/obj/item/implant/deployitem/blade
	name = "mantis blade implant"
	desc = "A large folding blade capable of being stored within an arm."
	icon = 'icons/obj/items/weapons/swords.dmi'
	icon_state = "armblade"
	helditem = /obj/item/weapon/sword/mantis_blade
	action_type = /datum/action/item_action/implant/mantis_blade

/obj/item/implant/deployitem/blade/get_data()
	return {"
	<b>Implant Specifications:</b><BR>
	<b>Name:</b> Nanotrasen MA-12 Mantis Implant<BR>
	<HR>
	<b>Implant Details:</b><BR>
	<b>Function:</b> Upon activation, the user deploys a large blade from the their arm.<BR>"}

/obj/item/implant/deployitem/blade/put_in_slots()
	. = ..()
	playsound(implant_owner.loc, 'sound/weapons/wristblades_on.ogg', 15, TRUE)

/obj/item/implant/deployitem/blade/fetch_item()
	. = ..()
	playsound(implant_owner.loc, 'sound/weapons/wristblades_off.ogg', 15, TRUE)

/datum/action/item_action/implant/mantis_blade
	desc = "Toggles your implanted mantis blade"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_IMPLANT_ABILITY_MANTIS_BLADE,
	)

/obj/item/weapon/sword/mantis_blade
	name = "mantis arm blade"
	desc = "A wicked-looking folding blade capable of being concealed within a human's arm."
	icon_state = "armblade"
	worn_icon_state = "armblade"
	force = 75
	attack_speed = 8
	equip_slot_flags = NONE
	w_class = WEIGHT_CLASS_BULKY
	hitsound = 'sound/weapons/slash.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

/obj/item/implant/deployitem/wrist_cannon
	name = "projectile launch system"
	desc = "A compact missile weapon systen capable of being stored within a cybernetic arm."
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "wrist_cannon"
	helditem = /obj/item/weapon/gun/launcher/wrist_cannon
	action_type = /datum/action/item_action/implant/wrist_cannon

/obj/item/implant/deployitem/wrist_cannon/get_data()
	return {"
	<b>Implant Specifications:</b><BR>
	<b>Name:</b> Nanotrasen MA-12 Mantis Implant<BR>
	<HR>
	<b>Implant Details:</b><BR>
	<b>Function:</b> Upon activation, the user deploys a gun from the their arm.<BR>"}

/obj/item/implant/deployitem/wrist_cannon/put_in_slots()
	. = ..()
	playsound(implant_owner.loc, 'sound/weapons/guns/interact/pred_plasmacaster_on.ogg', 15, TRUE)

/obj/item/implant/deployitem/wrist_cannon/fetch_item()
	. = ..()
	playsound(implant_owner.loc, 'sound/weapons/guns/interact/pred_plasmacaster_off.ogg', 15, TRUE)

/datum/action/item_action/implant/wrist_cannon
	desc = "Toggles your implanted PLS"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_IMPLANT_ABILITY_WRIST_CANNON,
	)

//rocket
/obj/item/weapon/gun/launcher/wrist_cannon
	name = "\improper RL-5 rocket launcher"
	desc = "The RL-5 is the primary anti-armor used around the galaxy. Used to take out light-tanks and enemy structures, the RL-5 rocket launcher is a dangerous weapon with a variety of combat uses. Uses a variety of 84mm rockets."
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "wrist_cannon"
	item_state = null
	max_shells = 5
	caliber = CALIBER_84MM
	load_method = MAGAZINE
	default_ammo_type = /obj/item/ammo_magazine/wrist_cannon
	allowed_ammo_types = list(/obj/item/ammo_magazine/wrist_cannon)
	w_class = WEIGHT_CLASS_HUGE
	force = 15
	wield_delay = 0.5 SECONDS
	aim_slowdown = 0.3
	general_codex_key = "explosive weapons"
	gun_features_flags = GUN_AMMO_COUNTER|GUN_SMOKE_PARTICLES
	reciever_flags = AMMO_RECIEVER_MAGAZINES|AMMO_RECIEVER_AUTO_EJECT_LOCKED
	gun_skill_category = SKILL_HEAVY_WEAPONS
	fire_sound = 'sound/weapons/guns/fire/launcher.ogg'
	dry_fire_sound = 'sound/weapons/guns/fire/launcher_empty.ogg'
	reload_sound = 'sound/weapons/guns/interact/launcher_reload.ogg'
	unload_sound = 'sound/weapons/guns/interact/launcher_reload.ogg'
	fire_delay = 3 SECONDS
	recoil = 1
	recoil_unwielded = 2
	scatter = 0
	scatter_unwielded = 8
	accuracy_mult = 1
	accuracy_mult_unwielded = 0.9

/obj/item/ammo_magazine/wrist_cannon
	name = "\improper wrist-cannon internal magazine"
	desc = "desc here"
	caliber = CALIBER_84MM
	icon_state = "rocket_he"
	w_class = WEIGHT_CLASS_NORMAL
	magazine_flags = MAGAZINE_REFUND_IN_CHAMBER
	max_rounds = 5
	default_ammo = /datum/ammo/rocket/wrist_cannon
	reload_delay = 6 SECONDS

/datum/ammo/rocket/wrist_cannon
	name = "high explosive rocket"
	icon_state = "apfds"
	hud_state = "rocket_he"
	accurate_range = 7
	max_range = 14
	damage = 20
	penetration = 0
	sundering = 15
	ammo_behavior_flags = AMMO_BALLISTIC

/datum/ammo/rocket/wrist_cannon/drop_nade(turf/T)
	explosion(T, 0, 2, 3, 4)

//particle lance
/obj/item/implant/deployitem/wrist_cannon/particle
	name = "light particle lance"
	desc = "A compact yet powerful energy weapon capable of being stored within a cybernetic arm."
	helditem = /obj/item/weapon/gun/energy/wrist_particle_cannon

/obj/item/weapon/gun/energy/wrist_particle_cannon
	name = "light particle lance"
	desc = "Desc here."
	reload_sound = 'sound/weapons/guns/interact/rifle_reload.ogg'
	fire_sound = 'sound/weapons/guns/fire/plasma_precision_3.ogg'
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "wrist_cannon"
	rounds_per_shot = 10 //100 shots.
	gun_features_flags = GUN_AMMO_COUNTER|GUN_AMMO_COUNT_BY_SHOTS_REMAINING|GUN_NO_PITCH_SHIFT_NEAR_EMPTY|GUN_ENERGY
	reciever_flags = AMMO_RECIEVER_MAGAZINES|AMMO_RECIEVER_AUTO_EJECT_LOCKED
	ammo_datum_type = /datum/ammo/energy/light_particle_cannon
	default_ammo_type = /obj/item/cell/lasgun
	allowed_ammo_types = list(/obj/item/cell/lasgun)
	w_class = WEIGHT_CLASS_BULKY
	load_method = CELL
	gun_skill_category = SKILL_HEAVY_WEAPONS
	muzzle_flash_color = COLOR_CYAN

	windup_delay = 0.3 SECONDS
	windup_sound = 'sound/weapons/guns/fire/laser_charge_up.ogg'

	aim_slowdown = 0.3
	wield_delay = 0.5 SECONDS

	fire_delay = 3 SECONDS
	recoil = 1
	recoil_unwielded = 2
	scatter = 0
	scatter_unwielded = 8
	accuracy_mult = 1
	accuracy_mult_unwielded = 0.9

/datum/ammo/energy/light_particle_cannon
	name = "particle beam"
	hud_state = "laser_efficiency"
	damage = 60
	penetration = 40
	sundering = 10
	hitscan_effect_icon = "beam_particle"
	ammo_behavior_flags = AMMO_ENERGY|AMMO_HITSCAN|AMMO_PASS_THROUGH_MOB
	max_range = 12
	accurate_range = 7
	bullet_color = COLOR_CYAN

/datum/ammo/energy/light_particle_cannon/on_hit_mob(mob/M, obj/projectile/proj)
	staggerstun(M, proj, max_range = 2, weaken = 0.3 SECONDS, knockback = 2)
	staggerstun(M, proj, max_range = 7, stagger = 2 SECONDS, slowdown = 2)
