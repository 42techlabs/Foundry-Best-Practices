// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/VerodromeOracle.sol";

interface IRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external;
}

contract VeloOracleTest is Test {
    VelodromeOracle public oracle; // an instance of VelodromeOracle

    // WETH Address: 0x4200000000000000000000000000000000000006
    // wstETH Address: 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb
    // Stable Pair Address: 0xBf205335De602ac38244F112d712ab04CB59A498
    // Volatile Pair Address: 0xc6C1E8399C1c33a3f1959f2f77349D74a373345c
    // Velodrome Router: 0x9c12939390052919aF3155f41Bf4160Fd3666A6f
    
    address constant STABLE_PAIR = 0xBf205335De602ac38244F112d712ab04CB59A498; // addreess of stable pair in LP
    
    IERC20 constant WSTETH = IERC20(0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb); // wstETH addrsss in Optimism
    IERC20 constant WETH = IERC20(0x4200000000000000000000000000000000000006); // WETH address in Optimism

    address constant ATTACKER = address(0xbad); // a mock address used to simulate an attacker

    IRouter constant VELO_ROUTER = IRouter(0x9c12939390052919aF3155f41Bf4160Fd3666A6f); // the address of a router contract tha


    function setUp() public {
        oracle = new VelodromeOracle(); //Inlitialize the oracle with a new instance of VelodromeOracle
    }

    /**
     Main test function, designed to simulate an attack and 
     check the oracle's price response to massive swaps
     */
    function testAttack() public {
        uint256[] memory prices = new uint256[](2); // for get_lp_price's second parameter: @param prices The prices of the underlying in the liquidity pool
        prices[0] = 1e18;
        prices[1] = 1e18;
        // Attack Pattern
        // 1. Check initial Price
        uint256 initialPrice = oracle.get_lp_price(STABLE_PAIR,prices);

        // 2. Check a reserve
        // Trick, just get balance of LP token, since it's so manipulated yet
        uint256 initialBalanceOfWETH = WETH.balanceOf(STABLE_PAIR);

        // 3. Do a Massive Swap
        deal()

        // 4. Verify if Price Changes
    }
}
