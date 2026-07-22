SHELL := /bin/bash
root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
bin_root := $(root)runtime/data/build_dir/compiled_binaries
pip_root := $(root)runtime/data/pip_packages/
paq_req_path := $(root)pkglist.txt

script_name := script.py

python_version := 3.14
python_patch_level := 
python_vers_multi := 3.11 3.12 3.13 3.14

ifeq ($(strip $(python_patch_level)),)
python_dot := $(python_version)
python_dash := $(shell latest=$$(ls -d $(root)venv_$(subst .,_,$(python_version))_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then basename "$$latest" | sed 's/venv_//'; fi )

else
python_dot := $(python_version).$(python_patch_level)
python_dash := $(subst .,_,$(python_version))_$(python_patch_level)
endif

test:
	@echo "$(paq_req_path)"
	@echo "$(root)venv_$(python_dash)/bin/python -m pip"
	@echo "$(pip_root)"


# default:

load_packages:
	@$(root)runtime/pip_handel.sh --pkglist-path "$(paq_req_path)" --pip-bin-src "$(root)venv_$(python_dash)/bin/python -m pip" --local-package-root "$(pip_root)python_$(python_dash)/" --resolve-pip

cache_packages:
	@$(root)runtime/pip_handel.sh --pkglist-path "$(paq_req_path)" --pip-bin-src "$(root)venv_$(python_dash)/bin/python -m pip" --local-package-root "$(pip_root)python_$(python_dash)/" --cache-pip

init_venv:
	@$(root)runtime/core.sh --init-env $(python_dot)

build_src:
	@$(root)runtime/build_engine.sh --build $(python_dot)

print_vers:
	@$(root)venv_$(python_dash)/bin/python --version

init_venv_array:
	@for pv in $(python_vers_multi); do p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || p_dash=""; $(root)runtime/core.sh --init-env "$$p_dot"; done

print_vers_array:
	@for pv in $(python_vers_multi); do latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || continue; $(root)venv_$$p_dash/bin/python --version; done

build_src_array:
	@for pv in $(python_vers_multi); do p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || p_dash=""; $(root)runtime/build_engine.sh --build "$$p_dot"; done

cache_build:
	@$(root)runtime/src_engine.sh --build-cache

cache_wipe:
	@$(root)runtime/src_engine.sh --wipe-cache

force_cache_rebuild:
	@$(root)runtime/src_engine.sh --force-build-cache

force_cache_wipe:
	@$(root)runtime/src_engine.sh --force-wipe-cache


# download_src_array:


# download_src_exact:


# build_src_exact:


# verify_local_sources:


# resolve_dependencies:
