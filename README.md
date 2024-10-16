# Foundry Based sample implementation for DeFi (Stable Coin)

Before getting started with the example here, it is essential to understand what is `DeFi` or `decentralized finance`? There is a lot of content on the internet, high level summary can be found [here](readme-docs/defi.md).

## Stablecoin Architecture

- **Relative Stability**: Anchored or Pegged (1 coin = 1 USD)
  - Leverage Chainlink Pricefeed
  - Have a function to exchange ETH / BTC with USD
- **Stability Mechanism**: Algorithmic / Decentralized
  - Minting will be allowed for stablecoin with sufficient/enough collateral (coded in the smart contract)
- **Collateral**: Exogenous, we will use cryptocurrencies
  - ETH
  - BTC
  We would use the ERC21 version of ETH and BTC - wETH and wBTC

## Initial Setup

### Setup the Project Workspace

```shell
# Project initialization
forge init

# Remove all the counter.sol related files. 

# Installing Openzeppelin libraries
forge install openzeppelin/openzeppelin-contracts --no-commit
# Install the chainlink brownie contracts
forge install smartcontractkit/chainlink-brownie-contracts@1.2.0 --no-commit
```

### Add remappings to `foundry.toml`

```toml
remappings = [
    '@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/',
    '@openzeppelin/contracts=lib/openzeppelin-contracts/contracts',
]
```
