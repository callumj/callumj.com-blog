function toggleCheetSheet() {
	cheatsheetDOM = document.getElementById("cheatsheet");
	if (cheatsheetDOM == null)
		return;
	if (cheatsheetDOM.style.display != "none")
		cheatsheetDOM.style.display = "none";
	else
		cheatsheetDOM.style.display = "block";
}