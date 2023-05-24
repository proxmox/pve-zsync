include /usr/share/dpkg/pkg-info.mk

PACKAGE=pve-zsync

DESTDIR=
SBINDIR=$(DESTDIR)/usr/sbin
MAN8DIR=$(DESTDIR)/usr/share/man/man8
DOCDIR=$(DESTDIR)/usr/share/doc/$(PACKAGE)
WORKDIR=$(DESTDIR)/var/lib/pve-zsync

BUILDDIR ?= $(PACKAGE)-$(DEB_VERSION_UPSTREAM)

GITVERSION:=$(shell git rev-parse HEAD)

DEB=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)_all.deb
DSC=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION).dsc

all:

.PHONY: dinstall
dinstall: deb
	dpkg -i $(DEB)

pve-zsync.8: pve-zsync
	./pve-zsync printpod | pod2man -c "Proxmox Documentation" -s 8 -r $(DEB_VERSION_UPSTREAM) -n pve-zsync - pve-zsync.8

.PHONY: install
install: pve-zsync.8
	install -d $(SBINDIR)
	install -m 0755 pve-zsync $(SBINDIR)/pve-zsync
	install -d $(WORKDIR)
	install -d $(MAN8DIR)
	install -m 0644 pve-zsync.8 $(MAN8DIR)/pve-zsync.8
	install -d $(DOCDIR)

$(BUILDDIR):
	rm -rf $@.tmp $@
	rsync -a * $@.tmp
	echo "git clone git://git.proxmox.com/git/dab.git\\ngit checkout $(GITVERSION)" > $@.tmp/debian/SOURCE
	mv $@.tmp $@

.PHONY: deb
deb: $(DEB)
$(DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -b -us -uc
	lintian $(DEB)

.PHONY: dsc
dsc: $(DSC)
$(DSC):$(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -S -us -uc -d -nc
	lintian $(DSC)

sbuild: $(DSC)
	sbuild $(DSC)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) *.deb *.dsc $(PACKAGE)*.tar.gz *.buildinfo *.changes
	find . -name '*~' -exec rm {} ';'

.PHONY: distclean
distclean: clean


.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEB)
	tar cf - $(DEB) | ssh repoman@repo.proxmox.com upload --product pve --dist $(UPLOAD_DIST)
