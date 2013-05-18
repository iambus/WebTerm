

load_ascii = (screen, files...) ->
	load_ascii_at = (i) ->
		if i < files.length
			webterm.resources.get_raw "test/" + files[i], (data) ->
				screen.fill_ascii_raw new Uint8Array data
				load_ascii_at i+1
		else
			screen.render()
	load_ascii_at 0

load_json = (screen, file) ->
	webterm.resources.get_text "test/" + file, (data) ->
		screen.data.data = JSON.parse data
		screen.cursor.row = screen.height
		screen.cursor.column = screen.width
		screen.screen_updated()
		screen.render()

ctrl_s = (screen) ->
	screen.commands.register_persisted 'ctrl-s', ->
		chrome.fileSystem.chooseEntry type: 'saveFile', accepts: [extensions: ['json']], (writableFileEntry) ->
			if not writableFileEntry
				console.log 'save file canceled?'
				return
			error_handler = (e) ->
				console.log 'save file error!', arguments
			writer_callback = (writer) ->
				writer.onerror = error_handler
				writer.onwriteend = (e) ->
					console.log 'save file good!', arguments
				writer.write new Blob [JSON.stringify(screen.data.data)], type: 'text/plain'
			writableFileEntry.createWriter writer_callback, error_handler
	screen.events.on_key_persisted 'ctrl-s', ->
		screen.commands.execute('ctrl-s')
	screen.events.on_key_persisted 'ctrl-shift-s', ->
		screen.events.send_key('ctrl-s')

setup = (screen) ->
	webterm.bbs.smth(screen)
	ctrl_s(screen)

test = (selector) ->
	screen = new webterm.Screen selector ? "##{webterm.tabs.nth_id(1)} .screen"
	setup(screen)

#	load_ascii screen, 'smth_menu_main_1', 'smth_menu_main_2'
#	load_ascii screen, 'smth_list_1', 'smth_list_2'
#	load_ascii screen, 'list_bug_a_1', 'list_bug_a_2'
#	load_ascii screen, 'smth_read_a_1', 'smth_read_a_2', 'smth_read_a_3'
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
#	load_ascii screen, 'any_key_2'
#	load_json screen, 'a.json'
#	load_json screen, 'fav.json'
#	load_json screen, 'mail_menu.json'
#	load_json screen, 'reply_me.json'
#	load_json screen, 'at_me.json'
#	load_json screen, 'mail_list.json'
#	load_json screen, 'toolbox.json'
#	load_json screen, 'can_not_select.json'
#	load_json screen, 'posting.json'
#	load_json screen, 'posting1.json'
#	load_json screen, 'replying.json'
#	load_json screen, 'login.json'
#	load_json screen, 'H.json'
	load_json screen, 'images.json'
#	load_json screen, 'images2.json'
#	load_json screen, 'ascii_1.json'
#	load_json screen, 'ascii_2.json'
#	load_json screen, 'ascii_3.json'
#	load_json screen, 'gesture_bug.json'

	screen: screen

test.setup = setup

this.test = test
