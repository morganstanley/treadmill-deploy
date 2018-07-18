# Makefile for Treadmill rpm.

PWD=$(shell pwd)

BLD=$(PWD)/build
RPMDIR=$(BLD)/rpms
VENV=$(RPMDIR)/BUILD/opt/treadmill
WHEELS=$(BLD)/wheels

# Point to root of Treadmill and Treadmill-AWS repos.
TREADMILL_DIR=$(PWD)/../../treadmill
TREADMILL_AWS_DIR=$(PWD)/../../treadmill-aws

REPO_TAG=$(shell git --git-dir=${TREADMILL_AWS_DIR}/.git describe --tags HEAD --long)
REPO_TAGFMT=$(shell echo ${REPO_TAG} | sed 's/-g/-/')
REPO_VER=$(shell echo ${REPO_TAGFMT} | cut -d '-' -f 1)
REPO_REL=$(shell echo ${REPO_TAGFMT} | cut -d '-' -f 2,3 | sed 's/-/_/')

clean:
	rm -rf $(BLD)

venv: $(VENV)/bin/activate

$(VENV)/bin/activate:
	mkdir -p $(VENV)
	virtualenv-3 $(VENV)                 \
		&& source $(VENV)/bin/activate   \
		&& pip install --no-cache-dir --no-index --find-links $(WHEELS) -U setuptools pip
	virtualenv-3 --relocatable $(VENV)

wheels: venv
	source $(VENV)/bin/activate                                       \
		&& cd $(TREADMILL_DIR)                                        \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS) \
		&& cd $(TREADMILL_AWS_DIR)                                    \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS)

wheels_cache:
	aws s3 sync $(S3_WHEELS_CACHE) $(WHEELS)

sbin: \
	$(VENV)/sbin/opts.sh \
	$(VENV)/sbin/start.sh \
	$(VENV)/sbin/start_node.sh \
	$(VENV)/sbin/start_master.sh

$(VENV)/sbin/%.sh: ./sbin/%.sh
	install -D $< $@

install: venv sbin
	source $(VENV)/bin/activate         \
		&& pip install --no-cache-dir  -f $(WHEELS)  \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		     kazoo[sasl]==2.4.0.dev0    \
		&& pip install --no-cache-dir  -f $(WHEELS)  \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		    $(TREADMILL_DIR)            \
		&& pip install --no-cache-dir  -f $(WHEELS)  \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		    $(TREADMILL_AWS_DIR)
	virtualenv-3 --relocatable $(VENV)
	sed -i "s^$(RPMDIR)/BUILD/opt/treadmill^/opt/treadmill^g" \
		$(RPMDIR)/BUILD/opt/treadmill/bin/activate*
	cp service/*.service $(RPMDIR)/BUILD

rpm: clean wheels_cache install
	mkdir -p $(RPMDIR)/SOURCES
	mkdir -p $(RPMDIR)/SRPMS
	mkdir -p $(RPMDIR)/RPMS
	mkdir -p $(RPMDIR)/BUILD
	mkdir -p $(RPMDIR)/BUILDROOT
	rpmbuild -bb                                                     \
		-D "__python $(RPMDIR)/BUILDROOT/opt/treadmill/bin/python"   \
		-D "_topdir $(RPMDIR)"                                       \
		-D "_version $(REPO_VER)"                             \
		-D "_release $(REPO_REL)"                             \
		treadmill-aws.spec

install_rpm:
	[ ! -z $(rpm_install_dir) ] || echo must run make rpm_install_dir=...
	mkdir -p $(rpm_install_dir)
	rsync -r $(RPMDIR)/RPMS $(rpm_install_dir)
	rsync -r $(RPMDIR)/SRPMS $(rpm_install_dir)

i:
	@echo "BLD           : $(BLD)"
	@echo "RPMDIR        : $(RPMDIR)"
	@echo "VENV          : $(VENV)"
	@echo "WHEELS        : $(WHEELS)"
	@echo "REPO_VER      : $(REPO_VER)"
	@echo "REPO_TAG      : $(REPO_TAG)"

.PHONY: sbin
