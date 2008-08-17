function isGecko() {
    var agent = navigator.userAgent.toLowerCase();
    if (agent.indexOf("gecko") != -1) {
        return true;
    }
    return false;
}

if (isGecko()) {
      document.write('<style type="text/css" media="screen">@import "layout/css/geckofixes.css";</style>\n');
}
