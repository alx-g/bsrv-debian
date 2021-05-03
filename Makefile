PKGNAME=bsrv
VERSION=0.0.3
SHA256SUM=5ebee0782b0434f14f9a7e8208423990835713b2892d01fdb246dfd333950fd4
BUILD_DIR=./build/
ARCHIVE_FILE=$(BUILD_DIR)$(PKGNAME)-$(VERSION).tar.gz
ARCHIVE_DIR=$(BUILD_DIR)$(PKGNAME)-$(VERSION)
DEB_DIR=$(BUILD_DIR)$(PKGNAME)_$(VERSION)-1_any
PACKAGE=$(BUILD_DIR)$(PKGNAME)_$(VERSION)-1_any.deb

COPYRIGHTFILE="$(DEB_DIR)"/usr/share/doc/$(PKGNAME)/copyright

.DEFAULT_GOAL:=$(PACKAGE)
.PHONY:=clean

$(ARCHIVE_FILE):
	mkdir $(BUILD_DIR)
	wget -O "$(ARCHIVE_FILE)" https://github.com/alx-g/$(PKGNAME)/archive/refs/tags/v$(VERSION).tar.gz
	
checksums: $(ARCHIVE_FILE)
	echo "$(SHA256SUM)  $(ARCHIVE_FILE)" > $(BUILD_DIR)checksums
	sha256sum -c $(BUILD_DIR)checksums || (rm $(BUILD_DIR)checksums && exit 1)

$(ARCHIVE_DIR): $(ARCHIVE_FILE) checksums
	tar xzf "$(ARCHIVE_FILE)" -C $(BUILD_DIR)
	# Setup all absolute paths in shell scripts
	sed -i "s|{{INSTALL_DIR}}|/usr/lib/$(PKGNAME)|g" "$(ARCHIVE_DIR)"/src/bsrvd.sh
	sed -i "s|{{INSTALL_DIR}}|/usr/lib/$(PKGNAME)|g" "$(ARCHIVE_DIR)"/src/bsrvstatd.sh
	sed -i "s|{{INSTALL_DIR}}|/usr/lib/$(PKGNAME)|g" "$(ARCHIVE_DIR)"/src/bsrvcli.sh
	sed -i "s|{{INSTALL_DIR}}|/usr/lib/$(PKGNAME)|g" "$(ARCHIVE_DIR)"/src/bsrvtray.sh
	sed -i "s|{{PKGDIR}}||g" "$(ARCHIVE_DIR)/configs/systemd/bsrvd.service"
	sed -i "s|{{PKGDIR}}||g" "$(ARCHIVE_DIR)/configs/systemd/bsrvstatd.service"

$(DEB_DIR): $(ARCHIVE_DIR)
	mkdir -p "$(DEB_DIR)/DEBIAN"
	chmod 755 "$(DEB_DIR)/DEBIAN"
	install -Dm755 control "$(DEB_DIR)/DEBIAN/"
	install -Dm755 postinst "$(DEB_DIR)/DEBIAN/"
	install -Dm755 prerm "$(DEB_DIR)/DEBIAN/"
	install -Dm755 postrm "$(DEB_DIR)/DEBIAN/"

	# Install dbus and systemd config files
	install -Dm644 $(ARCHIVE_DIR)/configs/dbus/de.alxg.bsrvd.conf "$(DEB_DIR)"/usr/share/dbus-1/system.d/de.alxg.bsrvd.conf
	install -Dm644 $(ARCHIVE_DIR)/configs/dbus/de.alxg.bsrvd.service "$(DEB_DIR)"/usr/share/dbus-1/system-services/de.alxg.bsrvd.service
	install -Dm644 $(ARCHIVE_DIR)/configs/systemd/bsrvd.service "$(DEB_DIR)"/usr/lib/systemd/system/bsrvd.service
	install -Dm644 $(ARCHIVE_DIR)/configs/systemd/bsrvstatd.service "$(DEB_DIR)"/usr/lib/systemd/system/bsrvstatd.service

	# Install BSD 3-clause LICENSE
	install -Dm644 $(ARCHIVE_DIR)/LICENSE $(COPYRIGHTFILE)
	@echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/" > $(COPYRIGHTFILE)
	@echo "Upstream-Name: $(PKGNAME)" >> $(COPYRIGHTFILE)
	@echo "" >> $(COPYRIGHTFILE)
	@echo "Files: *" >> $(COPYRIGHTFILE)
	@echo "Copyright: 2021, Alexander Grathwohl." >> $(COPYRIGHTFILE)
	@echo "License: BSD-3-clause" >> $(COPYRIGHTFILE)

	# Install bsrv software files
	mkdir -p "$(DEB_DIR)/usr/lib/$(PKGNAME)"
	cp "$(ARCHIVE_DIR)/src/bsrv" "$(DEB_DIR)/usr/lib/$(PKGNAME)/" -r
	cp "$(ARCHIVE_DIR)/src/bsrvd" "$(DEB_DIR)/usr/lib/$(PKGNAME)/" -r
	cp "$(ARCHIVE_DIR)/src/bsrvstatd" "$(DEB_DIR)/usr/lib/$(PKGNAME)/" -r
	cp "$(ARCHIVE_DIR)/src/bsrvcli" "$(DEB_DIR)/usr/lib/$(PKGNAME)/" -r
	cp "$(ARCHIVE_DIR)/src/bsrvd.sh" "$(DEB_DIR)/usr/lib/$(PKGNAME)/"
	cp "$(ARCHIVE_DIR)/src/bsrvstatd.sh" "$(DEB_DIR)/usr/lib/$(PKGNAME)/"
	cp "$(ARCHIVE_DIR)/src/bsrvcli.sh" "$(DEB_DIR)/usr/lib/$(PKGNAME)/"
	cp "$(ARCHIVE_DIR)/src/requirements.txt" "$(DEB_DIR)/usr/lib/$(PKGNAME)/"
	chmod 755 "$(DEB_DIR)/usr/lib/$(PKGNAME)/bsrvd.sh"
	chmod 755 "$(DEB_DIR)/usr/lib/$(PKGNAME)/bsrvstatd.sh"
	chmod 755 "$(DEB_DIR)/usr/lib/$(PKGNAME)/bsrvcli.sh"
	chmod 755 "$(DEB_DIR)/usr/lib/$(PKGNAME)"

	# make venv dir so dpkg knows about it
	mkdir "$(DEB_DIR)/usr/lib/$(PKGNAME)/venv"

	# Touch /usr/bin symlinks so dpkg knows about them
	mkdir "$(DEB_DIR)/usr/bin"
	touch "$(DEB_DIR)/usr/bin/bsrvd"
	touch "$(DEB_DIR)/usr/bin/bsrvstatd"
	touch "$(DEB_DIR)/usr/bin/bsrvcli"

$(PACKAGE): $(DEB_DIR)
	dpkg-deb --build --root-owner-group "$(DEB_DIR)"

clean:
	-rm -r $(BUILD_DIR)

install: $(PACKAGE)
	sudo apt install $(PACKAGE)

uninstall:
	sudo apt purge $(PKGNAME)
