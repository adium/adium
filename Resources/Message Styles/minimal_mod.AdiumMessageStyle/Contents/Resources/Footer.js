// Hide the header when the user scrolls up (using the same calc as nearBottom).
function twiddleHeader() {
	if ( document.body.scrollTop >= ( document.body.offsetHeight - ( window.innerHeight * 1.2 ) ) ) {
		document.getElementById('x-header').style.display = 'block';
	} else {
		document.getElementById('x-header').style.display = 'none';
	}
}

window.addEventListener("scroll", twiddleHeader, false);
