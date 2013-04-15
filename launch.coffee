
chrome.app.runtime.onLaunched.addListener ->
	chrome.app.window.create 'main.html',
		bounds:
			width: 600
			height: 400

