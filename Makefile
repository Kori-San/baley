PREFIX = /usr
SHELL := /bin/bash

all:
	@echo make: Run \'make install\' to install Baley.
	@echo make: Run \'make uninstall\' to uninstall Baley.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p baley.sh $(DESTDIR)$(PREFIX)/bin/baley
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/baley
	@./.sub-config.sh
	@echo make: Baley installed to \'$(DESTDIR)$(PREFIX)/bin/baley\'
	@echo make: You can now run \'$ baley\' to use Baley.

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/baley
	@echo make: Baley uninstalled.
