/datum/ai_unit
	var/mob/living/carbon/human/squad_leader
	var/list/mob/living/carbon/human/squad_list
	var/list/subformations

/datum/ai_unit/New()
	. = ..()
	squad_list = list()
	subformations = list()

/datum/ai_unit/proc/add_member(mob/living/carbon/human/new_member)
	//reg sigs
	squad_list += new_member

datum/ai_unit/proc/remove_member(mob/living/carbon/human/old_member)
	//unreg sigs
	if(squad_leader == old_member)
		remove_leader(old_member)
	squad_list -= new_member

datum/ai_unit/proc/add_leader(mob/living/carbon/human/new_leader)
	if(squad_leader)
		remove_leader(squad_leader)
	squad_leader = new_leader
	//reg sigs

datum/ai_unit/proc/remove_leader(mob/living/carbon/human/old_leader)
	//unreg sigs
	squad_leader = null
