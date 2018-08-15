# Makefile for socat-server rpm.

PWD=$(shell pwd)

BLD=$(PWD)/build
RPMDIR=$(BLD)/rpms

REPO_VER=1
REPO_REL=0

clean:
	rm -rf $(BLD)

install: 
	mkdir -p $(RPMDIR)/BUILD/opt
	cp -r source/* $(RPMDIR)/BUILD/opt
	cp service/* $(RPMDIR)/BUILD

rpm: clean install
	mkdir -p $(RPMDIR)/SOURCES
	mkdir -p $(RPMDIR)/SRPMS
	mkdir -p $(RPMDIR)/RPMS
	mkdir -p $(RPMDIR)/BUILD
	mkdir -p $(RPMDIR)/BUILDROOT
	rpmbuild -bb                                                  \
		-D "_topdir $(RPMDIR)"                                \
		-D "_version $(REPO_VER)"                             \
		-D "_release $(REPO_REL)"                             \
		socat-server.spec

install_rpm:
	[ ! -z $(rpm_install_dir) ] || echo must run make rpm_install_dir=...
	mkdir -p $(rpm_install_dir)
	rsync -r $(RPMDIR)/RPMS $(rpm_install_dir)
	rsync -r $(RPMDIR)/SRPMS $(rpm_install_dir)

i:
	@echo "BLD           : $(BLD)"
	@echo "RPMDIR        : $(RPMDIR)"
	@echo "REPO_VER      : $(REPO_VER)"
	@echo "REPO_TAG      : $(REPO_TAG)"

