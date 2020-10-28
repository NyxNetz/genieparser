################################################################################
#                                                                              #
#                      Cisco Systems Proprietary Software                      #
#        Not to be distributed without consent from Test Technology            #
#                               Cisco Systems, Inc.                            #
#                                                                              #
################################################################################
#                            genie.libs.parser Internal Makefile
#
# Author:
#   pyats-support@cisco.com
#
# Support:
#   pyats-support@cisco.com
#
# Version:
#   v3.0
#
# Date:
#   November 2018
#
# About This File:
#   This script will build the genie.libs.parser package for
#   distribution in PyPI server
#
# Requirements:
#	1. Module name is the same as package name.
#	2. setup.py file is stored within the module folder
################################################################################

# Variables
PKG_NAME      = genie.libs.parser
BUILD_DIR     = $(shell pwd)/__build__
DIST_DIR      = $(BUILD_DIR)/dist
PROD_USER     = pyadm@pyats-ci
PROD_PKGS     = /auto/pyats/packages
PYTHON        = python
TESTCMD       = runAll --path=$(shell pwd)/tests
BUILD_CMD     = $(PYTHON) setup.py bdist_wheel --dist-dir=$(DIST_DIR)
PYPIREPO      = pypitest
PYLINT_CMD	  = pylintAll
CYTHON_CMD	  = compileAll

# Development pkg requirements
RELATED_PKGS = genie.libs.parser
DEPENDENCIES = xmltodict requests

ifeq ($(MAKECMDGOALS), devnet)
	BUILD_CMD += --devnet
endif

.PHONY: clean package distribute develop undevelop help devnet\
        docs test install_build_deps uninstall_build_deps

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo ""
	@echo "package               Build the package"
	@echo "test                  Test the package"
	@echo "distribute            Distribute the package to internal Cisco PyPi server"
	@echo "clean                 Remove build artifacts"
	@echo "develop               Build and install development package"
	@echo "undevelop             Uninstall development package"
	@echo "docs                  Build Sphinx documentation for this package"
	@echo "devnet                Build DevNet package."
	@echo "install_build_deps    install pyats-distutils"
	@echo "uninstall_build_deps  Remove pyats-distutils"
	@echo "compile		 		 Compile all python modules to c"
	@echo "coverage_all			 Run code coverage on all test files"
	@echo "pylint_all			 Run python linter on all python modules"
	@echo "json					 Build json files"
	@echo "changelogs			 Build compiled changelog file"
	@echo ""
	@echo "     --- build arguments ---"
	@echo " DEVNET=true              build for devnet style (cythonized, no ut)"

compile:
	@echo ""
	@echo "Compiling to C code"
	@echo --------------------------
	$(CYTHON_CMD) 
	@echo "Done Compiling"
	@echo ""

coverage_all:
	@echo ""
	@echo "Running Code coverage on all unittests"
	@echo ---------------------------------------
	@$(TESTCMD) --path tests/ --coverage --no-refresh
	@echo ""

pylint_all:
	@echo ""
	@echo "Running Pylint on all modules"
	@echo "-----------------------------"
	@$(PYLINT_CMD)
	@echo "Done linting"
	@echo ""

devnet: package
	@echo "Completed building DevNet packages"
	@echo ""

install_build_deps:
	@pip install --upgrade pip setuptools wheel

uninstall_build_deps:
	@echo "Nothing to do"

docs:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "No documentation for $(PKG_NAME)"
	@echo ""

test:
	@$(TESTCMD)

package:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Building $(PKG_NAME) distributable: $@"
	@echo ""

	$(BUILD_CMD)

	@echo ""
	@echo "Completed building: $@"
	@echo ""

develop:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Building and installing $(PKG_NAME) development distributable: $@"
	@echo ""

	@pip uninstall -y $(RELATED_PKGS)
	@pip install $(DEPENDENCIES)

	@$(PYTHON) setup.py develop --no-deps

	@echo ""
	@echo "Completed building and installing: $@"
	@echo ""

undevelop:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Uninstalling $(PKG_NAME) development distributable: $@"
	@echo ""

	@$(PYTHON) setup.py develop --no-deps -q --uninstall

	@echo ""
	@echo "Completed uninstalling: $@"
	@echo ""

clean:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Removing make directory: $(BUILD_DIR)"
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo ""
	@echo "Removing build artifacts ..."
	@$(PYTHON) setup.py clean
	@echo ""
	@echo "Done."
	@echo ""

distribute:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Copying all distributable to $(PROD_PKGS)"
	@test -d $(DIST_DIR) || { echo "Nothing to distribute! Exiting..."; exit 1; }
	@ssh -q $(PROD_USER) 'test -e $(PROD_PKGS)/$(PKG_NAME) || mkdir $(PROD_PKGS)/$(PKG_NAME)'
	@scp $(DIST_DIR)/* $(PROD_USER):$(PROD_PKGS)/$(PKG_NAME)/
	@echo ""
	@echo "Done."
	@echo ""

json:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Generating Parser json file"
	@echo ""
	@python -c "from genie.json.make_json import make_genieparser; make_genieparser()"
	@echo ""
	@echo "Done."
	@echo ""

changelogs:
	@echo ""
	@echo "--------------------------------------------------------------------"
	@echo "Generating changelog file"
	@echo ""
	@python "./tools/changelog_script.py" "./changelog/undistributed" --output "./changelog/undistributed.rst"
	@echo "Done."
	@echo ""
