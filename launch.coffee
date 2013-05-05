
chrome.app.runtime.onLaunched.addListener ->
	chrome.app.window.create 'main.html',
		frame: "none"
		bounds:
			width: 600
			height: 400

