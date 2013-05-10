# $rtool: Makefile,v 1.01 2007/11/28 23:25:01 mmw Exp $

PREFIX  = /usr/local
MANDIR = $(PREFIX)/share/man/man1

RM = rm -f
INSTALL_PROG = install -m 755
INSTALL_MAN = install -m 644

DISTFILES = Makefile ReadMe Resources Version.plist rtool rtool.1
TAR = tar
GZIP = gzip
PACKAGE = rtool
SRCVERSION = 1.2.5

EXE = rtool
MAN = rtool.1

install : $(EXE)
	$(INSTALL_PROG) $(EXE) $(PREFIX)/bin
	$(INSTALL_MAN) $(MAN) $(MANDIR)
	
uninstall :
	$(RM) $(PREFIX)/bin/$(EXE)
	$(RM) $(MANDIR)/$(MAN)	

dist: ${DISTFILES}
	@rm -f `find . -name '.DS_Store'`
	rm -f `find . -name '._*'`
	@rm -f `find . -name '.gdb_history'`
	@mkdir -p $(PACKAGE)-$(SRCVERSION)
	@$(TAR) --exclude=.svn -cvf $(PACKAGE)-$(SRCVERSION).tar ${DISTFILES}
	cd $(PACKAGE)-$(SRCVERSION) && $(TAR) --exclude=.svn -xf ../$(PACKAGE)-$(SRCVERSION).tar && cd ..
	@rm $(PACKAGE)-$(SRCVERSION).tar
	@$(TAR) --exclude=.svn -cvf $(PACKAGE)-$(SRCVERSION).tar $(PACKAGE)-$(SRCVERSION)
	@rm -rf $(PACKAGE)-$(SRCVERSION)
	@$(GZIP) -9 $(PACKAGE)-$(SRCVERSION).tar
	@openssl sha1 $(PACKAGE)-$(SRCVERSION).tar.gz > $(PACKAGE)-$(SRCVERSION).sha1
	
	
# EOF	