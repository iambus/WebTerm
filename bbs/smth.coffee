
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
	mode = bbs.mode
	if not mode
		throw Error("bbs.mode is not loaded")
	common = bbs.common
	if not common
		throw Error("bbs.common is not loaded")

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
		attrs = if _.isObject(key) then key else class: 'clickable', key: key
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
# global
##################################################


class Clickable extends Feature
	render: (screen) ->
		screen.events.on_click_div 'div.clickable', (div) ->
			k = div.getAttribute('key')
			if k
				for x in k.split(' ')
					if /^\[.+\]$/.test x
						screen.events.put_text x.substring 1, x.length - 1
					else
						screen.events.put_key x
					screen.events.send()

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
		screen.events.on_click '.click-whitespace', -> screen.events.send_key 'enter'

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
					screen.area.define_area class:'clickable menu-option current', key:'enter'
						row, column_start, row, column_end
				else
					screen.area.define_area class:'clickable menu-option', key: k + ' enter'
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
		m = head.match(/\[(\w+)\]$/)
		if m
			board = m[1]
			key = "s enter enter" # XXX: only for main menu?
			screen.area.define_area class: 'clickable inner-clickable', key: key,
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
			if /^-?>\s+(\d+|\[提示\])/.test line
				current = row
				break
		if not current?
			# something is wrong
			return
		for row in [top..bottom]
			line = view.row(row)
			if /^-?>\s+(\d+|\[提示\])/.test line
				screen.area.define_area class:'clickable', key:'enter',
					row, 1, row, view.width
			else if /^\s+(\d+|\[提示\])/.test line
				if current < row
					key = ('down' for [1..row-current]).join(' ') + ' enter'
				else if current > row
					key = ('up' for [1..current-row]).join(' ') + ' enter'
				else
					key = 'enter'
				screen.area.define_area class:'clickable', key: key,
					row, 1, row, view.width

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
			'[您有信件]': 'v'
			'[您有@提醒]': 'left left left left m enter k enter'
			'[您有回复提醒]': 'left left left left m enter l enter'


class BoardModeSwitch extends Feature
	scan: (screen) ->
		if /\[..模式\] $/.test screen.view.text.row 3
			screen.area.define_area 'menu board-mode-switch', 3, 70, 3, 79
	render: (screen) ->
		# TODO

class BoardUserClick extends Feature
	scan: (screen) ->
		header = screen.view.text.row 3
		i = header.match(/刊\s*登\s*者|发布者|发信者/)?.index
		if not i?
			# something is wrong...
			return
		left = wcwidth(header.substring(0, i)) + 1
		for row in [4..screen.height-1]
			box = screen.view.text.row_range row, left, left + 12
			i = box.indexOf ' '
			if i == 0
				continue
			if i < 0
				right = left + 12
			else
				right = left + i - 1
			user = $.trim(box)
			if screen.view.text.at(row, 1) == '>'
				key = 'ctrl+a'
			else
				key = "u [#{user}] enter"
			screen.area.define_area class: 'clickable inner-clickable', key: key,
				row, left, row, right

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
				screen.area.define_area class: 'clickable inner-clickable board-bm', key: key,
					1, left, 1, right
				left = right + 2

class BoardInfoClick extends Feature
	scan: (screen) ->
		head = screen.view.text.head()
		m = head.match(/^(?:版主:(?: \w+)+|诚征版主中)\s\s\s*(\S+|投票中，按 V 进入投票)\s*\s\s(?:讨论区)? \[(\w+)\]$/)
		if m
			cn_board = m[1]
			board = m[2]
			key = "U [#{board}] enter"
			mappings = {}
			if not /^\[.+\]|投票中，按 V 进入投票$/.test cn_board
				mappings[cn_board] = key
			mappings["[#{board}]"] = key
			map_areas_by_words_on_line screen, 1, mappings

class BottomUserClick extends Feature
	scan: (screen) ->
		foot = screen.view.text.foot()
		m = foot.match(/使用者\[(\w+)\]/)
		if m and m.index == 37
			user = m[1]
			left = 51
			right = left + user.length - 1
			key = "u [#{user}] enter"
			screen.area.define_area class: 'clickable inner-clickable board-info', key: key,
				screen.height, left, screen.height, right


##################################################
# reading
##################################################

class ArticleUser extends Feature
	scan: (screen) ->
		line = screen.view.text.head()
		m = line.match(/^发信人: ((\w+) \(.*\)), 信区: (\w+)\s*$/)
		if m
			user = m[2]
			left = 9
			right = left + wcwidth(m[1]) - 1
			screen.area.define_area class: 'clickable', key: "u [#{user}] enter",
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
				'下': "n"
				'/': "/"
				'?': "?"
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
		else if line == '[通知模式] [阅读文章] 结束Q,| 上一篇 | 下一篇<空格>, | 同主题^x,p'
			map_areas_by_words_on_line screen, row,
				'结束 Q': "q"
				'上一篇': "up"
				'下一篇': "whitespace"
				'主题阅读 ^X或p': "p" # ctrl-x == p?
		else if line == '[阅读精华区资料]  结束 Q,← │ 上一项资料 U,↑│ 下一项资料 <Enter>,<Space>,↓'
			map_areas_by_words_on_line screen, row,
				'结束 Q,←': "q"
				'上一项资料 U,↑': "up"
				'下一项资料 <Enter>,<Space>,↓': "enter"

class ArticleURL extends Feature
	scan: (screen) ->
		text = screen.view.text.full()
		url_regexp = /http:\/\/[\w:\/?&=%+@$;._-]+/g
		while m = url_regexp.exec text
			start = wcwidth(text.substring(0, m.index))
			end = start + m[0].length - 1
			top = Math.floor(start / screen.width) - 1
			left = start - screen.width * (top - 1) + 1
			bottom = Math.floor(end / screen.width) - 1
			right = end - screen.width * (bottom - 1) + 1
			screen.area.define_area 'href', top, left, bottom, right

	render: (screen) ->
		$('div.href').replaceWith ->
			"<a href='#{$(@).text()}' target='_blank'>#{$(@).html()}</a>"

class ArticleImagePreview extends Feature
	render: (screen) ->
		$(screen.selector).find('a').preview()

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
			onclick: command


##################################################
# reply
##################################################

class ReplyOptions extends Feature
	scan: (screen) ->
		map_areas_by_regexp_on_line screen, screen.height,
			/(S)\/(Y)\/(N)\/(R)\/(A) 改引言模式，(b回复到信箱)，(T改标题)，(u传附件), (Q放弃), (Enter继续):/
			[
				{class: 'clickable', key: 'S enter', title: '引用前三行（默认）'}
				{class: 'clickable', key: 'Y enter', title: '完整引用原文'}
				{class: 'clickable', key: 'N enter', title: '不引用原文'}
				{class: 'clickable', key: 'R enter', title: '完整引用原文及回复，不加引用:，不包含签名档'}
				{class: 'clickable', key: 'A enter', title: '完整引用原文及回复，加引用:，包括签名档'}
				'b enter'
				'T enter'
				'u enter'
				'Q enter'
				'enter'
			]

##################################################
# favorite
##################################################

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
					screen.area.define_area class: 'clickable inner-clickable', key: 's',
						r1, 17, r1, 17 + board.length - 1
					screen.area.define_area class: 'clickable', key: 'enter',
						r2, 1, r2, screen.width
				else
					k = i % 10
					if need_enter
						if i == 1
							k = 'enter'
						else
							k = 'enter ' + k
					screen.area.define_area class: 'clickable inner-clickable', key: k + ' s',
						r1, 17, r1, 17 + board.length - 1
					screen.area.define_area class: 'clickable', key: k + ' enter',
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

class RowBoardClick extends Feature
	scan: (screen) ->
		header = screen.view.text.row 3
		i = header.match(/讨论区名称/)?.index
		if not i?
			# something is wrong...
			return
		left = wcwidth(header.substring(0, i)) + 1
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
			box = screen.view.text.row_range row, left, left + 12
			i = box.indexOf ' '
			if i == 0
				continue
			if i < 0
				right = left + 12
			else
				right = left + i - 1
			board = $.trim(box)
			if /^(-?>\s*|\s+)\d+/.test line
				if current < row
					key = ('down' for [1..row-current]).join(' ') + ' s'
				else if current > row
					key = ('up' for [1..current-row]).join(' ') + ' s'
				else
					key = 's'
				screen.area.define_area class: 'clickable inner-clickable', key: key,
					row, left, row, right


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
				screen.area.define_area class:'clickable', key:'enter', row, left, row, right
			else
				screen.area.define_area class:'clickable', key:k+' enter', row, left, row, right
		screen.area.define_area class:'clickable', key:'esc', 15, 35, 15, 46

##################################################
# summary
##################################################

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
		if line.indexOf(':') == -1
			return
		return true
	name: 'option_input'
	features: [
		Options
	]

class anykey_mode extends FeaturedMode
	@check: test_footline(/^\s*(按任何键继续|按任何键继续 \.\.|☆ 按任意键继续\.\.\.)\s*$/)
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
		GotoDefaultBoard
		BottomUserClick
	]

class talk_menu_mode extends FeaturedMode
	@check: test_headline(/^聊天选单\s/)
	name: 'talk_menu'
	features: [
		MenuClick
	]

class board_mode extends FeaturedMode
	@check: test_headline(/^(?:版主:(?: \w+)+|诚征版主中)\s\s\s*(\S+|投票中，按 V 进入投票)\s*\s\s(?:讨论区)? \[(\w+)\]$/)
	name: 'board'
	features: [
		RowClick
		BoardToolbar
		BoardTopNotification
		BoardModeSwitch
		BoardUserClick
		BoardBMClick
		BoardInfoClick
		BottomUserClick
		MousePaging
		MouseHomeEnd
	]

class read_mode extends FeaturedMode
	@check: test_footline(/^(下面还有喔|\[通知模式\] \[阅读文章\]|\[阅读文章\]|\[阅读精华区资料\])\s/)
	name: 'read'
	features: [
		ArticleUser
		ArticleBottom
		ArticleURL
		ArticleImagePreview
		ArticleDownload
		ClickWhitespace
		MousePaging
		MouseReadingHomeEnd
	]

class reply_mode extends FeaturedMode
	@check: test_footline(/^S\/Y\/N\/R\/A 改引言模式，b回复到信箱，T改标题，u传附件, Q放弃, Enter继续:/)
	name: 'reply'
	features: [
		ReplyOptions
	]

class favorite_mode extends FeaturedMode
	@check: test_headline(/^\[个人定制区\]\s/)
	name: 'favorite'
	features: [
		RowClick
		FavorateListToolbar
		BottomUserClick
		MousePaging
	]

class board_list_mode extends FeaturedMode
	@check: test_headline(/^\[讨论区列表\]\s/)
	name: 'board_list'
	features: [
		RowClick
		BoardListToolbar
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
	]

class mail_menu_mode extends FeaturedMode
	@check: test_headline(/^\[处理信笺选单\]\s/)
	name: 'mail'
	features: [
		MenuClick
		MailMenuToolbar
	]

class mail_list_mode extends FeaturedMode
	@check: test_headline(/^邮件选单\s/)
	name: 'mail_list'
	features: [
		RowClick
		BoardUserClick
		BottomUserClick
	]

class mail_replies_mode extends FeaturedMode
	@check: test_headline(/^\[回复我的文章\]\s/)
	name: 'mail_replies'
	features: [
		RowClick
		BoardUserClick
		RowBoardClick
		BottomUserClick
		MousePaging
	]

class mail_at_mode extends FeaturedMode
	@check: test_headline(/^\[@我的文章\]\s/)
	name: 'mail_at'
	features: [
		RowClick
		BoardUserClick
		RowBoardClick
		BottomUserClick
		MousePaging
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
	features: [Clickable]

modes = [
	option_input_mode
	anykey_mode
	enterkey_mode
	main_menu_mode
	board_mode
	read_mode
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
	info_menu_mode
	system_menu_mode
	user_mode
	board_info_mode
	user_list_mode
	talk_menu_mode
	logout_mode
	default_mode
]

##################################################
# done!
##################################################

smth = (screen) -> plugin screen, modes, global_mode

##################################################
# exports
##################################################

exports = smth

if module?.exports?
	module.exports = exports
else
	this.bbs = this.bbs ? {}
	this.bbs.smth = exports

