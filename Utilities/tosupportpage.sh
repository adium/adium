#!/bin/sh

# Usage: tosupportpage path/to/www/help

# This very ugly script adds a header and footer to each help page, makes sure
# the formatting is consistent etc. to incorperate them in the Adium website.
# Give it a path to /help/ in a checkout of http://hg.adium.im/www/adium.im/.

if [ $# -ne 1 ]
then
	echo "Usage: $0 path/to/www/help"
	exit -1
fi

mkdir -p $1

for file in ../AdiumHelp/pgs/*; do
cat "$file" \
| sed 's|</head>|<link href="../css/common.css" type="text/css" rel="stylesheet" media="all" />\
<link rel="stylesheet" type="text/css" href="../../styles/layoutstyle.css" />\
<link rel="stylesheet" type="text/css" href="../../styles/defaultstyle.css" />\
</head>|g' \
| sed 's|<body>|<body>\
<div id="container">\
		<div id="titlecontainer"> \
			<a href="/">Adium</a> \
        </div> \
		<div id="navcontainer"> \
			<a class="navtab" href="http://adium.im/">Download</a> \
			<a class="navtab" href="http://adium.im/about">About</a>\
			<a class="navtab" href="http://adium.im/blog/">Blog</a> \
			<a class="navtabcurrent" href="http://adium.im/help">Help</a> \
			<a class="navtab" href="http://trac.adium.im">Development</a> \
			<a class="navtab" href="http://adium.spreadshirt.com">Merchandise</a> \
			<a class="navtab" href="http://www.adiumxtras.com/">Xtras</a> \
		</div>|g' \
		| sed 's|</body>|	<div id="footer">					<div class="donate"> \
									<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;submit.x=57&amp;submit.y=8&amp;encrypted=-----BEGIN+PKCS7-----%0D%0AMIIHFgYJKoZIhvcNAQcEoIIHBzCCBwMCAQExggEwMIIBLAIBADCBlDCBjjELMAkG%0D%0AA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQw%0D%0AEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UE%0D%0AAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJ%0D%0AKoZIhvcNAQEBBQAEgYAFR5tF%2BRKUV3BS49vJraDG%2BIoWDoZMieUT%2FJJ1Fzjsr511%0D%0Au7hS1F2piJuHuqmm%2F0r8Kf8oaycOo74K3zLmUQ6T6hUS6%2Bh6lZAoIlhI3A1YmqIP%0D%0AdrdY%2FtfKRbWfolDumJ9Mdv%2FzJxPnpdQiTN5K1PMrPYE6GgPWE9WC4V9lqstSmTEL%0D%0AMAkGBSsOAwIaBQAwgZMGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQIjtd%2BN9o4ZB6A%0D%0AcIbH8ZjOLmE35xBQ%2F93chtzIcRXHhIQJVpBRCkyJkdTD3libP3F7TgkrLij1DBxg%0D%0AfFlE0V%2FGTk29Ys%2FwsPO7hNs3YSNuSz0HT5F6sa8aXwFtMCE%2FgB1Ha4qdtYY%2BNETJ%0D%0AEETwNMLefjhaBfI%2BnRxl2K2gggOHMIIDgzCCAuygAwIBAgIBADANBgkqhkiG9w0B%0D%0AAQUFADCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3Vu%0D%0AdGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9j%0D%0AZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBh%0D%0AbC5jb20wHhcNMDQwMjEzMTAxMzE1WhcNMzUwMjEzMTAxMzE1WjCBjjELMAkGA1UE%0D%0ABhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYD%0D%0AVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQI%0D%0AbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wgZ8wDQYJKoZI%0D%0AhvcNAQEBBQADgY0AMIGJAoGBAMFHTt38RMxLXJyO2SmS%2BNdl72T7oKJ4u4uw%2B6aw%0D%0AntALWh03PewmIJuzbALScsTS4sZoS1fKciBGoh11gIfHzylvkdNe%2FhJl66%2FRGqrj%0D%0A5rFb08sAABNTzDTiqqNpJeBsYs%2Fc2aiGozptX2RlnBktH%2BSUNpAajW724Nv2Wvhi%0D%0Af6sFAgMBAAGjge4wgeswHQYDVR0OBBYEFJaffLvGbxe9WT9S1wob7BDWZJRrMIG7%0D%0ABgNVHSMEgbMwgbCAFJaffLvGbxe9WT9S1wob7BDWZJRroYGUpIGRMIGOMQswCQYD%0D%0AVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDAS%0D%0ABgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQD%0D%0AFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbYIBADAMBgNV%0D%0AHRMEBTADAQH%2FMA0GCSqGSIb3DQEBBQUAA4GBAIFfOlaagFrl71%2Bjq6OKidbWFSE%2B%0D%0AQ4FqROvdgIONth%2B8kSK%2F%2FY%2F4ihuE4Ymvzn5ceE3S%2FiBSQQMjyvb%2Bs2TWbQYDwcp1%0D%0A29OPIbD9epdr4tJOUNiSojw7BHwYRiPh58S1xGlFgHFXwrEBb3dgNbMUa%2Bu4qect%0D%0AsMAXpVHnD9wIyfmHMYIBmjCCAZYCAQEwgZQwgY4xCzAJBgNVBAYTAlVTMQswCQYD%0D%0AVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFs%0D%0AIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRww%0D%0AGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMAkGBSsOAwIaBQCgXTAYBgkq%0D%0AhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wNDAzMjUwNDQ0%0D%0AMzRaMCMGCSqGSIb3DQEJBDEWBBRzTAS6zk5cmMeC49IorY8CM%2BkX0TANBgkqhkiG%0D%0A9w0BAQEFAASBgBsyRfMv9mSyoYq00wIB7BmUHFGq5x%2Ffnr8M24XbKjhkyeULk2NC%0D%0As4jbCgaWNg6grvccJtjbvmDskMKt%2BdS%2BEAkeWwm1Zf%2F%2B5u1fMyb5vo1NNcRIs5oq%0D%0A7SvXiLTPRzVqzQdhVs7PoZG0i0RRIb0tMeo1IssZeB2GE5Nsg0D8PwpB%0D%0A-----END+PKCS7-----"> \
									Donate to Adium</a> \
									</div> \
								<div id="powered" style="opacity: 100%"> \
									<a href="http://developer.apple.com/ada"><img class="libgaim" src="../../images/ada.png" alt="Apple design awards 05 special mention"></a> \
									<a href="http://www.pidgin.im"><img class="libgaim" src="../../images/powered_by_libpurple.png" alt="Adium is powered by libpurple"></a> \
									<a class="cachefly" href="http://www.cachefly.com"><img src="../../images/cachefly.png" alt="CacheFly Logo"></a> \
									<a class="networkredux" href="http://www.networkredux.com"><img src="../../images/network_redux.png" alt="Network Redux Logo"></a> \
								</div> \
							</div> \
			</body>|g' \
			| sed 's|<a class="navleftsty" href="../AdiumHelp.html">Adium Help</a> <a class="navleftsty" href="AdiumDocumentation.html">Adium Documentation</a>|<a class="navleftsty" href="../">Adium Help</a> <a class="navleftsty" href="http://adium.im/screencasts/">Adium Videos</a> <a class="navleftsty active" href="AdiumDocumentation.html">Adium Documentation</a>|g' \
			| sed 's|</title>| - Adium Documentation</title>|g' \
			| sed 's|<div id="pagetitle">|<div id="pagetitle"> <h3><span itemscope itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/help" itemprop="url"><img src="../gfx/AdiumIcon.png" alt="Adium Icon" height="32" width="32" border="0" /><span itemprop="title">Adium Help</span></a></span> \&gt; <span itemscope itemtype="http://data-vocabulary.org/Breadcrumb"><a href="AdiumDocumentation.html" itemprop="url"><span itemprop="title">Adium Documentation</span></a></span> \&gt; </h3> |g' \
			 > "$1/pgs/$(basename $file)"
done

find ../AdiumHelp/gfx/ -type f|while read file
do
cp -v "$file" "$1/gfx/${file##*/}"
done