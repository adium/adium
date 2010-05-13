	var highlightActive = false;

	function selectSender() {
		if (highlightActive || event.target.tagName.toLowerCase() == 'a')
			return;
		highlightActive = true;
		var node = event.target;
		var senderName = null;
		while (!senderName) {
			var nodeClass = node.className;
			if (/(^|[\s])message/.test(nodeClass)) {
				var parts = nodeClass.split(" ");
				senderName = parts[parts.length - 1];
			}
			node = node.parentElement;
		}
		var elms = document.getElementsByClassName(senderName); var elemArray = new Array(elms.length); for (var i=0; i<elms.length; i++) { elemArray[i]=elms[i]; }
		var len = elemArray.length;
		for(var i = 0; i < len; i++) { 
			elemArray[i].className += ' x-hover';
		} 
	}

	function deselectAll() {
		if (!highlightActive)
			return;
		var elms = document.querySelectorAll(".x-hover");
		var len = elms.length;
		var elm = null;
		for(var i = 0; i < len; i++) { 
			elm = elms[i];
			elm.className = elm.className.replace(' x-hover', ''); 
		}
		highlightActive = false;
	}

	function show_header () {
		document.getElementById('x-wrap').style.opacity = '1';
		document.getElementById('x-show').style.display = 'none';
		document.getElementById('x-hide').style.display = '';
	}

	function hide_header () {
		document.getElementById('x-wrap').style.opacity = '0';
		document.getElementById('x-hide').style.display = 'none';
		document.getElementById('x-show').style.display = '';
	}

	document.body.addEventListener("mousedown", selectSender, false);
	document.body.addEventListener("mouseup", deselectAll, false);
	var htmlElm = document.getElementsByTagName("html")[0];
	document.documentElement.addEventListener("mouseout", function() { if (event.relatedTarget == htmlElm) { deselectAll(); }}, false);
