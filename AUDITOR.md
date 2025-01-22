# DAOs World Smart Contract Audit Details

## Repository
https://github.com/daaoai/contractFinal<br>

## Overview
DAAO is a protocol enabling efficient DAO creation and management on Mode Network. Core contracts handle DAO creation, fundraising, liquidity management, and token vesting.

## Scope

### In Scope
* Commit hash: **`[b53757a3c2050c1f02216275186bbb62321a5107]`**

```solidity
src/
├── Agent
│   ├── AgentToken.sol
├── DaosWorldV1.sol
├── DaosWorldV1Token.sol
├── DAOTreasury.sol
├── interface.sol
├── LockerFactory.sol
├── LpLocker.sol
```
* Solc Version: ^0.8.0
* To be Deployed on: Mode Network

```bash
# Install
forge install

# Dependencies
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install Uniswap/v3-core --no-commit
forge install Uniswap/v3-periphery --no-commit

# Compile
forge build

# Test
forge test
```

## Setup

Read [this](https://github.com/daaoai/contractFinal?tab=readme-ov-file#setup)