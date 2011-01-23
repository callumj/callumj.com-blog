function toggleCheetSheet() {
	cheatsheetDOM = document.getElementById("cheatsheet");
	if (cheatsheetDOM.style.display != "none")
		cheatsheetDOM.style.display = "none";
	else
		cheatsheetDOM.style.display = "block";
}

function updatePreviewArea() {
	document.getElementById("content_render").innerHTML = convert(document.getElementById("post_content").value)
}