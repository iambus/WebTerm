
##################################################
# imports
##################################################


if module?.exports?
	$ = require 'jQuery'
	_ = require 'underscore'
	wcwidth = require 'wcwidth'
	mode = require './mode'
	common = require './common'
else
	$ = this.$
	_ = this._
	wcwidth = this.wcwidth
	mode = webterm.bbs.mode
	if not mode
		throw Error("webterm.bbs.mode is not loaded")
	common = webterm.bbs.common
	if not common
		throw Error("webterm.bbs.common is not loaded")

plugin = mode.plugin
Feature = mode.Feature
FeaturedMode = mode.FeaturedMode
{test_headline, test_footline} = mode.utils

##################################################
# helpers
##################################################

find_line_areas = (s, exprs) ->
	index = 0
	left = 1
	right = 1
	areas = []
	for expr in exprs
		right = left
		for i in [0...expr.length]
			if expr.charAt(i) != s.charAt(index)
				return
			right += wcwidth(s.charAt(index))
			i++
			index++
		areas.push [left, right-1]
		left = right
		if s.charAt(index) not in ['', ' ']
			return
		while s.charAt(index) == ' '
			index++
			left++
		if s.charAt(index) == ''
			if areas.length == exprs.length
				return areas
			else
				return
	return areas

find_line_area = (s, expr) ->
	start = s.indexOf(expr)
	if start == -1
		return
	left = 1 + wcwidth(s.substring(0, start))
	row = left + wcwidth(expr) - 1
	return [left, row]

map_areas_on_line = (screen, row, areas, bindings) ->
	if areas.length != bindings.length
		# something is wrong!
		return
	for i in [0...areas.length]
		[left, right] = areas[i]
		key = bindings[i]
		attrs = if _.isObject(key) then key else class: 'bbs-clickable', key: key
		screen.area.define_area attrs,
			row, left, row, right

map_areas_by_words_on_line = (screen, row, bindings) ->
	line = screen.view.text.row(row)
	areas = []
	keys = []
	for text, key of bindings
		area = find_line_area line, text
		if area
			areas.push area
			keys.push key
	if areas.length > 0
		map_areas_on_line screen, row, areas, keys

map_areas_by_whitespaces_on_line = (screen, row, text, bindings) ->
	line = screen.view.text.row(row)
	index = line.indexOf text
	if index >= 0
		areas = []
		m = text.split /\s+/
		for i in [0...m.length]
			word = m[i]
			index = line.indexOf word, index
			if index < 0
				# something is wrong!
				return
			left = 1 + wcwidth(line.substring(0, index))
			right = left + wcwidth(word) - 1
			areas.push [left, right]
		map_areas_on_line screen, row, areas, bindings

map_areas_by_regexp_on_line = (screen, row, regexp, bindings) ->
	line = screen.view.text.row(row)
	m = line.match regexp
	if m
		if m.length == 1
			left = 1 + wcwidth(line.substring(0, index))
			right = left + wcwidth(m[0]) - 1
			return map_areas_on_line screen, row, [[left, right]], [bindings]
		areas = []
		index = m.index
		for i in [1...m.length]
			word = m[i]
			index = line.indexOf word, index
			if index < 0
				# something is wrong!
				return
			left = 1 + wcwidth(line.substring(0, index))
			right = left + wcwidth(word) - 1
			areas.push [left, right]
		map_areas_on_line screen, row, areas, bindings

##################################################
# operations
##################################################

leave_article = (screen) ->
	if screen.view.text.foot().match /^下面还有/
		screen.events.send_key 'q', 'q'
	else
		screen.events.send_key 'q'

##################################################
# global
##################################################


class MousePaging extends common.MouseGestureFeature
	constructor: ->
		super
			'up': 'pageup'
			'down': 'pagedown'

class MouseHomeEnd extends common.MouseGestureFeature
	constructor: ->
		super
			'left up': 'home'
			'left down': 'end'

class MouseReadingHomeEnd extends common.MouseGestureFeature
	constructor: ->
		super
			'left up': 's'
			'left down': 'e'

class MouseEditingHomeEnd extends common.MouseGestureFeature
	constructor: ->
		super
			'left up': 'ctrl-s'
			'left down': 'ctrl-e'

class TopNotification extends Feature
	scan: (screen) ->
		if screen.view.text.head().match /^主选单/
			map_areas_by_words_on_line screen, 1,
				'[您有信件]': 'v'
				'[您有@提醒]': 'm enter k enter'
				'[您有回复提醒]': 'm enter l enter'
				'[您有Like提醒]': 'm enter b enter'
		else
			map_areas_by_words_on_line screen, 1,
				'[您有信件]': 'v'
				'[您有@提醒]': 'left left left left m enter k enter'
				'[您有回复提醒]': 'left left left left m enter l enter'
				'[您有Like提醒]': 'left left left left m enter b enter'

##################################################
# input options
##################################################

class Options extends Feature
	scan: (screen) ->
		map_areas_by_regexp_on_line screen, screen.height,
			/选择: (1\)十大话题) (2\)十大祝福) (3\)近期热点) (4\)系统热点) (5\)分区十大) (6\)百大版面) \[1\]:/
			['enter' , '2 enter' , '3 enter' , '4 enter' , '5 enter' , '6 enter']
		map_areas_by_whitespaces_on_line screen, screen.height-1,
			'1)文摘区 2)同主题 3)保留区 4)原作 5)同作者 6)标题关键字 7)超级文章选择'
			['enter' , '2 enter' , '3 enter' , '4 enter' , '5 enter' , '6 enter' , '7 enter']
		map_areas_by_regexp_on_line screen, screen.height,
			/(8\)本版精华区搜索) (9\)自删文章) (A\)积分变更) \[1\]:/
			['9 enter' , '9 enter' , 'a enter']
		line = screen.view.text.foot()
		if line.substring(0, 18) == '删除文章，确认吗？(Y/N) [N]'
			y = 'y enter'
			n = 'n enter'
			clear = ('backspace' for [0...line.substring(19).trim().length]).join ' '
			if clear
				y = clear + ' ' + y
				n = clear + ' ' + n
			screen.area.define_area class: 'bbs-clickable', key: y,
				screen.height, 20, screen.height, 20
			screen.area.define_area class: 'bbs-clickable', key: n,
				screen.height, 22, screen.height, 22

##################################################
# any key...
##################################################

class ClickWhitespace extends Feature
	scan: (screen) ->
		screen.area.define_area class:'click-whitespace', style:'cursor: pointer',
			1, 1, screen.height, screen.width
	render: (screen) ->
		screen.events.on_click '.click-whitespace', -> screen.events.send_key 'whitespace'

class ClickEnter extends Feature
	scan: (screen) ->
		screen.area.define_area class:'click-enter', style:'cursor: pointer',
			1, 1, screen.height, screen.width
	render: (screen) ->
		screen.events.on_click '.click-enter', -> screen.events.send_key 'enter'

class PressAnyKeyBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		m = {}
		m[line] = 'whitespace'
		map_areas_by_words_on_line screen, screen.height, m

class PressEnterKeyBottomBar extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, screen.height,
			'请按 ◆Enter◆ 继续': 'enter'
			'按回车键继续...': 'enter'
			'按 <ENTER> 键继续...': 'enter'

##################################################
# login
##################################################

class LoginGuest extends Feature
	scan: (screen) ->
		login_guest = -> screen.events.send_text 'guest\n'
		login_guest_and_skip_welcome = -> screen.events.send_key_sequence_string '[guest] enter whitespace whitespace whitespace whitespace whitespace whitespace whitespace whitespace whitespace'
		for row in [screen.height..1]
			line = screen.view.text.row(row).trim()
			if line
				if line == '请输入代号:'
					screen.events.on_key 'enter', login_guest
					screen.events.on_key 'whitespace', login_guest_and_skip_welcome
					screen.context_menus.register
						id: 'bbs-login-guest'
						title: '使用guest登录'
						onclick: login_guest
					screen.context_menus.register
						id: 'bbs-login-guest-and-skip-welcome'
						title: '使用guest登录并跳过欢迎画面'
						onclick: login_guest_and_skip_welcome
				break

##################################################
# main menu
##################################################

class MenuClick extends Feature
	scan: (screen) ->
		top = 5
		bottom = screen.height
		columns = [7, 9, 17, 43, 45]
		view = screen.view.text
		for column in columns
			menus = []
			for row in [top..bottom]
				if @is_menu view, row, column
					menus.push @get_menu view, row, column
			@fix_menus_with_whitespaces view, menus
			for [k, row, column_start, column_end] in menus
				if view.at(row, column_start-2) == '◆'
					screen.area.define_area class:'bbs-clickable menu-option current', key:'enter',
						row, column_start, row, column_end
				else
					screen.area.define_area class:'bbs-clickable menu-option', key: k + ' enter',
						row, column_start, row, column_end

	is_menu: (view, row, column) ->
		view.at(row, column+1) == ')' and
		(('A' <= view.at(row, column) <= 'Z') or ('0' <= view.at(row, column) <= '9')) and
		((view.at(row, column-2) == ' ' and view.at(row, column-1) == ' ') or
		 (view.at(row, column-2) == '◆' and view.at(row, column-1) == ''))

	get_menu: (view, row, column) ->
		k = view.at(row, column).toLowerCase()
		for i in [column+3...view.width]
			if view.at(row, i) == ' ' and view.at(row, i+1) == ' '
				return [k, row, column, i-1]
		return [k, row, column, i]

	fix_menus_with_whitespaces: (view, menus) ->
		if not menus?.length
			return menus
		longest = _.max(x[3] for x in menus)
		for menu in menus
			for i in [longest...menu[3]]
				if view.at(menu[1], i) != ' '
					menu[3] = i
					break
		return

class GotoDefaultBoard extends Feature
	scan: (screen) ->
		head = screen.view.text.head()
		m = head.match /\[([\w.]+)\]$/
		if m
			board = m[1]
			if head.match /^主选单\s/
				key = "s enter enter" # XXX: only for main menu?
			else
				key = "s [#{board}] enter" # XXX: only for main menu?
			screen.area.define_area class: 'bbs-clickable bbs-inner-clickable bbs-menu bbs-board-jump', key: key,
				1, 80-board.length-1, 1, 80

##################################################
# board
##################################################

class RowClick extends Feature
	scan: (screen) ->
		top = 4
		bottom = screen.height - 1
		view = screen.view.text
		current = null
		for row in [top..bottom]
			line = view.row(row)
			if /^(-?>|◆)\s+(\d+|\[提示\])/.test line
				current = row
				break
		if not current?
			# something is wrong
			return
		for row in [top..bottom]
			line = view.row(row)
			if /^(-?>|◆)\s+(\d+|\[提示\])/.test line
				screen.area.define_area class:'bbs-clickable bbs-row-item bbs-row-current-item', key:'enter', 'goto-key': '',
					row, 1, row, view.width
			else if /^\s+(\d+|\[提示\])/.test line
				if current < row
					goto = ('down' for [1..row-current]).join(' ')
					key = goto + ' enter'
				else if current > row
					goto = ('up' for [1..current - row]).join(' ')
					key = goto + ' enter'
				else
					goto = ''
					key = 'enter'
				screen.area.define_area class:'bbs-clickable bbs-row-item', key: key, 'goto-key': goto,
					row, 1, row, view.width

class RowFieldClick extends Feature
	scan_column: (screen, header_regexp, field_regexp, max_width, current_key, other_key) ->
		header = screen.view.text.row 3
		i = header.match(header_regexp)?.index
		if not i?
			# something is wrong...
			return
		left = wcwidth(header.substring(0, i)) + 1
		right_boundary = left + max_width
		if right_boundary > screen.width
			right_boundary = screen.width
		top = 4
		bottom = screen.height - 1
		current = null
		for row in [top..bottom]
			line = screen.view.text.row(row)
			if /^-?>/.test line
				current = row
				break
		if not current?
			# something is wrong
			return
		for row in [top..bottom]
			line = screen.view.text.row(row)
			if not /^(-?>|◆)?\s+(\d+|\[提示\])/.test line
				continue
			box = screen.view.text.row_range row, left, right_boundary
			i = box.indexOf ' '
			if i == 0
				continue
			if i < 0
				right = left + max_width
			else
				right = left + i - 1
			field = $.trim(box)
			if field_regexp and not field_regexp.test field
				continue
			offset = row - current
			if offset == 0
				key = current_key
			else
				key = other_key
			if _.isFunction key
				key = key field, offset
			if _.isString key
				attrs = class: 'bbs-clickable bbs-inner-clickable', key: key
			else if key?
				attrs = key
			else
				continue
			screen.area.define_area attrs, row, left, row, right

class ArticleRowUserClick extends RowFieldClick
	scan: (screen) ->
		@scan_column screen, /刊\s*登\s*者|发布者|发信者/, /^\w+$/, 12,
			'ctrl-a'
			(field) -> "u [#{field}] enter"


class BoardContextMenu extends Feature
	scan: (screen) ->
		normal_context = (context) ->
			$(context.target).closest('.bbs-row-item').length > 0
		non_guest_context = (context) ->
			normal_context(context) and context.screen.view.text.foot().match(/使用者\[(\w+)\]/)?[1] != 'guest'
		owner_context = (context) ->
			non_guest_context(context) # TODO: get article user and compare with current user
		goto_key = (context, key) ->
			goto = $(context.target).closest('.bbs-row-item').attr 'goto-key'
			if goto?
				if goto
					key = goto + ' ' + key
				screen.events.send_key_sequence_string key
		go = (key) ->
			(context) -> goto_key context, key

		screen.context_menus.register
			id: 'bbs-article-reply'
			title: '回复'
			onclick: go 'r r'
			context: non_guest_context
		screen.context_menus.register
			id: 'bbs-article-forward'
			title: '转帖'
			onclick: go 'ctrl-c'
			context: non_guest_context
		screen.context_menus.register
			id: 'bbs-article-edit'
			title: '编辑'
			onclick: go 'E'
			context: owner_context
		screen.context_menus.register
			id: 'bbs-article-first'
			title: '同主题首篇'
			onclick: go '='
			context: normal_context
		screen.context_menus.register
			id: 'bbs-article-source'
			title: '溯源'
			onclick: go '^'
			context: normal_context
		screen.context_menus.register
			id: 'bbs-article-info'
			title: '查看文章信息'
			onclick: go 'ctrl-q'
			context: normal_context
		screen.context_menus.register
			id: 'bbs-board-user-list'
			title: '查看驻版用户'
			onclick: -> screen.events.send_key 'ctrl-k'
			context: normal_context

class BoardToolbar extends Feature
	scan: (screen) ->
		toolbar = screen.view.text.row 2
		map_areas_by_regexp_on_line screen, 2,
			/(离开\[←,e\]) 选择\[(↑),(↓)\] (阅读\[→,r\]) (发表文章\[Ctrl-P\]) (砍信\[d\]) (备忘录\[TAB\]) (求助\[h\])/
			['left', 'up', 'down', 'right', 'ctrl-p', 'd', 'tab', 'h']
		if toolbar == '[十大模式]  离开[←,e] 记录位置并离开[q] 阅读[→,r] 同主题[^X,p] 同作者[^U,^H]  '
			map_areas_by_words_on_line screen, 2,
				'离开[←,e]': 'e'
				'记录位置并离开[q]': 'q'
				'阅读[→,r]': 'r'
				'同主题[^X,p]': 'p' # ctrl-x == p?
				'同作者[^U,^H]': 'ctrl+u' # ctrl-u == ctrl-p?


class BoardTopNotification extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, 1,
			'投票中，按 V 进入投票': 'V'


class BoardModeSwitch extends common.BBSMenu
	scan: (screen) ->
		m = screen.view.text.row(3).match /\[(..模式)\] $/
		if not m
			return
		if m[1] == '十大模式'
			return
		screen.area.define_area 'bbs-menu bbs-board-mode-switch', 3, 70, 3, 79
	render: (screen) ->
		menus = [['文摘区', '1']
						 ['同主题', '2']
						 ['保留区', '3']
						 ['原作',   '4']
						 ['同作者', '5']
						 ['标题搜索', '6']
						 ['超级文章', '7']
						 ['精华区搜索', '8']
						 ['自删文章', '9']
						 ['积分变更', 'a']]
		menus = (text: menu[0], class: 'bbs-clickable', key: "ctrl-g #{menu[1]} enter" for menu in menus)
		@render_menu_on_demand screen, ".bbs-menu.bbs-board-mode-switch", menus

class BoardBMClick extends Feature
	scan: (screen) ->
		head = screen.view.text.head()
		m = head.match(/^版主: (\w+ )+/)
		if m
			s = m[0]
			names = s.substring(4, s.length-1).split(' ')
			left = 7
			for name in names
				key = "u [#{name}] enter"
				right = left + name.length - 1
				screen.area.define_area class: 'bbs-clickable bbs-inner-clickable board-bm', key: key,
					1, left, 1, right
				left = right + 2

class BoardInfoClick extends Feature
	scan: (screen) ->
		head = screen.view.text.head()
		m = head.match(/^(?:版主:(?: (?:\w+|\[只读\]))+|诚征版主中)\s\s\s*(\S+|投票中，按 V 进入投票)\s*\s\s(?:讨论区)? \[([\w.]+)\]$/)
		if m
			cn_board = m[1]
			board = m[2]
			key = "U [#{board}] enter"
			mappings = {}
			if not /^\[.+\]|投票中，按 V 进入投票$/.test cn_board
				mappings[cn_board] = key
			mappings["[#{board}]"] = class: 'bbs-clickable bbs-menu bbs-board-jump', key: key
			map_areas_by_words_on_line screen, 1, mappings

class BoardJumpList extends common.BBSMenu

class BoardJumpListCache extends BoardJumpList
	scan: (screen) ->
		board = screen.view.text.head().match(/\[([\w.]+)\]$/)?[1]
		webterm.cache.mru("bbs.smth.boards:#{screen.name}", 10).put board

class BoardJumpListRender extends BoardJumpList
	render: (screen) ->
		menus = webterm.cache.get "bbs.smth.boards:#{screen.name}"
		if not menus
			return
		menus = (text: menu, class: 'bbs-clickable', key: "s [#{menu}] enter" for menu in menus)
		@render_menu_on_demand screen, ".bbs-menu.bbs-board-jump", menus

class BoardJumpListRenderInMainMenu extends BoardJumpList
	render: (screen) ->
		menus = webterm.cache.get "bbs.smth.boards:#{screen.name}"
		if not menus
			return
		menus = (text: menu, class: 'bbs-clickable', key: "s enter [#{menu}] enter" for menu in menus)
		@render_menu_on_demand screen, ".bbs-menu.bbs-board-jump", menus

class BottomUserClick extends Feature
	scan: (screen) ->
		foot = screen.view.text.foot()
		m = foot.match(/使用者\[(\w+)\]/)
		if m and m.index == 37
			user = m[1]
			left = 51
			right = left + user.length - 1
			key = "u [#{user}] enter"
			screen.area.define_area class: 'bbs-clickable bbs-inner-clickable board-info', key: key,
				screen.height, left, screen.height, right


##################################################
# reading
##################################################

class CleanAd extends Feature
	@patterns: [
		/※\s发自:\s*.*水木/
		/发自.*水木.*版/
		/ucsmth\/id543183096/
	]
	scan: (screen) ->
		for row in [1...screen.height]
			line = screen.view.text.row(row).trim()
			for pattern in CleanAd.patterns
				if _.isRegExp pattern
					if line.match(pattern)
						screen.data.clear_row row
				else if _.isString pattern
					if line == pattern
						screen.data.clear_row row

class ArticleContextMenu extends Feature
	scan: (screen) ->
		screen.context_menus.register
			id: 'bbs-article-first'
			title: '同主题首篇'
			onclick: ->
				leave_article(screen)
				screen.events.send_key '=', 'r'
		screen.context_menus.register
			id: 'bbs-article-source'
			title: '溯源'
			onclick: ->
				leave_article(screen)
				screen.events.send_key '^', 'r'

class ArticleUser extends Feature
	scan: (screen) ->
		line = screen.view.text.head()
		m = line.match(/^发信人: ((\w+) \(.*\)), 信区: (\w+)\s*$/)
		if m
			user = m[2]
			left = 9
			right = left + wcwidth(m[1]) - 1
			screen.area.define_area class: 'bbs-clickable', key: "u [#{user}] enter",
				1, left, 1, right

class ArticleBottom extends Feature
	scan: (screen) ->
		row = screen.height
		line = screen.view.text.foot().trim()
		if line.indexOf('| g 跳转 | l n 上下篇 | / ? 搜索 | s e 开头末尾|') > 0
			map_areas_by_words_on_line screen, row,
				'g 跳转': "g"
				'l': "l"
				'n': "n"
				'上': "l"
				'下篇': "n"
				'/': "/"
				'?': "?"
				'搜索': "/"
				's': "s"
				'e': "e"
				'开头': "s"
				'末尾': "e"
		else if line.indexOf('| g 跳转 | / ? 搜索 | s e 开头末尾|') > 0
			map_areas_by_words_on_line screen, row,
				'g 跳转': "g"
				'/': "/"
				'?': "?"
				's': "s"
				'e': "e"
				'开头': "s"
				'末尾': "e"
		else if line == '[阅读文章]  回信 R │ 结束 Q,← │上一封 ↑│下一封 <Space>,↓│主题阅读 ^X或p'
			map_areas_by_words_on_line screen, row,
				'回信 R': "r"
				'结束 Q,←': "q"
				'上一封 ↑': "up"
				'下一封 <Space>,↓': "enter"
				'主题阅读 ^X或p': "p" # ctrl-x == p?
		else if line == '[主题阅读]  回信 R │ 结束 Q,← │上一封 ↑│下一封 <Space>,↓'
			map_areas_by_words_on_line screen, row,
				'回信 R': "r"
				'结束 Q,←': "q"
				'上一封 ↑': "up"
				'下一封 <Space>,↓': "enter"
		else if line == '[通知模式] [阅读文章] 结束Q,| 上一篇 | 下一篇<空格>, | 同主题^x,p'
			map_areas_by_words_on_line screen, row,
				'结束Q': "q"
				'上一篇': "up"
				'下一篇<空格>': "whitespace"
				'同主题^x,p': "p" # ctrl-x == p?
		else if line == '[十大模式] [阅读文章] 结束 Q,← | 上一篇 ↑ | 下一篇 <Space>,↓ | 同主题 ^X,p'
			map_areas_by_words_on_line screen, row,
				'结束 Q,←': "q"
				'上一篇 ↑': "up"
				'下一篇 <Space>,↓': "whitespace"
				'同主题 ^X,p': "p" # ctrl-x == p?
		else if line == '[阅读精华区资料]  结束 Q,← │ 上一项资料 U,↑│ 下一项资料 <Enter>,<Space>,↓'
			map_areas_by_words_on_line screen, row,
				'结束 Q,←': "q"
				'上一项资料 U,↑': "up"
				'下一项资料 <Enter>,<Space>,↓': "enter"


class ArticleDownload extends Feature
	scan: (screen) ->
		command = ->
			buffer = []
			last_bottom = null
			is_article_start = (screen) ->
				head = screen.view.text.head()
				bottom = screen.view.text.foot()
				/^发信人:/.test(head) and /^\[阅读文章\]|第\(1-\d+\)行/.test(bottom)
			is_article_end = (screen) ->
				if /^\[阅读文章\]|\(100%\)/.test screen.view.text.foot() # XXX: 100% may be a wrong check
					/^※ 来源/m.test screen.to_text()
			is_article_changed = (screen) ->
				bottom = screen.view.text.foot()
				if bottom != last_bottom
					last_bottom = bottom
					true
			callback = ->
				console.log 'done!', buffer
			paging = ->
				buffer.push screen.to_text()
				if is_article_end(screen)
					callback()
					return
				append = (screen) ->
					buffer.push screen.to_text()
					if is_article_end(screen)
						callback()
						return
					screen.expect.check is_article_changed, append
					screen.events.send_key 'whitespace'
				screen.expect.check is_article_changed, append
				screen.events.send_key 'whitespace'
			if is_article_start(screen)
				paging()
			else
				screen.expect.check is_article_start, paging
				screen.events.send_key 's'
		screen.commands.register 'download_article', command
		screen.context_menus.register
			id: 'download_article'
			title: '全文下载'
			icon: 'download'
			onclick: command


##################################################
# post
##################################################

class AttachmentUpload extends Feature
	scan: (screen) ->
		if screen.view.text.row(1).trim() == '附件上传地址: (请勿将此链接发送给别人)'
			url = screen.view.text.row(2).trimRight()
			if url.match /^http:.*/
				screen.area.define_area 'bbs-attachment-url',
					2, 1, 2, url.length

	parse_response: (html) ->
		error_message = html.match(/<font color='red'>([^<>]+)<\/font>/)?[1]?.trim() or html.match(/<body>(您还没有登录，或者你发呆时间过长被服务器清除。)/)?[1]
		# TODO: check remaining bytes
		success_message = html.match(/\(最多能上传 \d+ 个, 还能上传 <font[^<>]+><b>\d+<\/b><\/font> 个\)/)?[0]?.replace /<[^<>]+>/g, ''
		if error_message and error_message != '提示：添加附件成功'
			return error_message: error_message
		else
			return success_message: "附件上传成功 #{success_message}"

	new_upload: (screen, url, sid, files) ->
		if files.length == 0
			return
		form =
			sid: sid
			counter: files.length
		for file, i in files
			form['attachfile'+i] = file
		webterm.upload.upload_files
			url: url
			form: form
			encoding: 'gbk'
			success: (data) =>
				{success_message, error_message} = @parse_response data
				screen.events.send_key 'u', 'enter'
				if error_message
					console.error error_message
					webterm.status_bar.error error_message
				else
					webterm.status_bar.info success_message
			error: ->
				console.error 'upload failed', arguments
				webterm.status_bar.error '上传文件失败'

	update_upload: (screen, url, sid, files) ->
		if files.length == 0
			return
		index = 0
		upload = =>
			if index >= files.length
				webterm.status_bar.info '所有附件上传完毕'
				screen.events.send_key 'u', 'enter'
				return
			file = files[index++]
			webterm.status_bar.info "正在上传附件 #{index}/#{files.length}"
			form =
				sid: sid
				attachfile: file
			webterm.upload.upload_files
				url: url
				form: form
				encoding: 'gbk'
				success: (data) =>
					{success_message, error_message} = @parse_response data
					if error_message
						console.error error_message
						webterm.status_bar.error error_message
					else
						webterm.status_bar.info success_message
						upload()
				error: ->
					console.error 'upload failed', arguments
					webterm.status_bar.error '上传文件失败'
		upload()

	render: (screen) ->
		url = $(screen.selector).find('.bbs-attachment-url').text()
		m = url.match /^http:\/\/www\.newsmth\.net\/(bbsupload\.php\?|bbseditatt\.php\?bid=\d+&id=\d+&)sid=(\w+)$/
		if not m
			# something is wrong!
			return
		url = url.replace /sid=\w+$/, 'act=add'
		sid = m[2]
		multiple = !! m[1].match /^bbsupload/
		webterm.status_bar.tip '你可以直接拖拽文件到屏幕上来上传附件，或者按ctrl-v/shift-insert上传剪切板的图片'

		if multiple
			upload = (files) => @new_upload screen, url, sid, files
		else
			upload = (files) => @update_upload screen, url, sid, files

		screen.events.on_dnd (data) =>
			upload data.files

		upload_clipboard_image = ->
			image_callback = (blob) ->
				filename = "webterm-clipboard-#{new Date().getTime()}.png"
				data =
					name: filename
					blob: blob
				upload [data]
			webterm.clipboard.get_image_as_png_blob image_callback, webterm.status_bar.error
		upload_clipboard_text = (text) ->
			if filename = text.match(/^http:\/\/\S+\/([^\s/\\]+\.\w+)$/)?[1]
				error = -> webterm.status_bar.error "下载失败：#{text}"
				webterm.ajax.get_blob text, error, (blob) ->
					data =
						name: filename
						blob: blob
					upload [data]
			else
				webterm.status_bar.error '剪切板内容可能不是一个合法的地址'
		upload_clipboard = ->
			text = webterm.clipboard.get()
			if text
				upload_clipboard_text(text)
			else
				upload_clipboard_image()
		screen.events.on_key 'ctrl-v', upload_clipboard
		screen.events.on_key 'shift-insert', upload_clipboard


class PostOptions extends Feature
	scan: (screen) ->
		map_areas_by_regexp_on_line screen, screen.height,
			/(P使用模板)，(Z选择标签)，(b回复到信箱)，(T改标题)，(u传附件), (Q放弃), (Enter继续):/
			[
				'P enter'
				'Z enter'
				'b enter'
				'T enter'
				'u enter'
				'Q enter'
				'enter'
			]


##################################################
# reply
##################################################

class ReplyOptions extends Feature
	scan: (screen) ->
		map_areas_by_regexp_on_line screen, screen.height,
			/(S)\/(Y)\/(N)\/(R)\/(A) 改引言模式，(b回复到信箱)，(T改标题)，(u传附件), (Q放弃), (Enter继续):/
			[
				{class: 'bbs-clickable', key: 'S enter', title: '引用前三行（默认）'}
				{class: 'bbs-clickable', key: 'Y enter', title: '完整引用原文'}
				{class: 'bbs-clickable', key: 'N enter', title: '不引用原文'}
				{class: 'bbs-clickable', key: 'R enter', title: '完整引用原文及回复，不加引用:，不包含签名档'}
				{class: 'bbs-clickable', key: 'A enter', title: '完整引用原文及回复，加引用:，包括签名档'}
				'b enter'
				'T enter'
				'u enter'
				'Q enter'
				'enter'
			]

##################################################
# favorite
##################################################

class BoardRowManagerClick extends RowFieldClick
	scan: (screen) ->
		@scan_column screen, /版  主/, /^\w+$/, 12,
			(field) -> "u [#{field}] enter"
			(field) -> "u [#{field}] enter"

class FavorateListToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '主选单[←,e] 阅读[→,r] 选择[↑,↓] 添加[a,A] 移动[m] 删除[d] 排序[S] 求助[h]'
			map_areas_by_words_on_line screen, row,
				'主选单[←,e]': "e"
				'阅读[→,r]': "r"
				'↑': "up"
				'↓': "down"
				'添加[a,A]': "a"
				'移动[m]': "m"
				'删除[d]': "d"
				'排序[S]': "S"
				'求助[h]': "h"

##################################################
# board list
##################################################


class BoardListContextMenu extends Feature
	scan: (screen) ->
		screen.context_menus.register
			id: 'bbs-ctrl-k'
			title: '查看驻版文章'
			onclick: ->
				screen.events.send_key 'ctrl-k'

class BoardListToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '主选单[←,e] 阅读[→,r] 选择[↑,↓] 添加到收藏夹[a] 排序[S] 求助[h]'
			map_areas_by_words_on_line screen, row,
				'主选单[←,e]': "e"
				'阅读[→,r]': "r"
				'↑': "up"
				'↓': "down"
				'添加到收藏夹[a]': "a"
				'排序[S]': "S"
				'求助[h]': "h"
		else if toolbar == '主选单[←,e] 阅读[→,r] 选择[↑,↓] 列出[y] 排序[S] 搜寻[/] 切换[c] 求助[h]'
			map_areas_by_words_on_line screen, row,
				'主选单[←,e]': "e"
				'阅读[→,r]': "r"
				'↑': "up"
				'↓': "down"
				'列出[y]': "y"
				'排序[S]': "S"
				'搜寻[/]': "/"
				'切换[c]': "c"
				'求助[h]': "h"

##################################################
# top 10
##################################################

class Top10 extends Feature
	scan: (screen) ->
		text = screen.view.text
		head = text.head().trim()
		foot = text.foot().trim()

		scan_topics = (need_enter) ->
			for i in [1..10]
				r1 = 1 + i * 2
				r2 = r1 + 1
				s = text.row r1
				a = text.row r2
				m = s.match /^第\s+(\d+) 名 信区 : (\w+)/
				if not m
					# something is wrong
					return
				if i != parseInt m[1]
					# something is wrong
					return
				board = m[2]
				if a[2] == '◆'
					screen.area.define_area class: 'bbs-clickable bbs-inner-clickable', key: 's',
						r1, 17, r1, 17 + board.length - 1
					screen.area.define_area class: 'bbs-clickable', key: 'enter',
						r2, 1, r2, screen.width
				else
					k = i % 10
					if need_enter
						if i == 1
							k = 'enter'
						else
							k = 'enter ' + k
					screen.area.define_area class: 'bbs-clickable bbs-inner-clickable', key: k + ' s',
						r1, 17, r1, 17 + board.length - 1
					screen.area.define_area class: 'bbs-clickable', key: k + ' enter',
						r2, 1, r2, screen.width

		if head == '-----===== 本日十大热门话题 =====-----'
			scan_topics()

		else if /^-----===== 本日\d+区十大热门话题 =====-----$/.test head
			m = foot.match /^(选择|查看)分区: (\S+) /
			if not m
				# something is wrong
				return
			pages = m[2].replace /\[.*\]/, ''
			if m[1] == '查看'
				scan_topics()
				m = {}
				for i in [0...pages.length]
					n = pages.charAt i
					m[n] = 'esc ' + n
				map_areas_by_words_on_line screen, screen.height, m
			else
				scan_topics(true)
				m = {}
				for i in [0...pages.length]
					n = pages.charAt i
					m[n] = n
				map_areas_by_words_on_line screen, screen.height, m

		map_areas_by_words_on_line screen, screen.height,
			'<TAB>阅读分区十大': 'tab'
			'<H>查阅帮助信息': 'h'


##################################################
# x list
##################################################

class XToolBar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == 'F 寄回自己的信箱┃↑↓ 移动┃→ <Enter> 读取┃←,q 离开'
			map_areas_by_words_on_line screen, row,
				'F 寄回自己的信箱': "F"
				'↑': "up"
				'↓': "down"
				'→ <Enter> 读取': "enter"
				'←,q 离开': "q"

class XBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		if line == '[功能键]  说明 h │ 离开 q,← │ 移动游标 k,↑,j,↓ │ 读取资料 Rtn,→'
			map_areas_by_words_on_line screen, screen.height,
				'说明 h': "h"
				'离开 q,←': "q"
				'k': "k"
				'↑': "up"
				'j': "j"
				'↓': "down"
				'读取资料 Rtn,→': "enter"
		else if line == '[版  主]  说明 h │ 离开 q,← │ 新增文章 a │ 新增目录 g │ 修改档案 e'
			map_areas_by_words_on_line screen, screen.height,
				'说明 h': "h"
				'离开 q,←': "q"
				'新增文章 a': "a"
				'新增目录 g': "g"
				'修改档案 e': "e"

##################################################
# mail
##################################################

class MailMenuToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '主选单[←,e] 进入[Enter] 选择[↑,↓] 左右切换[Tab] 添加[a] 改名[T] 删除[d]'
			map_areas_by_words_on_line screen, row,
				'主选单[←,e]': "e"
				'进入[Enter]': "enter"
				'↑': "up"
				'↓': "down"
				'左右切换[Tab]': "tab"
				'添加[a]': "a"
				'改名[T]': "T"
				'删除[d]': "d"

class RepliesRowBoardClick extends RowFieldClick
	scan: (screen) ->
		@scan_column screen, /讨论区名称/, /^\w+$/, 12,
			's'
			(field, offset) ->
				if offset > 0
					('down' for [1..offset]).join(' ') + ' s'
				else if offset < 0
					('up' for [1..-offset]).join(' ') + ' s'

class RepliesToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '''离开[←,e] 选择[↑,↓] 阅读[→,r] 版面[s] 删除[d] 标题[?,/] 作者[a,A] 寻版[',"]'''
			map_areas_by_words_on_line screen, row,
				'离开[←,e]': "e"
				'↑': "up"
				'↓': "down"
				'阅读[→,r]': "r"
				'版面[s]': "s"
				'删除[d]': "d"
				'?': class: 'bbs-clickable', key: '?', title: '向上搜索标题'
				'/': class: 'bbs-clickable', key: '/', title: '向下搜索标题'
				'a': class: 'bbs-clickable', key: 'a', title: '向下搜索作者'
				'A': class: 'bbs-clickable', key: 'A', title: '向上搜索作者'
				"'": class: 'bbs-clickable', key: "'", title: '向下寻版'
				'"': class: 'bbs-clickable', key: '"', title: '向上寻版'

##################################################
# timeline
##################################################

class TimelineRowBoardClick extends RowFieldClick
	scan: (screen) ->
		@scan_column screen, /讨论区名称/, /^\w+$/, 12,
			'ctrl-s'
			(field) -> "s [#{field}] enter"

class TimelineToolbar extends Feature
	scan: (screen) ->
		if screen.view.text.row(2) == '离开[←,e] 选择[↑,↓] 阅读[→,r] 版面[^s] 标题[?,/] 作者[a,A] 寻版[b,B] 帮助[h]'
			map_areas_by_words_on_line screen, 2,
				'离开[←,e]': "e"
				'↑': "up"
				'↓': "down"
				'阅读[→,r]': "r"
				'版面[^s]': "ctrl-s"
				'?': class: 'bbs-clickable', key: '?', title: '向上搜索标题'
				'/': class: 'bbs-clickable', key: '/', title: '向下搜索标题'
				'a': class: 'bbs-clickable', key: 'a', title: '向下搜索作者'
				'A': class: 'bbs-clickable', key: 'A', title: '向上搜索作者'
				'b': class: 'bbs-clickable', key: 'b', title: '向下寻版'
				'B': class: 'bbs-clickable', key: 'B', title: '向上寻版'
				'帮助[h]': "h"

##################################################
# vote
##################################################

class VoteListToolbar extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, 2,
			'离开[←,e]': "e"
			'求助[h]': "h"
			'进行投票[→,r <cr>]': "r"
			'上': "up"
			'下': "down"
			'↑': "up"
			'↓': "down"

class VoteOpenOption extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, 3,
			'(0)取消': "backspace 0 enter"
			'(1)是非': "backspace 1 enter"
			'(2)单选': "backspace 2 enter"
			'(3)复选': "backspace 3 enter"
			'(4)数值': "backspace 4 enter"
			'(5)问答': "backspace 5 enter"

##################################################
# user
##################################################

class UserBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		if line == '寄信[m]           加,减朋友[o,d] 说明档[l] 驻版[k] 短信[w] 其它键继续'
			map_areas_by_words_on_line screen, screen.height,
				'寄信[m]': "m"
				'加': "o"
				'o': "o"
				'减': "d"
				'd': "d"
				'说明档[l]': "l"
				'驻版[k]': "k"
				'短信[w]': "w"
				'其它键继续': "whitespace"
		else if line == '聊天[t] 寄信[m] 送讯息[s] 加,减朋友[o,d] 选择使用者[↑,↓] 切换模式 [f] 求救[h]'
			map_areas_by_words_on_line screen, screen.height,
				'聊天[t]': "t"
				'寄信[m]': "m"
				'送讯息[s]': "s"
				'加': "o"
				'o': "o"
				'减': "d"
				'd': "d"
				'↑': "up"
				'↓': "down"
				'切换模式 [f]': "f"
				'求救[h]': "h"
		else if line == '聊天[t] 寄信[m] 送讯息[s] 加,减朋友[o,d] 说明档[l] 驻版[k] 短信[w] 其它键继续'
			map_areas_by_words_on_line screen, screen.height,
				'聊天[t]': "t"
				'寄信[m]': "m"
				'送讯息[s]': "s"
				'加': "o"
				'o': "o"
				'减': "d"
				'd': "d"
				'说明档[l]': "l"
				'驻版[k]': "k"
				'短信[w]': "w"
				'其它键继续': "whitespace"

##################################################
# board info
##################################################

class BoardInfoBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		if line == '添加到个人定制区[a]'
			map_areas_by_words_on_line screen, screen.height,
				'添加到个人定制区[a]': "a"

##################################################
# article info
##################################################

class ArticleInfoBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		map_areas_by_words_on_line screen, screen.height,
			'<A>查看对本文的积分奖励记录': "A"

##################################################
# article score history
##################################################

class ArticleScoreHistoryBottomBar extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, screen.height,
			'上一页 PGUP,↑': "up"
			'下一页 PGDN,空格,↓': "whitespace"
			'退出 Q,E,←': "q"

##################################################
# board user
##################################################

class BoardUserListToolbar extends Feature
	scan: (screen) ->
		map_areas_by_words_on_line screen, 2,
			'加入驻版[j]': "j"
			'取消驻版[t]': "t"
			'其他操作请通过[h]查看帮助': "h"

##################################################
# user list
##################################################

class UserListToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '聊天[t] 寄信[m] 送讯息[s] 加,减朋友[o,d] 看说明档[→,r] 切换模式 [f] 求救[h]'
			map_areas_by_words_on_line screen, row,
				'聊天[t]': "t"
				'寄信[m]': "m"
				'送讯息[s]': "s"
				'加': "o"
				'o': "o"
				'减': "d"
				'd': "d"
				'看说明档[→,r]': "r"
				'切换模式 [f]': "f"
				'求救[h]': "h"

##################################################
# logout
##################################################

class LogoutMenu extends Feature
	scan: (screen) ->
		top = 9
		left = 30
		for row in [top...top+4]
			if screen.view.text.at(row, left) != '['
				return
			k = screen.view.text.at row, left + 1
			right = left + wcwidth(screen.view.text.row_range(row, left, left+26).trim()) - 1
			if screen.view.text.at(row, left-2) == '◆'
				screen.area.define_area class:'bbs-clickable', key:'enter', row, left, row, right
			else
				screen.area.define_area class:'bbs-clickable', key:k+' enter', row, left, row, right
		screen.area.define_area class:'bbs-clickable', key:'esc', 15, 35, 15, 46

##################################################
# spoiler
##################################################

class BoardSpoilerWarning extends Feature
	@pattern: /剧透|\bjt\b/i
	scan: (screen) ->
		is_dangerous = ->
			headline = $(screen.selector).find('.bbs-row-current-item').text().match(/(★|●|Re:).*/)?[0]
			return headline?.match BoardSpoilerWarning.pattern
		screen.events.on_key 'enter', ->
			if is_dangerous()
				webterm.dialogs.confirm '剧透警告', '打开内容可能涉及剧透，是否要继续？', (ok) ->
					if ok
						screen.events.send_key 'enter'
			else
				screen.events.send_key 'enter'
	render: (screen) ->
		screen.events.on_click '.bbs-row-item', (div) ->
			click = ->
				k = div.getAttribute('key')
				if k
					screen.events.send_key_sequence_string k
			headline = $(div).text().match(/(★|●|Re:).*/)?[0]
			if headline?.match BoardSpoilerWarning.pattern
				webterm.dialogs.confirm '剧透警告', '打开内容可能涉及剧透，是否要继续？', (ok) ->
					if ok
						click()
			else
				click()

class ArticleSpoilerWarning extends Feature
	@pattern: /标  题:.*(剧透|\bjt\b)|以下.*(剧透|\bjt\b)/i
	scan: (screen) ->
		if screen.view.text.full().match ArticleSpoilerWarning.pattern
			$(screen.selector).hide()
			webterm.dialogs.confirm '剧透警告', '打开内容可能涉及剧透，是否要继续？', (ok) ->
				if not ok
					leave_article screen
				$(screen.selector).show()

##################################################
# summary
##################################################

class login_mode extends FeaturedMode
	@check: (screen) ->
		foot = screen.view.text.foot().trim()
		foot.match(/^请输入代号:/) or (foot == '' and screen.view.text.row(23).match /^请输入代号:/)
	name: 'login'
	features: [
		LoginGuest
	]

class option_input_mode extends FeaturedMode
	@check: (screen) ->
		if screen.cursor.row != screen.height
			return
		if screen.data.at(screen.height, 1).background
			return
		if screen.data.at(screen.height, 1).foreground
			return
		line = screen.view.text.foot().trim()
		if not line
			return
		return line.indexOf(':') != -1 or line.match /确认.*Y\/N/
	name: 'option_input'
	features: [
		Options
	]

class anykey_mode extends FeaturedMode
	@check: test_footline(/^\s*(按任何键继续|按任何键继续 \.\.|☆ 按任意键继续\.\.\.|本文无积分奖励记录, 按 <任意> 键继续\.\.\.)\s*$/)
	name: 'anykey'
	features: [
		ClickWhitespace
		PressAnyKeyBottomBar
	]

class enterkey_mode extends FeaturedMode
	@check: test_footline(/^\s*(请按 ◆Enter◆ 继续|帮助信息显示完成, 按回车键继续\.\.\.|您不能给自己奖励个人积分, 按 <ENTER> 键继续\.\.\.|您不能给该用户奖励个人积分, 按 <ENTER> 键继续\.\.\.)\s*$/)
	name: 'enterkey'
	features: [
		ClickEnter
		PressEnterKeyBottomBar
	]

class main_menu_mode extends FeaturedMode
	@check: test_headline(/^主选单\s/)
	name: 'main_menu'
	features: [
		MenuClick
		TopNotification
		GotoDefaultBoard
		BoardJumpListRenderInMainMenu
		BottomUserClick
	]

class talk_menu_mode extends FeaturedMode
	@check: test_headline(/^聊天选单\s/)
	name: 'talk_menu'
	features: [
		MenuClick
	]

class board_mode extends FeaturedMode
	@check: test_headline(/^(?:版主:(?: (?:\w+|\[只读\]))+|诚征版主中)\s\s\s*(\S+|投票中，按 V 进入投票)\s*\s\s(?:讨论区)? \[([\w.]+)\]$/)
	name: 'board'
	features: [
		RowClick
		BoardContextMenu
		BoardToolbar
		TopNotification
		BoardTopNotification
		BoardModeSwitch
		ArticleRowUserClick
		BoardBMClick
		BoardInfoClick
		BoardJumpListCache
		BoardJumpListRender
		BottomUserClick
		MousePaging
		MouseHomeEnd
		BoardSpoilerWarning
	]

class read_mode extends FeaturedMode
	@check: test_footline(/^(下面还有喔|\[(通知|十大)模式\] \[阅读文章\]|\[阅读文章\]|\[主题阅读\]|\[阅读精华区资料\])\s/)
	name: 'read'
	features: [
		common.CleanSignature
		CleanAd
		common.URLRecognizer
		common.ImagePreview
		common.IPResolve
		ArticleContextMenu
		ArticleUser
		ArticleBottom
		ArticleDownload
		ClickWhitespace
		MousePaging
		MouseReadingHomeEnd
		ArticleSpoilerWarning
	]

class edit_mode extends FeaturedMode
	@check: test_footline(/状态 \[插入\]/)
	name: 'edit'
	features: [
		MousePaging
		MouseEditingHomeEnd
	]

class post_mode extends FeaturedMode
	@check: test_footline(/^P使用模板，Z选择标签，b回复到信箱，T改标题，u传附件, Q放弃, Enter继续:/)
	name: 'post'
	features: [
		AttachmentUpload
		PostOptions
		common.URLRecognizer
	]

class reply_mode extends FeaturedMode
	@check: test_footline(/^S\/Y\/N\/R\/A 改引言模式，b回复到信箱，T改标题，u传附件, Q放弃, Enter继续:/)
	name: 'reply'
	features: [
		AttachmentUpload
		ReplyOptions
		common.URLRecognizer
	]

class favorite_mode extends FeaturedMode
	@check: test_headline(/^\[个人定制区\]\s/)
	name: 'favorite'
	features: [
		RowClick
		BoardRowManagerClick
		BoardListContextMenu
		FavorateListToolbar
		TopNotification
		GotoDefaultBoard
		BoardJumpListRender
		BottomUserClick
		MousePaging
	]

class board_list_mode extends FeaturedMode
	@check: test_headline(/^\[讨论区列表\]\s/)
	name: 'board_list'
	features: [
		RowClick
		BoardRowManagerClick
		BoardListContextMenu
		BoardListToolbar
		TopNotification
		GotoDefaultBoard
		BoardJumpListRender
		BottomUserClick
		MousePaging
	]

class board_group_mode extends FeaturedMode
	@check: test_headline(/^分类讨论区选单\s/)
	name: 'board_group'
	features: [
		MenuClick
	]

class top10_mode extends FeaturedMode
	@check: (screen) ->
		/^\s*-----===== 本日(\d+区)?十大热门话题 =====-----\s*$/.test(screen.view.text.head()) and /<H>查阅帮助信息/.test(screen.view.text.foot())
	name: 'top10'
	features: [
		Top10
	]

class x_list_mode extends FeaturedMode
	@check: test_footline(/读取资料|修改档案/)
	name: 'x'
	features: [
		RowClick
		XToolBar
		XBottomBar
		MousePaging
		BoardSpoilerWarning
	]

class mail_menu_mode extends FeaturedMode
	@check: test_headline(/^\[处理信笺选单\]\s/)
	name: 'mail'
	features: [
		MenuClick
		MailMenuToolbar
		BoardSpoilerWarning
	]

class mail_list_mode extends FeaturedMode
	@check: test_headline(/^邮件选单\s/)
	name: 'mail_list'
	features: [
		RowClick
		ArticleRowUserClick
		BottomUserClick
		MousePaging
	]

class mail_replies_mode extends FeaturedMode
	@check: test_headline(/^\[回复我的文章\]\s/)
	name: 'mail_replies'
	features: [
		RowClick
		ArticleRowUserClick
		RepliesRowBoardClick
		RepliesToolbar
		BottomUserClick
		MousePaging
		BoardSpoilerWarning
	]

class mail_at_mode extends FeaturedMode
	@check: test_headline(/^\[@我的文章\]\s/)
	name: 'mail_at'
	features: [
		RowClick
		ArticleRowUserClick
		RepliesRowBoardClick
		RepliesToolbar
		BottomUserClick
		MousePaging
		BoardSpoilerWarning
	]

class mail_like_mode extends FeaturedMode
	@check: test_headline(/^\[Like我的文章\]\s/)
	name: 'mail_like'
	features: [
		RowClick
		ArticleRowUserClick
		RepliesRowBoardClick
		RepliesToolbar
		BottomUserClick
		MousePaging
		BoardSpoilerWarning
	]

class timeline_mode extends FeaturedMode
	@check: test_headline(/^\[驻版阅读模式\]\s/)
	name: 'timeline'
	features: [
		RowClick
		ArticleRowUserClick
		TimelineRowBoardClick
		TimelineToolbar
		BottomUserClick
		MousePaging
		BoardSpoilerWarning
	]

class vote_list_mode extends FeaturedMode
	@check: test_headline /^\[投票箱列表\]/
	name: 'vote_list'
	features: [
		RowClick
		VoteListToolbar
		MousePaging
	]

class vote_open_options_mode extends FeaturedMode
	@check: test_headline /^开启投票箱/
	name: 'vote_open_options'
	features: [
		VoteOpenOption
	]

class info_menu_mode extends FeaturedMode
	@check: test_headline(/^工具箱选单\s/)
	name: 'system'
	features: [
		MenuClick
	]

class system_menu_mode extends FeaturedMode
	@check: test_headline(/^系统资讯选单\s/)
	name: 'system'
	features: [
		MenuClick
	]

class user_mode extends FeaturedMode
	@check: test_footline(/寄信/)
	name: 'user'
	features: [
		UserBottomBar
	]

class board_info_mode extends FeaturedMode
	@check: test_footline(/^\s*添加到个人定制区\[a\]\s*$/)
	name: 'board_info'
	features: [
		BoardInfoBottomBar
		ClickWhitespace
	]

class article_info_mode extends FeaturedMode
	@check: test_footline(/^\s*<A>查看对本文的积分奖励记录/)
	name: 'article_info'
	features: [
		common.URLRecognizer
		ArticleInfoBottomBar
		ClickWhitespace
	]

class article_score_history_mode extends FeaturedMode
	@check: test_headline /^文章.*的积分奖励记录.*/
	name: 'article_score_history'
	features: [
		ArticleScoreHistoryBottomBar
	]

class board_user_list_mode extends FeaturedMode
	@check: test_headline(/^\[驻版用户列表\]/)
	name: 'board_user_list'
	features: [
		RowClick
		ArticleRowUserClick
		MousePaging
	]

class user_list_mode extends FeaturedMode
	@check: test_headline(/^\[使用者列表\]/)
	name: 'user_list'
	features: [
		RowClick
		UserListToolbar
		MousePaging
	]


class logout_mode extends FeaturedMode
	@check: (screen) ->
		screen.view.text.head().trim() == '' and
		screen.view.text.row(9).trim() == '║     [1] 寄信给水木             ║' and
		screen.view.text.row(15).trim() == '║            取消(ESC) ▃        ║'
	name: 'logout'
	features: [
		LogoutMenu
	]

class default_mode extends FeaturedMode
	@check: -> true
	name: 'default'
	features: [
		ClickWhitespace
	]

class global_mode extends FeaturedMode
	name: 'global'
	features: [
		common.Clickable
	]

modes = [
	login_mode
	option_input_mode
	anykey_mode
	enterkey_mode
	main_menu_mode
	user_mode
	board_mode
	read_mode
	edit_mode
	post_mode
	reply_mode
	favorite_mode
	board_list_mode
	board_group_mode
	top10_mode
	x_list_mode
	mail_menu_mode
	mail_list_mode
	mail_replies_mode
	mail_at_mode
	mail_like_mode
	timeline_mode
	vote_list_mode
	vote_open_options_mode
	info_menu_mode
	system_menu_mode
	board_info_mode
	article_info_mode
	article_score_history_mode
	board_user_list_mode
	user_list_mode
	talk_menu_mode
	logout_mode
	default_mode
]

features = [
	MousePaging
	MouseHomeEnd
	MouseReadingHomeEnd
	MouseEditingHomeEnd
	Options
	ClickWhitespace
	ClickEnter
	PressAnyKeyBottomBar
	PressEnterKeyBottomBar
	LoginGuest
	MenuClick
	GotoDefaultBoard
	RowClick
	RowFieldClick
	BoardContextMenu
	BoardToolbar
	TopNotification
	BoardTopNotification
	BoardModeSwitch
	ArticleRowUserClick
	BoardBMClick
	BoardInfoClick
	BoardJumpList
	BoardJumpListRender
	BoardJumpListRenderInMainMenu
	BottomUserClick
	CleanAd
	ArticleContextMenu
	ArticleUser
	ArticleBottom
	ArticleDownload
	AttachmentUpload
	PostOptions
	ReplyOptions
	BoardRowManagerClick
	FavorateListToolbar
	BoardListContextMenu
	BoardListToolbar
	Top10
	XToolBar
	XBottomBar
	VoteListToolbar
	MailMenuToolbar
	RepliesRowBoardClick
	RepliesToolbar
	TimelineRowBoardClick
	TimelineToolbar
	UserBottomBar
	BoardInfoBottomBar
	ArticleInfoBottomBar
	ArticleScoreHistoryBottomBar
	BoardUserListToolbar
	UserListToolbar
	LogoutMenu
	BoardSpoilerWarning
	ArticleSpoilerWarning
]

for m in modes
	modes[m.name] = m
for f in features
	features[f.name] = f

##################################################
# done!
##################################################

smth = (screen) -> plugin screen, modes, global_mode
smth.modes = modes
smth.features = features

##################################################
# exports
##################################################

exports = smth

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.smth = exports

