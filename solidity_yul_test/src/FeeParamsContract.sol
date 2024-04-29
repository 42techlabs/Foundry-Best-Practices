// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeParamsContract {
    function getFeeParams(uint256 fairPubdataPrice, uint256 fairL2GasPrice) public pure returns (uint256 baseFee, uint256 gasPerPubdata) {
        assembly {
            // 将 Solidity 变量的值赋给 Yul 变量
            let _fairPubdataPrice := fairPubdataPrice
            let _fairL2GasPrice := fairL2GasPrice

            function ceilDiv(x, y) -> ret {
                switch or(eq(x, 0), eq(y, 0))
                case 0 {
                    // (x + y - 1) / y can overflow on addition, so we distribute.
                    ret := add(div(sub(x, 1), y), 1)
                }
                default {
                    ret := 0
                }
            }

            /// @dev Returns the maximum of two numbers
            function max(x, y) -> ret {
                ret := y
                if gt(x, y) {
                    ret := x
                }
            }

            function MAX_L2_GAS_PER_PUBDATA() -> ret {
                ret := 1048576
            }

            function gasPerPubdataFromBaseFee(_baseFee, pubdataPrice) -> ret {
                ret := ceilDiv(pubdataPrice, _baseFee)
            }

            baseFee := max(
                _fairL2GasPrice,
                ceilDiv(_fairPubdataPrice, MAX_L2_GAS_PER_PUBDATA())
            )

            gasPerPubdata := gasPerPubdataFromBaseFee(baseFee, _fairPubdataPrice)
        }
    }
}
