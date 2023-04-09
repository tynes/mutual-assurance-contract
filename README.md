# pact

A pact is an implementation of a [mutual assurance contract](https://en.wikipedia.org/wiki/Assurance_contract).

> An assurance contract, also known as a provision point mechanism, or crowdaction,[1] is a game-theoretic mechanism and a financial technology that facilitates the voluntary creation of public goods and club goods in the face of collective action problems such as the free rider problem.

> The free rider problem is that there may be actions that would benefit a large group of people, but once the action is taken, there is no way to exclude those who did not pay for the action from the benefits. This leads to a game theoretic problem: all members of a group might be better off if an action were taken, and the members of the group contributed to the cost of the action, but many members of the group may make the perfectly rational decision to let others pay for it, then reap the benefits for free, possibly with the result that no action is taken. The result of this rational game play is lower utility for everyone.

## Usage

To coordinate with others, first come to an offchain agreement on the rules of the engagement. The
`PactFactory` can be used to create a mutual assurance contract. An instance of a mutual assurance
contract is referred to a pact, (an instance of a `Pact`). Commit to the offchain agreement when
creating a pact. A pact also needs a duration (amount of time until it can be resolved), a sum of
ether (denominated in wei) and a set of leads to control the ether if the coordination continues.

### optimism-goerli

| Contract | Address | Version |
| -------- | ------- | ------- |
| `PactFactory` | [0x6E49B117A895eaf0037279B9Dc625D3A4C2065CC](https://goerli-optimism.etherscan.io/address/0x6E49B117A895eaf0037279B9Dc625D3A4C2065CC) | `0.1.0` |
| `Pact` (implementation) | [0x1d8Edff9F794684E78D40Aa5b2a5799b2383a2a5](https://goerli-optimism.etherscan.io/address/0x1d8Edff9F794684E78D40Aa5b2a5799b2383a2a5) | `0.1.0` |
| `PactFactory` | [0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95](https://goerli-optimism.etherscan.io/address/0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95) | `0.2.0` |
| `Pact` (implementation) | [0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1](https://goerli-optimism.etherscan.io/address/0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1) | `0.2.0` |

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
