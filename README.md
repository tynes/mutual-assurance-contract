# pact

`pact` is an implementation of a [Mutual Assurance Contract](https://en.wikipedia.org/wiki/Assurance_contract).

> An assurance contract, also known as a provision point mechanism, or crowdaction, is a game-theoretic
> mechanism and a financial technology that facilitates the voluntary creation of public goods and club
> goods in the face of collective action problems such as the free rider problem.

> The free rider problem is that there may be actions that would benefit a large group of people, but once
> the action is taken, there is no way to exclude those who did not pay for the action from the benefits.
> This leads to a game theoretic problem: all members of a group might be better off if an action were taken,
> and the members of the group contributed to the cost of the action, but many members of the group may make
> the perfectly rational decision to let others pay for it, then reap the benefits for free, possibly with
> the result that no action is taken. The result of this rational game play is lower utility for everyone.

While Wikipedia's definition makes sense, it does not take into account the blockchain's ability to
act as a credible commitment engine. Coordination only happens when the expected value from
coordinating is greater than the cost to initiate the coordination itself. There is always an
alternative in a networked world so the cost to commit is high when the chances of the counterparty
flaking are high. Perceived social status binds people to their commitments but this does not
scale. A Mutual Assurance Contract is meant to make coordination more scalable by reducing the risk
of counterparties flaking and increasing the signal for potential participants.

When a participant would like to coordinate, they can create an instance of a Mutual Assurance
Contract. This is a permissionless pool that anybody can contribute ether to within a timeframe.
There is a target sum of ether that is determined to be the amount of capital required to execute
on whatever the coordination is about and the contract guarantees that the ether will be returned
if not enough accumulates. When a participant sends ether into the pool, they are financially
committed to coordinating, increasing the cost to flake. All other possible participants can not
see that others are committed, reducing the costs to committing themselves.

## Usage

The `PactFactory` can be used to create a pact, or an instance of a mutual assurance contract.
First come to an offchain agreement on the rules of the engagement. A commitment to these rules
should be included with each pact. A pact also needs a duration (amount of time until it can be
resolved), a sum of ether (denominated in wei) and a set of leads to control the ether if the
coordination continues.

To create a pact, call `create(bytes32 _commitment, uint256 _duration, uint256 _sum, address[] memory _leads)`
on the `PactFactory`.

### Arguments

#### `_commitment`

This is a commitment to the rules of the engagement. Once the rules exist, it is easy to call the
`commit(string)(bytes32)` function on the `PactFactory` to get back the commitment.

#### `_duration `

This is the number of seconds that the pact should be live for.

#### `_sum`

This is the amount of wei that the pact requires for coordination to continue.
Note that 10^18 wei is 1 ether.

#### `_leads`

The custodians of the funds if coordination continues. A Gnosis Safe is created and
the funds are transferred there. The Gnosis Safe has a signing threshold of all of the
leads. The leads can choose to update this value themselves.

### optimism-mainnet

| Contract | Address | Version |
| -------- | ------- | ------- |
| `PactFactory` | [0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95](https://optimistic.etherscan.io/address/0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95) | `0.2.0` |
| `Pact` (implementation) | [0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1](https://optimistic.etherscan.io/address/0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1) | `0.2.0` |

### optimism-goerli

| Contract | Address | Version |
| -------- | ------- | ------- |
| `PactFactory` | [0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95](https://goerli-optimism.etherscan.io/address/0x642a7864cBe44ED24D408Cbc38117Cfd6E6D1a95) | `0.2.0` |
| `Pact` (implementation) | [0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1](https://goerli-optimism.etherscan.io/address/0x4eE4ff6D24c8D334fA41b560Dac95BB3CEF828a1) | `0.2.0` |

## Philosophy

It is incredibly important that the language is simple and internally consistent enough that users
can understand the UX intuitively. Vocabulary should be standard and synonyms are bad.

It is an anti-pattern to build a platform when there isn't a usecase with product market fit already
using the platform. The first usecase of `pact` is coordinating nomads to be in the same location at
the same time. Can/should it be used for everyday tasks?

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

Useful for deploying the factory. This requires no additional config.

### `deploy-contract.sh`

Useful for deploying an instance of a mutual assurance contract.
Place the config in a JSON file inside of the `deploy-config`
directory. Pass the path to the desired config file as the first
argument to `deploy-contract.sh` and that will deploy the mutual
assurance contract as desired.
