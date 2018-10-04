.PHONY:	rpm clean

PWD = $(shell pwd)
BLD=$(PWD)/build

VERSION ?= 3.4.12
BUILD_NUMBER ?= 5 

SOURCE = zookeeper-$(VERSION).tar.gz
URL = $(shell curl -s https://www.apache.org/dyn/closer.cgi/zookeeper/zookeeper-$(VERSION)/zookeeper-$(VERSION).tar.gz?asjson=1 \
	| python -c 'import sys,json; data=json.load(sys.stdin); print(data["preferred"] + data["path_info"])')

clean:
	rm -rf $(BLD)
	rm -rf zookeeper-$(VERSION).tar.gz.asc KEYS

rpm: $(SOURCE) zkauth
	mkdir -p $(BLD)/SOURCES
	mkdir -p $(BLD)/SRPMS
	mkdir -p $(BLD)/RPMS
	mkdir -p $(BLD)/BUILD
	mkdir -p $(BLD)/BUILDROOT
	mv -v zookeeper-$(VERSION).tar.gz $(BLD)/SOURCES
	cp -v zookeeper-authorizers.jar $(BLD)/SOURCES/
	rpmbuild -bb \
           		--define "_topdir $(BLD)" \
			--define "_sourcedir $(PWD)" \
			--define "version $(VERSION)" \
			--define "build_number $(BUILD_NUMBER)" \
			zookeeper.spec

source: $(SOURCE)

$(SOURCE): KEYS $(SOURCE).asc
	@wget -q $(URL)
	gpg --verify $(SOURCE).asc $(SOURCE)

$(SOURCE).asc:
	@wget -q https://dist.apache.org/repos/dist/release/zookeeper/zookeeper-$(VERSION)/$(SOURCE).asc

KEYS:
	@wget -q https://dist.apache.org/repos/dist/release/zookeeper/KEYS
	gpg --import KEYS

zkauth:
	cp -v ../../zookeeper-authorizers/build/libs/zookeeper-authorizers.jar .

install_rpm:
	[ ! -z $(rpm_install_dir) ] || echo must run make rpm_install_dir=...
	mkdir -p $(rpm_install_dir)
	rsync -r $(BLD)/RPMS $(rpm_install_dir)
	rsync -r $(BLD)/SRPMS $(rpm_install_dir)	
