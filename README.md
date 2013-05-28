A Term for Chrome
=================

### 简介

WebTerm是一款使用Web技术开发，基于Chrome的telnet BBS客户端。

WebTerm的当前版本提供的功能包括（但不限于）：

* 一个新的界面
  * 多标签浏览
  ![多标签浏览](http://iambus.github.io/static/webterm-0101-a-new-look.png)
  * 快速连接菜单
  ![快速连接菜单](http://iambus.github.io/static/webterm-0102-quick-connect.png)
  * 桌面通知
  ![屏幕通知](http://iambus.github.io/static/webterm-0103-inline-notifications.png)
  ![桌面通知](http://iambus.github.io/static/webterm-0104-desktop-notifications.png)
* 增强的鼠标功能
  * 内置鼠标手势功能
  ![内置鼠标手势功能](http://iambus.github.io/static/webterm-0201-mouse-gesture.png)
  * 更多可点击的屏幕元素
  ![更多可点击的屏幕元素](http://iambus.github.io/static/webterm-0202-more-buttons.png)
  * 内嵌菜单
  ![快速跳转到最近访问过的版面](http://iambus.github.io/static/webterm-0203-inline-menus-1.png)
  ![快速切换版面模式](http://iambus.github.io/static/webterm-0204-inline-menus-2.png)
  * 右键菜单
  ![右键菜单](http://iambus.github.io/static/webterm-0205-context-menus.png)
* 阅读
  * 图片预览
  ![图片预览](http://iambus.github.io/static/webterm-0301-image-preview.png)
* 编辑
  * ASCII彩色复制
  * 矩形复制
  ![矩形复制](http://iambus.github.io/static/webterm-0401-rect-copy.png)
* 脚本引擎
  * 可以使用CoffeeScript脚本进行定制（包括快捷键）和交互
  ![脚本引擎](http://iambus.github.io/static/webterm-0501-scripting.png)
* 附加功能
  * IP地址显示
  ![IP地址显示](http://iambus.github.io/static/webterm-0601-ip.png)
  * 清除签名档
  * 清除某些垃圾水木客户发帖附加的广告
  * 剧透警告
  ![剧透警告](http://iambus.github.io/static/webterm-0602-spoiler-warning.png)

### To build:

Prerequisites:

* [node.js](http://nodejs.org/)
* [CoffeeScript](http://coffeescript.org/)

Build:

	npm install
    cake deps
    cake build

### To install:

Please read [here](http://developer.chrome.com/extensions/getstarted.html#unpacked) to learn how to load an unpackaged app.

__Note__: This is a startup project, so you will find no public distribution at this time. If you want to try, build it yourself, or ask the author for a packaged app via email.


## License

Copyright (C) 2013

Distributed under the MIT License.
