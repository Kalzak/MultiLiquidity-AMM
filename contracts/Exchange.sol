//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidityPool.sol";

contract Exchange is LiquidityPool {
	/**
	 * @dev Quotes the amount of token x you will recieve for a number of token y
	 * @param lpId The ID of the liquidity pool to quote an exchange from
	 * @param direction True = A to B exchange, False = B to A exchange
	 * @param inputAmount The amount of token `addr` that the user is quoting
	 * @return The amount of the other token that will be recieved in an exchange
	 */
	function quoteExchange(
		bytes20 lpId,
		bool direction,
		uint256 inputAmount
	) public view poolExists(lpId) returns (uint256) {
		// Get the data for the given LpID
		LiquidityPoolData storage _lpData = lpData[lpId];
		uint256 aAmt = _lpData.tokenAAmt;
		uint256 bAmt = _lpData.tokenBAmt;
		uint256 cP = _lpData.constantProduct;
		// Return quote depending which way the exchange will be
		if(direction == true) {
			return bAmt - (cP / (aAmt + inputAmount));
		} else {
			return aAmt - (cP / (bAmt + inputAmount));
		}
	}
	
	/**
	 * @dev Exchanges token x for token y
	 * @param lpId The ID of the liquidity pool to quote an exchange from
	 * @param direction True = A to B exchange, False = B to A exchange
	 * @param inputAmount The amount of token `addr` that the user is quoting
	 */
	function exchange(
		bytes20 lpId,
		bool direction,
		uint256 inputAmount
	) public poolExists(lpId) {
		// Get the data for the given LpID
		LiquidityPoolData storage _lpData = lpData[lpId];
		uint256 aAmt = _lpData.tokenAAmt;
		uint256 bAmt = _lpData.tokenBAmt;
		uint256 cP = _lpData.constantProduct;
		// Return quote depending which way the exchange will be
		if(direction == true) {
			// Calculate the amount that would be received
			uint256 outputAmount = bAmt - (cP / (aAmt + inputAmount));
			// Update the liquidity pool data
			_lpData.tokenAAmt += inputAmount;
			_lpData.tokenBAmt -= outputAmount;
			// Transfer tokens
			IERC20(_lpData.tokenA).transferFrom(msg.sender, address(this), inputAmount);
			IERC20(_lpData.tokenB).transferFrom(address(this), msg.sender, outputAmount);
		} else {
			// Calculate the amount that would be received
			uint256 outputAmount = aAmt - (cP / (bAmt + inputAmount));
			// Update the liquidity pool data
			_lpData.tokenAAmt += inputAmount;
			_lpData.tokenBAmt -= outputAmount;
			// Transfer tokens
			IERC20(_lpData.tokenB).transferFrom(msg.sender, address(this), inputAmount);
			IERC20(_lpData.tokenA).transferFrom(address(this), msg.sender, outputAmount);
		}
	}
}	
