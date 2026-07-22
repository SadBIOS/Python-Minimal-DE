SHELL := /bin/bash
root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
bin_root := $(root)runtime/data/build_dir/compiled_binaries
pip_root := $(root)runtime/data/pip_packages/
paq_req_path := $(root)pkglist.txt

script_name := main.py

python_version := 3.12
python_patch_level := 
python_vers_multi := 3.11 3.12 3.13 3.14

ifeq ($(strip $(python_patch_level)),)
python_dot := $(python_version)
python_dash := $(shell latest=$$(ls -d $(root)venv_$(subst .,_,$(python_version))_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then basename "$$latest" | sed 's/venv_//'; fi )

else
python_dot := $(python_version).$(python_patch_level)
python_dash := $(subst .,_,$(python_version))_$(python_patch_level)
endif

default:
	@rm -vrf $(root)__pycache__ 2>/dev/null
	@$(root)venv_$(python_dash)/bin/python -m $(script_name:.py=)
	@rm -rf $(root)__pycache__ 2>/dev/null

system_init:
	@$(root)runtime/src_engine.sh --force-build-cache

download_src:
	@if [ -z "$(python_version)" ]; then $(root)runtime/src_engine.sh --download-bleeding; elif [ -z "$(python_patch_level)" ]; then $(root)runtime/src_engine.sh --download-max-patch-lvl $(python_dot); else $(root)runtime/src_engine.sh --download-exact $(python_dot); fi

verify_local_sources:
	@$(root)runtime/src_engine.sh --verify-archive

build_src:
	@$(root)runtime/build_engine.sh --build $(python_dot)

create_venv:
	@$(root)runtime/core.sh --init-env $(python_dot)

cache_packages:
	@$(root)runtime/pip_handel.sh --pkglist-path "$(paq_req_path)" --pip-bin-src "$(root)venv_$(python_dash)/bin/python -m pip" --local-package-root "$(pip_root)python_$(python_dash)/" --cache-pip

load_packages:
	@$(root)runtime/pip_handel.sh --pkglist-path "$(paq_req_path)" --pip-bin-src "$(root)venv_$(python_dash)/bin/python -m pip" --local-package-root "$(pip_root)python_$(python_dash)/" --resolve-pip

print_venv_details:
	@echo "------------------------------------------------------------------------"
	@echo "------------------------------------------------------------------------"
	@echo "Virtual Environment Name = venv_$(python_dash)"
	@echo "Python Version           = $$($(root)venv_$(python_dash)/bin/python --version)"
	@echo "------------------------------------------------------------------------"
	@echo "Installed Pip Packages"
	@echo "------------------------------------------------------------------------"
	@$(root)venv_$(python_dash)/bin/python -m pip --disable-pip-version-check list
	@echo "------------------------------------------------------------------------"

sync_online:
	@$(root)runtime/src_engine.sh --update-archive

force_cache_rebuild:
	@$(root)runtime/src_engine.sh --force-build-cache

url_cache_wipe:
	@$(root)runtime/src_engine.sh --wipe-cache

force_cache_wipe:
	@$(root)runtime/src_engine.sh --force-wipe-cache

force_build_local_src_repo:
	@$(root)runtime/src_engine.sh --force-download-all

init_venv_array:
	@for pv in $(python_vers_multi); do p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || p_dash=""; $(root)runtime/core.sh --init-env "$$p_dot"; done

print_venv_details_array:
	@for venv in $$(ls -d $(root)venv_* 2>/dev/null | sort -V); do name=$$(basename "$$venv"); echo "------------------------------------------------------------------------"; echo "------------------------------------------------------------------------"; echo "Virtual Environment Name = $$name"; printf "Python Version           = "; "$$venv/bin/python" --version; echo "------------------------------------------------------------------------"; echo "Installed Pip Packages"; echo "------------------------------------------------------------------------"; "$$venv/bin/python" -m pip --disable-pip-version-check list; echo "------------------------------------------------------------------------"; done

build_src_array:
	@for pv in $(python_vers_multi); do p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || p_dash=""; $(root)runtime/build_engine.sh --build "$$p_dot"; done

download_src_array:
	@for pv in $(python_vers_multi); do p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); [ -n "$$latest" ] && p_dash=$$(basename "$$latest" | sed 's/venv_//') || p_dash=""; $(root)runtime/src_engine.sh --download-max-patch-lvl "$$p_dot"; done

full_workspace_reset:
	@rm -vrf $(root)venv_* 2>/dev/null
	@$(root)runtime/build_engine.sh --nuke
	@$(root)runtime/src_engine.sh --force-wipe-cache
	@$(root)runtime/src_engine.sh --wipe-archive
	@$(root)runtime/core.sh --force-pip-cache-wipe
	@rm -vrf $(root)runtime/data/ 2>/dev/null
