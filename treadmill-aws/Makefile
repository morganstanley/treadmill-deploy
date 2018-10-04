# Makefile for Treadmill rpm.

PWD=$(shell pwd)

BLD=$(PWD)/build
RPMDIR=$(BLD)/rpms
VENV=$(RPMDIR)/BUILD/opt/treadmill
VENV_SEED=$(BLD)/venv-seed
WHEELS=$(BLD)/wheels

USE_CACHE=0

# Point to root of Treadmill and Treadmill-AWS repos.
TREADMILL_DIR=$(PWD)/../../treadmill
TREADMILL_AWS_DIR=$(PWD)/../../treadmill-aws

TREADMILL_BUILD_N=$(shell git --git-dir ${TREADMILL_DIR}/.git rev-list --count HEAD)
TREADMILL_AWS_BUILD_N=$(shell git --git-dir ${TREADMILL_AWS_DIR}/.git rev-list --count HEAD)
TREADMILL_DEPLOY_BUILD_N=$(shell git rev-list --count HEAD)

TREADMILL_DESCRIBE=$(shell git --git-dir=${TREADMILL_DIR}/.git describe --tags HEAD --long)
TREADMILL_AWS_DESCRIBE=$(shell git --git-dir=${TREADMILL_AWS_DIR}/.git describe --tags HEAD --long)
TREADMILL_DEPLOY_DESCRIBE=$(shell git describe --tags HEAD --long)

REPO_UNIQ=$(shell echo ${TREADMILL_DESCRIBE}.${TREADMILL_AWS_DESCRIBE}.${TREADMILL_DEPLOY_DESCRIBE} | md5sum - | cut -d ' ' -f 1 | tail -c 9)

REPO_TAG=$(shell git --git-dir=${TREADMILL_AWS_DIR}/.git describe --tags HEAD --long)
REPO_TAGFMT=$(shell echo ${REPO_TAG} | sed 's/-g/-/')
REPO_VER=$(shell echo ${REPO_TAGFMT} | cut -d '-' -f 1)

TOTAL_COMMITS=$(shell echo $$(( ${TREADMILL_BUILD_N} + ${TREADMILL_AWS_BUILD_N} + ${TREADMILL_DEPLOY_BUILD_N} )) )
REPO_REL=${TOTAL_COMMITS}_${REPO_UNIQ}

PYTHON=$(shell which python3 2> /dev/null || which python34 2> /dev/null || which python36 2> /dev/null)

clean:
	rm -rf $(BLD)

ifeq ($(USE_CACHE),0)

venv: $(VENV)/bin/activate

$(VENV)/bin/activate:
	mkdir -p $(VENV)
	$(PYTHON) -mvenv $(VENV_SEED)
	$(VENV_SEED)/bin/python -mpip install --upgrade \
		pip==10.0 setuptools wheel virtualenv
	$(VENV_SEED)/bin/virtualenv $(VENV)

wheels: venv
	source $(VENV)/bin/activate                                           \
		&& pip install -U pip==10.0 wheel setuptools virtualenv       \
		&& cd $(TREADMILL_DIR)                                        \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS) \
		&& cd $(TREADMILL_AWS_DIR)                                    \
		&& $(TREADMILL_DIR)/scripts/setup_wheel_cache.sh -w $(WHEELS)

s3:
	aws s3 sync $(WHEELS) $(S3_WHEELS_CACHE) --delete

else

wheels:
	aws s3 sync $(S3_WHEELS_CACHE) $(WHEELS)
	$(PYTHON) -mvenv $(VENV_SEED)
	$(VENV_SEED)/bin/python -mpip install -f $(WHEELS) \
    		--no-cache-dir                             \
    		--no-index                                 \
			--upgrade                                  \
		pip==10.0 wheel setuptools virtualenv
	$(VENV_SEED)/bin/virtualenv $(VENV)
			
endif

sbin: \
	$(VENV)/sbin/opts.sh \
	$(VENV)/sbin/start.sh \
	$(VENV)/sbin/start_node.sh \
	$(VENV)/sbin/start_openldap.sh \
	$(VENV)/sbin/start_zookeeper.sh

$(VENV)/sbin/%.sh: ./sbin/%.sh
	install -D $< $@

install: wheels sbin
	$(VENV)/bin/python -mpip install --no-cache-dir -f $(WHEELS) \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		     kazoo[sasl]==2.4.0.dev0
	$(VENV)/bin/python -mpip install --no-cache-dir -f $(WHEELS) \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		    $(TREADMILL_DIR)
	$(VENV)/bin/python -mpip install --no-cache-dir -f $(WHEELS) \
		    --only-binary               \
		    --no-cache-dir              \
		    --no-index                  \
		    $(TREADMILL_AWS_DIR)
	$(VENV_SEED)/bin/virtualenv --relocatable $(VENV)
	sed -i "s^$(RPMDIR)/BUILD/opt/treadmill^/opt/treadmill^g" \
		$(RPMDIR)/BUILD/opt/treadmill/bin/activate*

rpm: clean install
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
	@echo "PYTHON        : $(PYTHON)"
	@echo "BLD           : $(BLD)"
	@echo "RPMDIR        : $(RPMDIR)"
	@echo "VENV          : $(VENV)"
	@echo "WHEELS        : $(WHEELS)"
	@echo "REPO_VER      : $(REPO_VER)"
	@echo "REPO_REL      : $(REPO_REL)"
	@echo "REPO_TAG      : $(REPO_TAG)"
	@echo "REPO_UNIQ     : $(REPO_UNIQ)"
	@echo "USE_CACHE     : $(USE_CACHE)"

.PHONY: sbin
