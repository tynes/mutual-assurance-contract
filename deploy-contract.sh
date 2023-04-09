#!/bin/bash

ETH_RPC_URL="${ETH_RPC_URL:-$1}"
ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-$2}"
PRIVATE_KEY="${PRIVATE_KEY:-$3}"

function check() {
    if [ -z $1 ]; then
        exit 1
    fi
}

CONFIG_PATH="$1"

check "$ETH_RPC_URL"
check "$ETHERSCAN_API_KEY"
check "$PRIVATE_KEY"
check "$CONFIG_PATH"

if [ ! -f $CONFIG_PATH ]; then
    exit 1
fi

COMMITMENT=$(jq -r .commitment < "$CONFIG_PATH" | cast keccak)
DURATION=$(jq -r .duration < "$CONFIG_PATH")
SUM=$(jq -r .sum < "$CONFIG_PATH")
GUARDIANS=$(jq -r '.leads' < "$CONFIG_PATH" | tr -d '"' | tr -d '[:space:]')

DATA=$(cast abi-encode \
    'f(bytes32,uint256,uint256,address[])' \
    $COMMITMENT \
    $DURATION \
    $SUM \
    $GUARDIANS)

forge script script/DeployContract.s.sol \
    -s 'run(bytes)' $DATA \
    --broadcast \
    --rpc-url $ETH_RPC_URL \
    --private-key $PRIVATE_KEY \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --verify \
    --slow
