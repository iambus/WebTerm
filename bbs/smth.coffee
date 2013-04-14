
##################################################
# imports
##################################################


if module?.exports?
	$ = require 'jQuery' # XXX: not working on windows?
	_ = require 'underscore'
	wcwidth = require 'wcwidth'
	mode = require './mode'
else
	$ = this.$
	_ = this._
	wcwidth = this.wcwidth
	mode = bbs.mode
	if not mode
		throw Error("bbs.mode is not loaded")

plugin = mode.plugin
Feature = mode.Feature
{featured_mode, featured_mode_by, test_headline, test_footline} = mode.utils

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

global_mode = featured_mode 'global', [
	Clickable
]

##################################################
# main menu
##################################################

class MenuClick extends Feature
	scan: (screen) ->
		top = 10
		bottom = screen.data.height
		columns = [9, 17, 43, 45]
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
		view.at(row, column+2) == ' ' and
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
		bottom = screen.data.height - 1
		view = screen.view.text
		current = null
		for row in [top..bottom]
			line = view.row(row)
			if /^-?>\s+(\d+|\[提示\])/.test line
				current = row
				break
		for row in [top..bottom]
			line = view.row(row)
			if /^-?>\s+(\d+|\[提示\])/.test line
				screen.area.define_area class:'clickable', key:'enter',
					row, 1, row, view.width
			else if /^\s+(\d+|\[提示\])/.test line
				if current < row
					key = ('down' for [1..row-current]).join ' '
				else
					key = ('up' for [1..current-row]).join ' '
				screen.area.define_area class:'clickable', key: key + ' enter',
					row, 1, row, view.width

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

class BoardToolbar extends Feature
	scan: (screen) ->
		toolbar = screen.view.text.row 2
		if toolbar == '离开[←,e] 选择[↑,↓] 阅读[→,r] 发表文章[Ctrl-P] 砍信[d] 备忘录[TAB] 求助[h]  '
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'left',
				2, 1, 2, 10
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'up',
				2, 17, 2, 17
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'down',
				2, 20, 2, 20
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'right',
				2, 24, 2, 33
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'ctrl-p',
				2, 35, 2, 50
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'd',
				2, 52, 2, 58
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'tab',
				2, 60, 2, 70
			screen.area.define_area class: 'clickable board-toolbar-hint', key: 'h',
				2, 72, 2, 78


class BoardTopVote extends Feature
	scan: (screen) ->
		head = screen.view.text.head()
		area = find_line_area(head, '投票中，按 V 进入投票')
		if area
			screen.area.define_area class: 'clickable board-top-vote', key: 'V',
				1, area[0], 1, area[1]


class BoardModeSwitch extends Feature
	scan: (screen) ->
		if /\[..模式\] $/.test screen.view.text.row 3
			screen.area.define_area 'menu board-mode-switch', 3, 70, 3, 79
	render: (screen) ->
		# TODO

class BoardUserClick extends Feature
	scan: (screen) ->
		header = screen.view.text.row 3
		i = header.indexOf '刊'
		if i < 0
			# something is wrong...
			return
		left = wcwidth(header.substring(0, i)) + 1
		for row in [4..screen.height-1]
			box = screen.view.text.row_range row, left, 22
			i = box.indexOf ' '
			if i == 0
				continue
			if i < 0
				right = 22
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
		m = head.match(/^(?:版主:(?: \w+)+|诚征版主中)\s\s\s*(\S+)\s*\s\s(?:讨论区)? \[(\w+)\]$/)
		if m
			cn_board = m[1]
			board = m[2]
			key = "U [#{board}] enter"
			mappings = {}
			mappings[cn_board] = key
			mappings["[#{board}]"] = key
			map_keys_on_line screen, 1, mappings

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


map_keys_on_line = (screen, row, bindings) ->
	line = screen.view.text.row(row)
	for text, key of bindings
		area = find_line_area line, text
		if area
			screen.area.define_area class: 'clickable', key: key,
				row, area[0], row, area[1]

class ArticleBottom extends Feature
	scan: (screen) ->
		row = screen.height
		line = screen.view.text.foot().trim()
		if line.indexOf('| g 跳转 | l n 上下篇 | / ? 搜索 | s e 开头末尾|') > 0
			map_keys_on_line screen, row,
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
			map_keys_on_line screen, row,
				'g 跳转': "g"
				'/': "/"
				'?': "?"
				's': "s"
				'e': "e"
				'开头': "s"
				'末尾': "e"
		else if line == '[阅读文章]  回信 R │ 结束 Q,← │上一封 ↑│下一封 <Space>,↓│主题阅读 ^X或p'
			map_keys_on_line screen, row,
				'回信 R': "r"
				'结束 Q,←': "q"
				'上一封 ↑': "up"
				'下一封 <Space>,↓': "enter"
				'主题阅读 ^X或p': "p"
		else if line == '[通知模式] [阅读文章] 结束Q,| 上一篇 | 下一篇<空格>, | 同主题^x,p'
			map_keys_on_line screen, row,
				'结束 Q': "q"
				'上一篇': "up"
				'下一篇': "whitespace"
				'主题阅读 ^X或p': "p"
		else if line == '[阅读精华区资料]  结束 Q,← │ 上一项资料 U,↑│ 下一项资料 <Enter>,<Space>,↓'
			map_keys_on_line screen, row,
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



##################################################
# favorite
##################################################


##################################################
# board list
##################################################


class BoardListToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '主选单[←,e] 阅读[→,r] 选择[↑,↓] 添加到收藏夹[a] 排序[S] 求助[h]'
			map_keys_on_line screen, row,
				'主选单[←,e]': "e"
				'阅读[→,r]': "r"
				'↑': "up"
				'↓': "down"
				'添加到收藏夹[a]': "a"
				'排序[S]': "S"
				'求助[h]': "h"
		else if toolbar == '主选单[←,e] 阅读[→,r] 选择[↑,↓] 列出[y] 排序[S] 搜寻[/] 切换[c] 求助[h]'
			map_keys_on_line screen, row,
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
# x list
##################################################

class XToolBar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == 'F 寄回自己的信箱┃↑↓ 移动┃→ <Enter> 读取┃←,q 离开'
			map_keys_on_line screen, screen.height,
				'F 寄回自己的信箱': "F"
				'↑': "up"
				'↓': "down"
				'→ <Enter> 读取': "enter"
				'←,q 离开': "q"

class XBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		if line == '[功能键]  说明 h │ 离开 q,← │ 移动游标 k,↑,j,↓ │ 读取资料 Rtn,→'
			map_keys_on_line screen, screen.height,
				'说明 h': "h"
				'离开 q,←': "q"
				'k': "k"
				'↑': "up"
				'j': "j"
				'↓': "down"
				'读取资料 Rtn,→': "enter"
		else if lien == '[版  主]  说明 h │ 离开 q,← │ 新增文章 a │ 新增目录 g │ 修改档案 e'
			map_keys_on_line screen, screen.height,
				'说明 h': "h"
				'离开 q,←': "q"
				'新增文章 a': "a"
				'新增目录 g': "g"
				'修改档案 e': "e"

##################################################
# user
##################################################

class UserBottomBar extends Feature
	scan: (screen) ->
		line = screen.view.text.foot().trim()
		if line == '寄信[m]           加,减朋友[o,d] 说明档[l] 驻版[k] 短信[w] 其它键继续'
			map_keys_on_line screen, screen.height,
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
			map_keys_on_line screen, screen.height,
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
			map_keys_on_line screen, screen.height,
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
			map_keys_on_line screen, screen.height,
				'添加到个人定制区[a]': "a"

##################################################
# user list
##################################################

class UserListToolbar extends Feature
	scan: (screen) ->
		row = 2
		toolbar = screen.view.text.row(row).trim()
		if toolbar == '聊天[t] 寄信[m] 送讯息[s] 加,减朋友[o,d] 看说明档[→,r] 切换模式 [f] 求救[h]'
			map_keys_on_line screen, row,
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


main_menu_mode = featured_mode_by test_headline(/^主选单\s/), 'main_menu', [
	MenuClick
	GotoDefaultBoard
	BottomUserClick
]

talk_menu_mode = featured_mode_by test_headline(/^聊天选单\s/), 'talk_menu', [
	MenuClick
]

board_mode = featured_mode_by test_headline(/^(版主: |诚征版主中).* 讨论区 \[.+\]$/), 'board', [
	RowClick
	BoardToolbar
	BoardTopVote
	BoardModeSwitch
	BoardUserClick
	BoardBMClick
	BoardInfoClick
	BottomUserClick
]

read_mode = featured_mode_by test_footline(/^(下面还有喔|\[通知模式\] \[阅读文章\]|\[阅读文章\]|\[阅读精华区资料\])\s/), 'read', [
	ArticleUser
	ArticleBottom
	ArticleURL
]

favorite_mode = featured_mode_by test_headline(/^\[个人定制区\]\s/), 'favorite', [
	RowClick
]

board_list_mode = featured_mode_by test_headline(/^\[讨论区列表\]\s/), 'board_list', [
	RowClick
	BoardListToolbar
	BottomUserClick
]
board_group_mode = featured_mode_by test_headline(/^分类讨论区选单\s/), 'board_group', [
	MenuClick
]

x_list_mode = featured_mode_by test_footline(/读取资料|修改档案/), 'x', [
	RowClick
	XToolBar
	XBottomBar
]

system_mode = featured_mode_by test_headline(/^系统资讯选单\s/), 'system', [
	MenuClick
]

user_mode = featured_mode_by test_footline(/寄信/), 'user', [
	UserBottomBar
]

board_info_mode = featured_mode_by test_footline(/^\s*添加到个人定制区\[a\]\s*$/), 'board_info', [
	BoardInfoBottomBar
]

user_list_mode = featured_mode_by test_headline(/^\[使用者列表\]/), 'user_list', [
	RowClick
	UserListToolbar
]

press_any_key_mode = featured_mode_by test_footline(/^\s*按任何键继续 \.\.\s*$/), 'user', [
]

is_logout_mode = (screen) ->
	screen.view.text.head().trim() == '' and
	screen.view.text.row(9).trim() == '║     [1] 寄信给水木             ║' and
	screen.view.text.row(15).trim() == '║            取消(ESC) ▃        ║'
logout_mode = featured_mode_by is_logout_mode, 'logout', [
	LogoutMenu
]

modes = [
	main_menu_mode
	board_mode
	read_mode
	favorite_mode
	board_list_mode
	board_group_mode
	x_list_mode
	system_mode
	user_mode
	board_info_mode
	user_list_mode
	talk_menu_mode
	logout_mode
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

