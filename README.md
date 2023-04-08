# Mutual Assurance Contracts

## Deployment

The provided deploy scripts operate on in memory private keys.
It is preferable to use hardware wallets when doing deployments.

It is recommended to use [direnv](https://direnv.net) for managing
environment variables when doing deployments with `foundry`.

Create a `.envrc` file with the following values:
- `ETH_RPC_URL`
- `ETHERSCAN_API_KEY`
- `PRIVATE_KEY`

There are 2 deployment scripts.

### `deploy-factory.sh`

Useful for deploying the factory

### `deploy-contract.sh`

Useful for deploying an instance of a mutual assurance contract.
Place the config in a JSON file inside of the `deploy-config`
directory. Pass the path to the desired config file as the first
argument to `deploy-contract.sh` and that will deploy the mutual
assurance contract as desired.
