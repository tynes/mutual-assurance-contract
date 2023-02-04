.PHONY: all clean test deploy

RPC := https://mainnet.optimism.io
BLOCK_NUMBER := 71540418

all      :; forge build
clean    :; forge clean
test     :; forge test -vvvvv -f $(RPC) --block-number $(BLOCK_NUMBER) --mt lose
snapshot :; forge snapshot -f $(RPC) --block-number $(BLOCK_NUMBER)
deploy   :; forge script
