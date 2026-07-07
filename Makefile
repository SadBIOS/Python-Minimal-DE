root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

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

# download_sources:


# verify_local_sources: