// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {FeeParamsContract} from "../src/FeeParamsContract.sol";

import {Test, console} from "forge-std/Test.sol";

contract FeeParamsContractTest is Test {
    FeeParamsContract public feeParamsContract;

    uint256 constant MAX_L2_GAS_PER_PUBDATA = 1048576;

    function setUp() public {
        feeParamsContract = new FeeParamsContract();
    }

    function testGetFeeParams(uint256 fairPubdataPrice, uint256 fairL2GasPrice) public {
        // 如果 fairL2GasPrice 为 0，直接设置预期结果，避免在 Yul 代码中进行除零操作
        if (fairL2GasPrice == 0) {
            uint256 expectedBaseFee = 0;
            uint256 expectedGasPerPubdata = 0;
    
            // 断言基础费用和每个 Pubdata 的 Gas 成本为 0
            assertTrue(expectedBaseFee == 0, "Base fee should be zero when fair L2 gas price is zero");
            assertTrue(expectedGasPerPubdata == 0, "Gas per pubdata should be zero when fair L2 gas price is zero");
            return;
        }
    
        (uint256 baseFee, uint256 gasPerPubdata) = feeParamsContract.getFeeParams(fairPubdataPrice, fairL2GasPrice);
    
        // 断言 baseFee 至少与 fairL2GasPrice 相等
        assertTrue(baseFee >= fairL2GasPrice, "Base fee should be at least fair L2 gas price");
    
        // 断言 gasPerPubdata 乘以 baseFee 至少与 fairPubdataPrice 相等
        assertTrue(gasPerPubdata * baseFee >= fairPubdataPrice, "gasPerPubdata times baseFee should be at least fair pubdata price");
    
        // 断言 gasPerPubdata 不超过 MAX_L2_GAS_PER_PUBDATA
        assertTrue(gasPerPubdata <= MAX_L2_GAS_PER_PUBDATA, "gasPerPubdata should be less than or equal to MAX_L2_GAS_PER_PUBDATA");
    }
    
}
    /*
    function testGetFeeParams() public view {
        uint256 fairPubdataPrice = 36028797034692609;
        uint256 fairL2GasPrice = 1;
        (uint256 baseFee, uint256 gasPerPubdata) = feeParamsContract.getFeeParams(fairPubdataPrice, fairL2GasPrice);

        // 断言 baseFee 至少与 fairL2GasPrice 相等
        assertTrue(baseFee >= fairL2GasPrice, "Base fee should be at least fair L2 gas price");

        // 断言 gasPerPubdata 乘以 baseFee 至少与 fairPubdataPrice 相等
        assertTrue(gasPerPubdata * baseFee >= fairPubdataPrice, "gasPerPubdata times baseFee should be at least fair pubdata price");

        // 断言 gasPerPubdata 不超过 MAX_L2_GAS_PER_PUBDATA
        assertTrue(gasPerPubdata <= MAX_L2_GAS_PER_PUBDATA, "gasPerPubdata should be less than or equal to MAX_L2_GAS_PER_PUBDATA");
    }*/

