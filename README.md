# Janus Lottery Contract

# WORK IN PROGRESS 

## Author
Harold Rosenberg

## Overview
The Janus Lottery contract facilitates a unique lottery system with two main participants: **Jackpot Funders** and **Ticket Buyers**.

### Phases
1. **Jackpot Funding Phase**: 
   - Funders compete to offer the best jackpot.
   - Each jackpot offer includes the total amount, winning chance, ticket price, and selling period.

2. **Ticket Buying Phase**: 
   - Participants purchase tickets for a chance to win the jackpot.
   - If no one wins, the funder receives the ticket sales.

### Additional Details
- The contract owner receives a fee from the proceedings.
## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
