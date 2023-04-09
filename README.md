# pact

A pact is an implementation of a [mutual assurance contract](https://en.wikipedia.org/wiki/Assurance_contract).

> An assurance contract, also known as a provision point mechanism, or crowdaction,[1] is a game-theoretic mechanism and a financial technology that facilitates the voluntary creation of public goods and club goods in the face of collective action problems such as the free rider problem.

> The free rider problem is that there may be actions that would benefit a large group of people, but once the action is taken, there is no way to exclude those who did not pay for the action from the benefits. This leads to a game theoretic problem: all members of a group might be better off if an action were taken, and the members of the group contributed to the cost of the action, but many members of the group may make the perfectly rational decision to let others pay for it, then reap the benefits for free, possibly with the result that no action is taken. The result of this rational game play is lower utility for everyone.

## Usage

Needs to have the deployed contract addresses here.


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
