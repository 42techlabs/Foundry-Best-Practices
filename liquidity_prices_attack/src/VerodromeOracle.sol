// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; 

interface IVeloPair {

	function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);

    function decimals() external view returns (uint8);
}

//some minor differences to univ2 pairs, but mostly the same
contract VelodromeOracle {
	//limited to curve pools only, either 2 or 3 assets (mostly 2) 
	function nthroot(uint8 n, uint256 val) internal pure returns(uint256) {
		//VMEX empirically checked that this is only accurate for square roots and cube roots, and the decimals are 9 and 12 respectively
		if(n==2){
			return Math.sqrt(val);
		}

		revert("Math only can handle square roots and cube roots");
	}
	/**
     * @dev Gets the price of a velodrome lp token
     * @param lp_token The lp token address
     * @param prices The prices of the underlying in the liquidity pool
     **/
	function get_lp_price(address lp_token, uint256[] memory prices) public view returns(uint256) {
		IVeloPair token = IVeloPair(lp_token); 	
		uint256 total_supply = IERC20(lp_token).totalSupply(); 
		uint256 decimals = 10**token.decimals();
		(uint256 d0, uint256 d1, uint256 r0, uint256 r1, , ,) = token.metadata(); 

		//converts to number of decimals that lp token has, regardless of original number of decimals that it has
		//this is independent of chainlink oracle denomination in USD or ETH
		uint256 reserve0 = (r0 * decimals) / d0; 
		uint256 reserve1 = (r1 * decimals) / d1; 
		
		uint256 lp_price = calculate_lp_token_price(
			total_supply, 
			prices[0],
			prices[1],
			reserve0,
			reserve1
		); 

		return lp_price; 
	}
	
	//where total supply is the total supply of the LP token
	//assumes that prices passed in are already properly WAD scaled
	function calculate_lp_token_price(
		uint256 total_supply,
		uint256 price0,
		uint256 price1,
		uint256 reserve0,
		uint256 reserve1
	) internal pure returns (uint256) {
		uint256 a = nthroot(2, reserve0 * reserve1); //square root
		uint256 b = nthroot(2, price0 * price1); //this is in decimals of chainlink oracle
		//we want a and total supply to have same number of decimals so c has decimals of chainlink oracle
		uint256 c = 2 * a * b / total_supply; 

		return c; 
	}

}







