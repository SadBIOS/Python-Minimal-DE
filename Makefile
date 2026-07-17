root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

python_version := 3.12
python_patch_level := 10

ifeq ($(strip $(python_patch_level)),)
python_dot := $(python_version)
python_dash := $(shell latest=$$(ls -d $(root)venv_$(subst .,_,$(python_version))_* 2>/dev/null | sort -V | tail -1); if [ -n "$$latest" ]; then basename "$$latest" | sed 's/venv_//'; fi )

else
python_dot := $(python_version).$(python_patch_level)
python_dash := $(subst .,_,$(python_version))_$(python_patch_level)
endif

default:
	@$(root)runtime/core.sh --init-env $(python_dot)

print_vers:
	@echo "python_dot=$(python_dot)"
	@echo "python_dash=$(python_dash)"
	@$(root)venv_$(python_dash)/bin/python --version

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


# build_src_array:


# download_src_exact:


# build_src_exact:


# verify_local_sources:

