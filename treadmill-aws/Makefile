# Makefile for Treadmill rpm.

PWD=$(shell pwd)

BLD=$(PWD)/build
RPMDIR=$(BLD)/rpms
VENV=$(RPMDIR)/BUILD/opt/treadmill
WHEELS=$(BLD)/wheels

# Point to root of Treadmill and Treadmill-AWS repos.
TREADMILL_DIR=$(PWD)/../../treadmill
TREADMILL_AWS_DIR=$(PWD)/../../treadmill-aws

clean:
	rm -rf $(BLD)

venv: $(VENV)/bin/activate

$(VENV)/bin/activate:
	mkdir -p $(VENV)
	virtualenv-3 $(VENV)                 \
		&& source $(VENV)/bin/activate   \
		&& pip install -U setuptools pip
	virtualenv-3 --relocatable $(VENV)

wheels: venv
	source $(VENV)/bin/activate                                       \
		&& cd $(TREADMILL_DIR)                                        \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS) \
		&& cd $(TREADMILL_AWS_DIR)                                    \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS)

sbin: \
	$(VENV)/sbin/start_node.sh \
	$(VENV)/sbin/start_master.sh

$(VENV)/sbin/%.sh: ./sbin/%.sh
	install -D $< $@

install: venv sbin
	source $(VENV)/bin/activate         \
		&& pip install -f $(WHEELS)     \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		     kazoo[sasl]==2.4.0.dev0 Treadmill Treadmill_AWS
	virtualenv-3 --relocatable $(VENV)

rpm:
	mkdir -p $(RPMDIR)/SOURCES
	mkdir -p $(RPMDIR)/SRPMS
	mkdir -p $(RPMDIR)/RPMS
	mkdir -p $(RPMDIR)/BUILD
	mkdir -p $(RPMDIR)/BUILDROOT
	rpmbuild -bb                                                     \
		-D "__python $(RPMDIR)/BUILDROOT/opt/treadmill/bin/python"   \
		-D "_topdir $(RPMDIR)"                                       \
		treadmill-aws.spec

.PHONY: sbin
