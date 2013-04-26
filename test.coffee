

test = ->
	screen = new Screen

	bbs.smth(screen)

	load_ascii = (screen, files...) ->
		load_ascii_at = (i) ->
			if i < files.length
				resources.get_raw "test/" + files[i], (data) ->
					screen.fill_ascii_raw new Uint8Array data
					load_ascii_at i+1
			else
				screen.render()
		load_ascii_at 0

	#	load_ascii screen, 'smth_menu_main_1', 'smth_menu_main_2'
	#	load_ascii screen, 'smth_list_1', 'smth_list_2'
	#	load_ascii screen, 'list_bug_a_1', 'list_bug_a_2'
	load_ascii screen, 'smth_read_a_1', 'smth_read_a_2', 'smth_read_a_3'
	#	load_ascii screen, 'smth_long_url'
	#	load_ascii screen, 'smth_logout'
	#	load_ascii screen, 'board_list_1', 'board_list_2'
	#	load_ascii screen, 'board_group_1', 'board_group_2', 'board_group_3', 'board_group_4', 'board_group_5'
	#	load_ascii screen, 'smth_user_1'
	#	load_ascii screen, 'board_info_1'
	#	load_ascii screen, 'login_error_1', 'login_error_2', 'login_error_3', 'login_error_4', 'login_error_5'
	#	load_ascii screen, 'goto_shida_1', 'goto_shida_2'
	#	load_ascii screen, 'ctrl+g'
	#	load_ascii screen, 'shida_1', 'shida_2', 'shida_3'
	#	load_ascii screen, 'shida_sub_1', 'shida_sub_2', 'shida_sub_3'
	#	load_ascii screen, 'shida_sub_on_1', 'shida_sub_on_2', 'shida_sub_on_3'
	#	load_ascii screen, 'netnovel_1', 'netnovel_2', 'netnovel_3'

	window.screen = screen # XXX: for debugging


this.test = test
