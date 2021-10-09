#!/usr/bin/env bash

# import the deployment helpers
. $(dirname $0)/common.sh

#export DAPP_VERIFY_CONTRACT=1 # FIXME: This breaks :( Can't figure out how to pass it in properly

# Deploy.
if [[ ! "$RendererAddr" ]]; then
  RendererAddr=$(deploy MemeNumbersRenderer)
  log "MemeNumbersRenderer deployed at:" $RendererAddr
else
  log "MemeNumbersRenderer already deployed, skipping: $RendererAddr"
fi

if [[ ! "$ContractAddr" ]]; then
  ContractAddr=$(deploy MemeNumbers $RendererAddr)
  log "MemeNumbers deployed at:" $ContractAddr
else
  log "MemeNumbers already deployed, skipping: $ContractAddr"
fi
