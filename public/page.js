function registerEvents() {
	syncElements();
	window.onmousewheel = syncElements;
}

function syncElements() {
	moveNavigation();
}


function moveNavigation() {
	var posY = (document.all ? document.scrollTop : window.pageYOffset);
	var sideBar = document.getElementById("navigation");
	var winHeight = getWindowHeight();
	if (posY > 0) {
		sideBar.style.top = (posY + 30) + "px";
	} else if (posY == 0) {
		sideBar.style.top = "30px";
	}
}

function getWindowWidth() {
	var windowWidth = 0;
	if (document.documentElement && document.documentElement.clientWidth) {
		windowWidth = document.documentElement.clientWidth;
	}
	else {
		if (document.body && document.body.clientWidth) {
			windowWidth = document.body.clientWidth;
		}
	}
	return windowWidth;
}

function getWindowHeight() {
	var windowHeight = 0;
	if (document.documentElement && document.documentElement.clientHeight) {
		windowHeight = document.documentElement.clientHeight;
	}
	else {
		if (document.body && document.body.clientHeight) {
			windowHeight = document.body.clientHeight;
		}
	}
	return windowHeight;
}
