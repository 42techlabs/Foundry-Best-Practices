# Liquidity Prices Attack Foundry Test

## Introduce

We will create a Foundry test (POC Proof of Concept) to verify the [Velodrome LP Share calculation wont work for all velodrome pools](https://github.com/hats-finance/VMEX-0x050183b53cf62bcd6c2a932632f8156953fd146f/issues/24) finding.

We will design a simulation to test an attack scenario where the attacker attempts to mainpulate the price of a liquidity pool (LP) by extensively swapping tokens, and verify if the price changes.

### Setup

1. Init project
   ```
       forge init liquidity_prices_attack --no-commit
   ```
2. Set solc version

   Add solc version in `foundry.toml`

   ```
       solc = '0.8.20'
   ```

   The version of solc refers to the version in OpenZeppelion lib


### Install dependencies

- `{IERC20}`: Using OZ ERC20 interface replace origin ERC20 contracts

- `{vMath}`: Using OZ Math interface replace origin Math

- `{IVeloPair}`: Copy `IVeloPair` interface into test file.


### Change Function Visibility

Since the test requires the `get_lp_price` function, its function visibility needs to be changed from `internal` to `public`.

### Build Test

Run `forge build` to check if the basic configuration is correct.

### Add the addresses required for testing

Search Token address from [Optimism](https://optimistic.etherscan.io/)

1. WETH Address: 0x4200000000000000000000000000000000000006
2. wstETH Address: 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb

### Write SetUp Function

```solidity
    function setUp() public {
        oracle = new VelodromeOracle(); //Inlitialize the oracle with a new instance of VelodromeOracle
    }
```

### Wrtite Test Case Code

We plan to simulate the attack in four steps.

```solidity
    function testAttack() public {

    }
```

#### 1. Check initial Price
Set stable pair liquidity pool address using `0xBf205335De602ac38244F112d712ab04CB59A498`

```
    address constant STABLE_PAIR = 0xBf205335De602ac38244F112d712ab04CB59A498;
```

Using `get_lp_price` to fetch the initial price of the LP token from the `oracle` in the `STABLE_PAIR` liquidity pool.

There are two parameters in `get_lp_price(address lp_token, uint256[] memory prices)`
- Using `STABLE_PAIR` for the first parmeter.
- Initializing an arry with fixed values(1e18) for the second parmeter.

#### First Build and Fork Tests
Frist, build and debug tests.

```bash
  forge build
  forge test
```

Due to the need to fetch the latest prices from the Optimism Mainnet, using `forge test` results in a `FAIL`. Thus, Fork Tests are needed. Using the following command.

```bash
   forge test --rpc-url https://opt-mainnet.g.alchemy.com/v2/YOUR_OPTIMISM_MAINNET_API
```

You can get an Optimism Mainnet fork URL from [Alchemy](https://www.alchemy.com/).


#### 2. Check a reserve

The reserve of a liquidity pool refer to the quantity of each token in the pool. Reserve can usually be accessed directly through contract functions `getReserves`.

However, there is a trick way using `WETH.balanceOf(STABLE_PAIR)` to obtain the balance of `WETH` tokens in the `STABLE_PAIR` liquidity pool as an approximate way to estimate the pool's reserves


#### 3. Do a Massive Swap
1. Create a mock address used to simulate an attacker

2. Using `deal()` to driectly assign a token balance to a specific account.

3. Using `startPrank()` set the sender(`msg.sender`) of the test environment, unitl `vm.stopPrank()` is called.

4. Approve transfer

5. Calling the Swap function on the Velodrome Finance: Router,so create the interface IRouter in your test file.
   
6. Find Swap function and add it into interface IRouter
   
7. Using `swapExactTokensForTokens` in your test file.

#### 4. Verify if Price Changes
1. After `swapExactTokensForTokens`, use `get_lp_price` to obtain the latest LP price, and use `assertEq` to determine whether the price has changed.
  
2. Using `console2.log` to print price in the console. 

#### 5. Test Result
The test results indicate a significant change in the liquidity pool price reported by the `VelodromeOracle` contract after simulating an attack, with the initial price at approximately `1.834e18` and the new price dropping to about `0.992e18` post-attack. This discrepancy highlights a potential vulnerability in the contract's price feedback mechanism, especially under extreme market conditions or manipulative actions.

![result](images/result.png)

### 6. Fuzz Testing

We use fuzz testing to provide extensive coverage and reveal vulnerabilities.

## Tips

- Using balance of LP token to approximate the pool's reserves

- Use [Solidity by Example](https://solidity-by-example.org/) to assist in writing test code 

- Use `-vvv` to check the detail of test, if there are some error.
  ```
      forge test --rpc-url https://opt-mainnet.g.alchemy.com/v2/YOUR_API -vvv
  ```
## More
For more information, please refer to my article

- [Foundry Testing Master Class: Step-by-Step Guides to Smart Contract Security-Episode 1]()

## Thanks
Case From: [Foundry for Blazing Fast Brute Forcing](https://youtu.be/tDFA8cnHoCY?t=8063)
