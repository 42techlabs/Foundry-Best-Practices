# Foundry Best Practices

Welcome to the Foundry Best Practices GitHub repository, your go-to resource for Foundry-based smart contract testing. This repository is crafted to help developers navigate through the complexities of blockchain testing with ease.

### What's Inside

- **Smart Contract Test Scenarios**: Explore a range of scenarios, including "Attacks on Liquidity Pools", to prepare for real-world challenges.
- **Comprehensive Guides**: Each scenario comes with clear instructions on setup, execution, and debugging, making your testing journey straightforward.

### Get Involved

Dive into the examples to bolster your smart contract development skills. Contributions are welcome; share your insights or improve existing content!

Stay tuned for updates and new test cases. Happy coding!

## [Liquidity Prices Attack](https://github.com/42techlabs/Foundry-Best-Practices/tree/main/liquidity_prices_attack)
- Liquidity Pool Price Attack Simulation
- Price Verification: Comparing Liquidity Pool prices before and after swaps
- Fuzz Testing
- Exception Handling: Captureing and dealing with potential exceptions during the swap process using `try-catch` statements.
- Reuse source code: contract -> interface, IERC20 lib -> OpenZeppelin,
- `console2.log`, `vm.startPrank`, `vm.stopPrank`, `deal`.
- `--rpc-url`
- Alchemy API