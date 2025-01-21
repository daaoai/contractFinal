# DAOs World Smart Contracts

A decentralized platform for creating and managing DAOs with integrated liquidity management and token vesting capabilities.

## Core Components

### DaosWorldV1
The main contract handling DAO creation, fundraising, and liquidity management. Features include:
- Customizable fundraising parameters
- Whitelist support
- Automatic liquidity provision
- LP token locking mechanism
- Built-in tax system

### DaosWorldV1Token
Standard ERC20 token implementation with:
- Minting capabilities controlled by owner
- Full ERC20 compliance
- Ownable pattern implementation

### LpLocker
Handles liquidity pool token locking with:
- Time-based token locking
- Fee collection mechanism
- LP token management
- Security controls for token releases

### LockerFactory
Factory contract for deploying LP lockers with:
- Standardized deployment process
- Protocol admin controls
- Event logging for deployments

## Key Features

- **Fundraising**: Configurable fundraising goals and deadlines
- **Token Management**: Automated token distribution and vesting
- **Liquidity Management**: Automated LP creation and locking
- **Security**: Multiple security measures including reentrancy protection
- **Fee System**: Configurable tax system for buys and sells

## Setup

```sh
forge install
forge build
```

## License
MIT