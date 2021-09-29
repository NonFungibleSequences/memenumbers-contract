#!/usr/bin/env bash

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
RendererAddr=$(deploy MemeNumbersRenderer)
ContractAddr=$(deploy MemeNumbers $RendererAddr)
log "MemeNumbers deployed at:" $ContractAddr
