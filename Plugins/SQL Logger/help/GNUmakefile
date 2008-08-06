HTML_FILES := index.html technical.html \
	      performance.html install.html

deploy: $(HTML_FILES)

clean:
	rm -f $(HTML_FILES)

$(HTML_FILES): index.jsp

%.html: %.xml
	wget -O $@ "http://www.visualdistortion.org/sqllogger/index.jsp?page=$<&mode=html"
