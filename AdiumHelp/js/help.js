// Help related scripts

// Display nav bar on pre 10.7 systems
if (parseInt(/Mac OS X 10_([^\s]+)/.exec(navigator.appVersion)[1]) < 7) { 
	var nav = document.getElementById("nav");
	if (nav == null) {nav = document.getElementById("banner");}
	if (nav != null) {nav.style.display = "block";}
	
	var main = document.getElementById("mainbox");
	if (main != null) {main.style.marginTop = "40px";}
}