# Risks Involved with DeFi

## Blockchain Oracle Problem

Smart contracts can unlock new economic opportunities; however, access to high-quality, tamper-proof data has historically been difficult, and no matter how robust the smart contract code is, it is highly dependent on the data it receives, this is commonly referred to as the [blockchain oracle problem](https://blog.chain.link/what-is-the-blockchain-oracle-problem/) and concerns most DeFi applications.

dApps sourcing data from premium off-chain data providers play a pivotal role in maintaining a robust and resilient DeFi ecosystem. These providers are an essential component in the fight against oracle manipulation attacks, such as flash loan attacks, and numerous other potential outlier events.

## Flash Loan

A [flash loan](https://chain.link/education-hub/flash-loans) is a type of loan where a user borrows assets with no upfront collateral and returns the borrowed assets within the same blockchain transaction.

![Flash Loan Problem](readme-imgs/flash-loan-problem.png)

Hence, high-quality (off-chain) data sources that avoid manipulation are vital to protecting users and mitigating systemic risk within DeFi.

## Maximal Extractable Value (MEV)

- MEV is a significant concept in the cryptocurrency world, particularly in relation to blockchain networks like Ethereum, it refers to the maximum value that can be extracted from block production in excess of the standard block rewards and gas fees by including, excluding, or changing the order of transactions in a block.
  - Earlier it was known as "Miner Extractable Value," the term has evolved to "Maximal Extractable Value" as it applies to both proof-of-work and proof-of-stake systems.
  - MEV presents opportunities for profit, it also raises concerns about fairness and network security. As the industry evolves, finding ways to balance MEV's impact will be crucial for the long-term health of blockchain ecosystems.

MEV has significant implications for the cryptocurrency ecosystem:

- **Fairness Issues**: It can lead to an uneven playing field where miners have an advantage over regular users.
- **Network Security**: Large MEV opportunities can incentivize blockchain forks, potentially compromising network security.
- **DeFi Vulnerability**: Decentralized finance (DeFi) protocols are particularly susceptible to MEV exploitation due to their transparent and permissionless nature.

Several approaches are being developed to mitigate MEV:

- **Fair Sequencing Services**: These aim to ensure fairness in transaction ordering.
- **Off-chain Transactions and Batching**: This reduces the importance of transaction order.
- **User Controls**: Protocols allowing users to specify maximum slippage can help limit MEV exploitation.

### How does MEV work?

MEV extraction typically occurs through:

1. `Transaction Ordering`: Miners or validators can reorder transactions within a block to their advantage.
2. `Transaction Inclusion/Exclusion`: Miners can choose which transactions to include or exclude from a block.
3. `Inserting Own Transactions`: Miners can insert their own transactions to capitalize on profitable opportunities.

### Common Strategies

- **Frontrunning**: Miners or bots monitor the mempool for pending transactions and execute their own transactions ahead of others to take advantage of price movements.
- **Backrunning**: This involves placing a sell order after noticing a large buy order to profit from the resulting price increase.
- **Sandwiching**: A combination of frontrunning and backrunning, where traders place orders both before and after a target transaction.
