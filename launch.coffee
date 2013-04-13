
chrome.app.runtime.onLaunched.addListener ->
	chrome.app.window.create 'main.html',
		bounds:
			width: 800
			height: 440

