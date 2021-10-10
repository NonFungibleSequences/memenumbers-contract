#!/usr/bin/env bash

# import the deployment helpers
. $(dirname $0)/common.sh

#export DAPP_VERIFY_CONTRACT=1 # FIXME: This breaks :( Can't figure out how to pass it in properly

# Deploy.
if [[ ! "$RendererAddr" ]]; then
  RendererAddr=$(deploy MemeNumbersRenderer)
  log "MemeNumbersRenderer deployed at:" $RendererAddr

  [[ $ETHERSCAN_API_KEY ]] && dapp verify-contract src/MemeNumbersRenderer.sol:MemeNumbersRenderer $RendererAddr
else
  log "MemeNumbersRenderer already deployed, skipping: $RendererAddr"
fi

if [[ ! "$ContractAddr" ]]; then
  ContractAddr=$(deploy MemeNumbers $RendererAddr)
  log "MemeNumbers deployed at:" $ContractAddr

  [[ $ETHERSCAN_API_KEY ]] && dapp verify-contract src/MemeNumbers.sol:MemeNumbers $ContractAddr $RendererAddr
else
  log "MemeNumbers already deployed, skipping: $ContractAddr"
fi
