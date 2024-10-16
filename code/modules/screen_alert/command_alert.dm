#define MAX_COMMAND_MESSAGE_LEN 300

/atom/movable/screen/text/screen_text/command_order
	maptext_height = 64
	maptext_width = 480
	maptext_x = 0
	maptext_y = 0
	screen_loc = "LEFT,TOP-3"

	letters_per_update = 2
	fade_out_delay = 5 SECONDS
	style_open = "<span class='maptext' style=font-size:20pt;text-align:center valign='top'>"
	style_close = "</span>"

/datum/action/innate/message_squad
	name = "Send Order"
	action_icon_state = "screen_order_marine"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_KB_SENDORDER,
	)
	///What skill is needed to have this action
	var/skill_name = SKILL_LEADERSHIP
	///What minimum level in that skill is needed to have that action
	var/skill_min = SKILL_LEAD_TRAINED

/datum/action/innate/message_squad/should_show()
	return owner.skills.getRating(skill_name) >= skill_min

/datum/action/innate/message_squad/can_use_action()
	. = ..()
	if(!.)
		return
	if(owner.stat != CONSCIOUS || TIMER_COOLDOWN_CHECK(owner, COOLDOWN_HUD_ORDER))
		return FALSE

/datum/action/innate/message_squad/action_activate()
	if(!can_use_action())
		return
	var/mob/living/carbon/human/human_owner = owner
	var/text = tgui_input_text(human_owner, "Maximum message length [MAX_COMMAND_MESSAGE_LEN]", "Send message to squad",  max_length = MAX_COMMAND_MESSAGE_LEN, multiline = TRUE)
	if(!text)
		return
	var/filter_result = CAN_BYPASS_FILTER(human_owner) ? null : is_ic_filtered(text)
	if(filter_result)
		to_chat(human_owner, span_warning("That message contained a word prohibited in IC chat! Consider reviewing the server rules.\n<span replaceRegex='show_filtered_ic_chat'>\"[text]\"</span>"))
		SSblackbox.record_feedback(FEEDBACK_TALLY, "ic_blocked_words", 1, lowertext(config.ic_filter_regex.match))
		REPORT_CHAT_FILTER_TO_USER(src, filter_result)
		log_filter("IC", text, filter_result)
		return
	if(!can_use_action())
		return
	var/sound/S = sound('sound/misc/notice2.ogg')
	S.channel = CHANNEL_ANNOUNCEMENTS
	TIMER_COOLDOWN_START(owner, COOLDOWN_HUD_ORDER, ORDER_COOLDOWN)
	log_game("[key_name(human_owner)] has broadcasted the hud message [text] at [AREACOORD(human_owner)]")
	if(human_owner.assigned_squad)
		deadchat_broadcast(" has sent a Squad Announcement:<br><br>[span_bigdeadsay("[text]")]<br><br>", human_owner, human_owner)
		for(var/mob/living/carbon/human/marine AS in human_owner.assigned_squad.marines_list)
			marine.play_screen_text("<span class='maptext' style=font-size:24pt;text-align:center valign='top'><u>SQUAD ANNOUNCEMENT:</u></span><br>" + text, /atom/movable/screen/text/screen_text/command_order)
			to_chat(marine, "[span_faction_alert("[span_faction_alert_minortitle("Squad Announcement")][span_faction_alert_text("[text]<br><br><i>Sent by [human_owner.real_name], the [human_owner.job.title]</i>")]")]")
		return
	deadchat_broadcast(" has sent a Command Announcement:<br><br>[span_bigdeadsay("[text]")]<br><br>", human_owner, human_owner)
	for(var/mob/living/carbon/human/human AS in GLOB.alive_human_list)
		if(human.faction == human_owner.faction)
			human.play_screen_text("<span class='maptext' style=font-size:24pt;text-align:center valign='top'><u>COMMAND ANNOUNCEMENT:</u></span><br>" + text, /atom/movable/screen/text/screen_text/command_order)
			to_chat(human, "[span_faction_alert("[span_faction_alert_title("Command Announcement")]<br>[span_faction_alert_text("[text]<br><br><i>Sent by [human_owner.real_name], the [human_owner.job.title]</i>")]")]")
			SEND_SOUND(human, S)
