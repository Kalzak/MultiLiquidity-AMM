//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool {
	// Struct to store data about a liquidity pool pair
	struct LiquidityPoolData {
		address tokenA;
		address tokenB;
		uint256 tokenAAmt;
		uint256 tokenBAmt;
		uint256 constantProduct;
		// This tracks how much msg.sender has added to the liquidity pool
		mapping(address => uint256) providerAmount;
	}
	
	// Mapping from a unqiue liquidity pool pair ID to the pair data
	mapping(bytes20 => LiquidityPoolData) private lpData;

	/**
	 * @dev Creates a liquidity pool between tokenA and tokenB.
	 * @param tokenA Address of the first ERC20 token
	 * @param tokenB Adderss of the second ERC20 token
	 * @param aAmt The amount of tokenA to be provided
	 * @param bAmt The amount of tokenB to be provided
  	 *	
	 * The user should have approved this contract for tokenA and tokenB to an
	 * amount equal or greater than aAmt for tokenA and bAmt for tokenB.
	 * The pool must not already exist and both addresses.
	 * The given address is assumed to be an ERC20 contract.
	 */
	function createLp(
		address tokenA,
		address tokenB,
		uint256 aAmt,
		uint256 bAmt
	) public {
		// Get the unique liquidity pool ID
		bytes20 lpId = calcLpId(tokenA, tokenB);
		// Check if a pool already exists
		require(lpData[lpId].constantProduct == 0, "Already exists");
		// Check that aAmt and bAmt are above zero
		require(aAmt > 0 && bAmt > 0, "aAmt or bAmt is zero");
		// Transfer tokens to this contract
		IERC20(tokenA).transferFrom(msg.sender, address(this), aAmt);
		IERC20(tokenB).transferFrom(msg.sender, address(this), bAmt);
		// Fill data into the struct containing information on the new pool
		LiquidityPoolData storage _lpData = lpData[lpId];
		_lpData.tokenA = tokenA;
		_lpData.tokenB = tokenB;
		_lpData.tokenAAmt = aAmt;
		_lpData.tokenBAmt = bAmt;
		_lpData.constantProduct = aAmt * bAmt;
		_lpData.providerAmount[msg.sender] = aAmt;
	}

	/**
	 * @dev Adds funds to liquidity pool
	 * @param lpId The ID for the pool to have liquidity added to
	 * @param aAmt The amount of tokenA to be provided. The amount of tokenB
 	 *             to be provided is calculated from aAmt
	 * 
     * Typically less than aAmt or bAmt will be used in order to properly
	 * choose the right amount of tokens to keep the constantProduct the same.
	 * The user should have approved this contract for tokenA and tokenB to an
	 * amount equal or greater than aAmt for tokenA and bAmt for tokenB.
	 */
	function addToLp(bytes20 lpId, uint256 aAmt) public {
		// Calculate the amount of each token to add to the LP
		uint256 bAmt = calcTokenBAmount(lpId, aAmt);
		// Load the lpData struct
		LiquidityPoolData storage _lpData = lpData[lpId];
		// Get the addresses of the tokens
		address tokenA = _lpData.tokenA;
		address tokenB = _lpData.tokenB;
		// Increment the lpData total pool size
		_lpData.tokenAAmt += aAmt;
		_lpData.tokenBAmt += bAmt;
		// Store the amount that the user has contributed to the pool
		_lpData.providerAmount[msg.sender] += aAmt;
		// Transfer the tokens to the contract
		IERC20(tokenA).transferFrom(msg.sender, address(this), aAmt);
		IERC20(tokenB).transferFrom(msg.sender, address(this), bAmt);
	}

	/**
	 * @dev Removes liquidity from the pool lpId
	 * @param lpId The ID for the pool to have its liquidity removed
	 * @param removeAmount The amount of liquidity to be removed in terms of tokenA
	 */
	function removeFromLp(bytes20 lpId, uint256 removeAmount) public {
		// Load the lpData struct
		LiquidityPoolData storage _lpData = lpData[lpId];
		// Ensure user is not removing more than they own and amount is nonzero
		require(removeAmount != 0);
		require(_lpData.providerAmount[msg.sender] >= removeAmount);
		// Calculate how much to be removed
		uint256 aRetAmt = removeAmount;
		uint256 bRetAmt = calcTokenBAmount(lpId, aRetAmt);
		// Update the pool data (done before transfer to avoid reentrancy)
		_lpData.tokenAAmt -= aRetAmt;
		_lpData.tokenBAmt -= bRetAmt;
		_lpData.providerAmount[msg.sender] -= aRetAmt;
		// Get the addresses of the tokens
		address tokenA = _lpData.tokenA;
		address tokenB = _lpData.tokenB;
		// Return the tokens to the user
		IERC20(tokenA).transfer(msg.sender, aRetAmt);
		IERC20(tokenB).transfer(msg.sender, bRetAmt);

		
	}

	/**
	 * @dev Given a number of tokenA caluclate how much tokenB is needed to
	 *      keep the same ratio between the pair
	 * @param lpId The ID of the liquidity pool 
	 * @param aUserAmt The amount of tokenA that the user is adding or removing
	 * @return The amount of tokenB that should be added or removed
	 *
	 * This will be called internally when adding or removing liquidity
	 * Users can also call it externally to find out how many tokens they have
	 * to approve before adding liquidity
	 */
	function calcTokenBAmount(
		bytes20 lpId,
		uint256 aUserAmt
	) public view returns (uint256) {
		// Get current amount of each token in the pool
		uint256 aLpAmt = lpData[lpId].tokenAAmt;
		uint256 bLpAmt = lpData[lpId].tokenBAmt;
		// Calculate and return the necessary amount of tokens
		return bLpAmt * (aUserAmt/aLpAmt);
	}

	/**
	 * @dev Returns the amount of liquidity being provided by addr
	 * @param lpId The ID of the pool being checked
	 * @param addr The liquidity provider address being checked
	 * @return Amount of liquidity provided in terms of tokenA 
	 */
	function getAmountProvided(
		bytes20 lpId,
		address addr
	) public view returns (uint256) {
		return lpData[lpId].providerAmount[addr];
	}

	/**
	 * @dev Calculates the liquidity pool ID based on token addresses.
	 * @param addr1 Address of token1
	 * @param addr2 Address of token2
	 * @return The unique ID for a pool between a1 and a2
	 *
	 * Calculation is done by XOR of the byte-data of both addresses.
	 * Will return a liqidity pool ID event if the given ID does not exist.
	 * It simply calculates what the ID would be.
	 */
	function calcLpId(
		address addr1,
		address addr2
	) public pure returns (bytes20) {
		return bytes20(addr1) ^ bytes20(addr2);
	}

	/**
	 * @dev Indicates whether a pool with lpId exists
	 * @param lpId The ID of the pool being checked
	 * @return True if pool exists, otherwise false
	 */
	function poolExists(bytes20 lpId) public view returns (bool) {
		if(lpData[lpId].constantProduct == 0) {
			return false;
		}
		return true;
	}
}
