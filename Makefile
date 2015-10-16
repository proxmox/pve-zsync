RELEASE=4.0

VERSION=1.6
PACKAGE=pve-zsync
PKGREL=2

DESTDIR=
PREFIX=/usr
BINDIR=${PREFIX}/bin
SBINDIR=${PREFIX}/sbin
MANDIR=${PREFIX}/share/man
DOCDIR=${PREFIX}/share/doc/${PACKAGE}
PODDIR=${DOCDIR}/pod
MAN1DIR=${MANDIR}/man8/

#ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
ARCH=all
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=${PACKAGE}_${VERSION}-${PKGREL}_${ARCH}.deb

all: ${DEB}

.PHONY: dinstall
dinstall: deb
	dpkg -i ${DEB}

%.8.gz: %.8.man
	rm -f $@
	gzip pve-zsync.8.man -c9 >$@

pve-zsync.8.man: pve-zsync
	pod2man -c "Proxmox Documentation" -s 8 -r ${RELEASE} -n pve-zsync  pve-zsync pve-zsync.8.man

.PHONY: install
install: pve-zsync.8.man pve-zsync.8.gz
	install -d ${DESTDIR}${SBINDIR}
	install -m 0755 pve-zsync ${DESTDIR}${SBINDIR}
	install -d ${DESTDIR}/usr/share/man/man8
	install -d ${DESTDIR}${PODDIR}
	install -m 0644 pve-zsync.8.gz ${DESTDIR}/usr/share/man/man8/

.PHONY: deb ${DEB}
deb ${DEB}:
	rm -rf debian
	mkdir debian
	install -d debian/var/lib/pve-zsync
	make DESTDIR=${CURDIR}/debian install
	install -d -m 0755 debian/DEBIAN
	sed -e s/@@VERSION@@/${VERSION}/ -e s/@@PKGRELEASE@@/${PKGREL}/ -e s/@@ARCH@@/${ARCH}/ <control.in >debian/DEBIAN/control
	install -D -m 0644 copyright debian/${DOCDIR}/copyright
	install -m 0644 changelog.Debian debian/${DOCDIR}/
	gzip -9 debian/${DOCDIR}/changelog.Debian
	echo "git clone git://git.proxmox.com/git/pve-storage.git\\ngit checkout ${GITVERSION}" > debian/${DOCDIR}/SOURCE
	dpkg-deb --build debian
	mv debian.deb ${DEB}
	rm -rf debian

.PHONY: clean
clean:
	rm -rf debian *.deb ${PACKAGE}-*.tar.gz dist *.8.man *.8.gz
	find . -name '*~' -exec rm {} ';'

.PHONY: distclean
distclean: clean


.PHONY: upload
upload: ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro
