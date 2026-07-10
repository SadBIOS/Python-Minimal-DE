root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
dependencies := $(root)dep_deb135.tar.gz

default:
	@echo "$(dependencies)"

init_env:
	@chmod +x $(root)runtime/*.sh
	@echo "Runtime Scripts Have Been Activated!"

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

