# Setup some project vars
ROOT_DIR := $(CURDIR)
OUTPUT_DIR := ${ROOT_DIR}/out
TESTNET_DIR := ${OUTPUT_DIR}/testnet
TEST_ADDR := 0x003533CD36aC980768B510F5C57E00CE4c0229D5
TEST_KEY := 0x9cbc61f079e82f0d9d3989a99f5cfe4aef68cbec8063b821fd41e994ea131c79 
$(shell mkdir -p ${OUTPUT_DIR})

# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

install: update npm solc

# dapp deps
update:; dapp update

# npm deps for linting etc.
npm:; yarn install

# install solc version
# example to install other versions: `make solc 0_8_2`
SOLC_VERSION := 0_8_7
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_${SOLC_VERSION}

# Build & test
build  :; dapp build
test   :; dapp test # --ffi # enable if you need the `ffi` cheat code on HEVM
clean  :; dapp clean
lint   :; yarn run lint
estimate :; ./scripts/estimate-gas.sh ${contract}
size   :; ./scripts/contract-size.sh ${contract}
abi-out :; jq '.contracts."src/MemeNumbers.sol".MemeNumbers.abi' ./out/dapp.sol.json > ./out/MemeNumbersAbi.json

testnet :; dapp testnet --dir ${TESTNET_DIR}

# Deployment helpers
deploy :; @./scripts/deploy.sh

# local testnet, funding TEST_ADDR with 1000 eth
deploy-testnet: export ETH_FROM=$(shell seth ls --keystore ${TESTNET_DIR}/8545/keystore | cut -f1)
deploy-testnet: export ETH_RPC_ACCOUNTS=true
deploy-testnet: deploy
deploy-testnet :; seth send --value 1000000000000000000000 ${TEST_ADDR}

# mainnet
deploy-mainnet: export ETH_RPC_URL = $(call network,mainnet)
deploy-mainnet: check-api-key deploy

# rinkeby
deploy-rinkeby: export ETH_RPC_URL = $(call network,rinkeby)
deploy-rinkeby: check-api-key deploy

check-api-key:
ifndef ALCHEMY_API_KEY
	$(error ALCHEMY_API_KEY is undefined)
endif

# Returns the URL to deploy to a hosted node.
# Requires the ALCHEMY_API_KEY env var to be set.
# The first argument determines the network (mainnet / rinkeby / ropsten / kovan / goerli)
define network
	https://eth-$1.alchemyapi.io/v2/${ALCHEMY_API_KEY}
endef
