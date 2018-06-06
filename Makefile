RELEASE=5.0

VERSION=1.6
PACKAGE=pve-zsync
PKGREL=16

DESTDIR=
SBINDIR=${DESTDIR}/usr/sbin
MAN8DIR=${DESTDIR}/usr/share/man/man8
DOCDIR=${DESTDIR}/usr/share/doc/${PACKAGE}
WORKDIR=${DESTDIR}/var/lib/pve-zsync

BUILDDIR=build

ARCH=all
GITVERSION:=$(shell git rev-parse HEAD)

DEB=${PACKAGE}_${VERSION}-${PKGREL}_${ARCH}.deb

all:

.PHONY: dinstall
dinstall: deb
	dpkg -i ${DEB}

pve-zsync.8: pve-zsync
	./pve-zsync printpod | pod2man -c "Proxmox Documentation" -s 8 -r ${RELEASE} -n pve-zsync - pve-zsync.8

.PHONY: install
install: pve-zsync.8
	install -d ${SBINDIR}
	install -m 0755 pve-zsync ${SBINDIR}/pve-zsync
	install -d ${WORKDIR}
	install -d ${MAN8DIR}
	install -m 0644 pve-zsync.8 ${MAN8DIR}/pve-zsync.8
	install -d ${DOCDIR}
	echo "git clone git://git.proxmox.com/git/pve-zsync.git\\ngit checkout ${GITVERSION}" > ${DOCDIR}/SOURCE

.PHONY: deb
deb: ${DEB}
${DEB}:
	rm -rf ${BUILDDIR}
	rsync -a * build
	cd build; dpkg-buildpackage -b -us -uc
	lintian ${DEB}

.PHONY: clean
clean:
	rm -rf ${BUILDDIR} *.deb *.buildinfo *.changes
	find . -name '*~' -exec rm {} ';'

.PHONY: distclean
distclean: clean


.PHONY: upload
upload: ${DEB}
	tar cf - ${DEB} | ssh repoman@repo.proxmox.com upload --product pve --dist stretch
