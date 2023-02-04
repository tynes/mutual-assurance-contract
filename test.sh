#!/bin/bash

forge test -vvvvv \
    -f https://optimism-mainnet.infura.io/v3/1e89900b83544a4080855f166037bdc8 \
    --block-number 71540418 \
    --mt resolve
