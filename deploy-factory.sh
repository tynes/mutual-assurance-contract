#!/bin/bash

ETH_RPC_URL="${ETH_RPC_URL:-$1}"
ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$2}"
PRIVATE_KEY="${PRIVATE_KEY:-$3}"

function check() {
    if [ -z $1 ]; then
        exit 1
    fi
}

check "$ETH_RPC_URL"
check "$ETHERSCAN_API_KEY"
check "$PRIVATE_KEY"

forge script script/DeployFactory.s.sol \
    --broadcast \
    --rpc-url $ETH_RPC_URL \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    --slow
