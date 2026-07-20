root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
bin_root := $(root)runtime/data/build_dir/compiled_binaries
pip_root := $(root)runtime/data/pip_packages/

python_version := 3.11 3.12 3.13 3.14
python_patch_level :=


init_venv_array:
	@for pv in $(python_version); do if [ -z "$(strip $(python_patch_level))" ]; then p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then p_dash=$$(basename "$$latest" | sed 's/venv_//'); else p_dash=""; fi; else p_dot="$$pv.$(strip $(python_patch_level))"; p_dash="$${pv//./_}_$(strip $(python_patch_level))"; fi; $(root)runtime/core.sh --init-env "$$p_dot"; done

print_vers_array:
	@for pv in $(python_version); do if [ -z "$(strip $(python_patch_level))" ]; then p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then p_dash=$$(basename "$$latest" | sed 's/venv_//'); else p_dash=""; fi; else p_dot="$$pv.$(strip $(python_patch_level))"; p_dash="$${pv//./_}_$(strip $(python_patch_level))"; fi; echo "python_dot=$$p_dot"; echo "python_dash=$$p_dash"; $(root)venv_$$p_dash/bin/python --version; done

init_env:
	@chmod +x $(root)runtime/*.sh
	
cache_build:
	@$(root)runtime/src_engine.sh --build-cache

cache_wipe:
	@$(root)runtime/src_engine.sh --wipe-cache

force_cache_rebuild:
	@$(root)runtime/src_engine.sh --force-build-cache

force_cache_wipe:
	@$(root)runtime/src_engine.sh --force-wipe-cache

# download_src_array:


build_src_array:
	@for pv in $(python_version); do if [ -z "$(strip $(python_patch_level))" ]; then p_dot="$$pv"; latest=$$(ls -d $(root)venv_$${pv//./_}_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then p_dash=$$(basename "$$latest" | sed 's/venv_//'); else p_dash=""; fi; else p_dot="$$pv.$(strip $(python_patch_level))"; p_dash="$${pv//./_}_$(strip $(python_patch_level))"; fi; $(root)runtime/build_engine.sh --build "$$p_dot"; done

# download_src_exact:


# build_src_exact:


# verify_local_sources:


# resolve_dependencies:


test:
	@echo "$(bin_root)"
	@echo "$(pip_root)"