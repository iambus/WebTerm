
##################################################
# imports
##################################################

if module?.exports?
	smth = require './smth'
	lily = require './lily'
else
	smth = webterm.bbs.smth
	lily = webterm.bbs.lily
	firebird = webterm.bbs.firebird
	if not smth
		throw Error("webterm.bbs.smth is not loaded")
	if not lily
		throw Error("webterm.bbs.lily is not loaded")
	if not firebird
		throw Error("webterm.bbs.firebird is not loaded")

##################################################
# address book
##################################################

list = [
	name: '水木社区'
	host: 'bbs.newsmth.net'
	port: 23
	protocol: 'telnet'
	module: smth
	icon: 'lib/smth.ico'
,
	name: '南京大学小百合'
	host: 'bbs.nju.edu.cn'
	port: 23
	protocol: 'telnet'
	module: lily
	icon: 'lib/lily.ico'
,
	name: '北邮人'
	host: 'bbs.byr.cn'
	port: 23
	protocol: 'telnet'
	module: smth
	icon: 'lib/byr.ico'
,
	name: '饮水思源'
	host: 'bbs.sjtu.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/sjtu.ico'
,
	name: '日月光华'
	host: 'bbs.fudan.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/fudan.ico'
,
	name: '北大未名'
	host: 'bbs.pku.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/pku.ico'
,
	name: '东南大学虎踞龙蟠'
	host: 'bbs.seu.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/seu.ico'
,
	name: '白云黄鹤'
	host: 'bbs.whnet.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/whnet.ico'
,
	name: '珞珈山水'
	host: 'bbs.whu.edu.cn'
	port: 23
	protocol: 'telnet'
	module: firebird
	icon: 'lib/whu.ico'
,
	name: '兵马俑'
	host: 'bbs.xjtu.edu.cn'
	port: 23
	protocol: 'telnet'
	module: null
	icon: 'lib/xjtu.ico'
]




##################################################
# exports
##################################################

exports = list

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.list = exports
