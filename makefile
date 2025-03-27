-include .env

.PHONY: help build test stageTest

help:
	@echo "Usage:"
	@echo "  make build"
	@echo ""
	@echo "  make test"
	@echo ""
	@echo "  make stageTest"

build :; forge build

test :; forge test -vvv

stageTest :; forge test -vvv --mc TokenMinterStagingTest --rpc-url $(ETH_RPC_URL)