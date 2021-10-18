pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPools {
	// Struct to store data about a liquidity pool pair
	struct LiquidityPoolData {
		address tokenA;
		address tokenB;
		uint256 constantProduct;
		mapping(address => uint256) providerAmount;
	}
	
	// Mapping from a unqiue liquidity pool pair ID to the pair data
	mapping(bytes20 => liquidityPoolData) private lpData;

	/**
	 * @dev Creates a liquidity pool between tokenA and tokenB.
	 * @param tokenA Address of the first ERC20 token
	 * @param tokenB Adderss of the second ERC20 token
	 * @param aAmt The amount of tokenA to be provided
	 * @param aBmt The amount of tokenB to be provided
  	 *	
	 * The user should have approved this contract for tokenA and tokenB to an
	 * amount equal or greater than aAmt for tokenA and bAmt for tokenB.
	 * The pool must not already exist and both addresses.
	 * The given address is assumed to be an ERC20 contract.
	 */
	function createLp(
		address calldata tokenA,
		address calldata tokenB,
		uint256 aAmt,
		uint256 bAmt
	) public {
		// Get the unique liquidity pool ID
		bytes20 lpId = calcLpId(tokenA, tokenB);
		// Check if a pool already exists
		require(lpData[lpId].constantProduct == 0, "Already exists");
		// Transfer tokens to this contract
		bool aRes = IERC20(tokenA).transferFrom(msg.sender, address(this), aAmt);
		bool bRes = IERC20(tokenB).transferFrom(msg.sender, address(this), bAmt);
		// If either of the transfers failed then revert
		require(aRes && bRes, "Transfer failed");
		// Fill data into the struct containing information on the new pool
		LiquidityPoolData storage _lpData = lpData[lpId];
		_lpData.tokenA = tokenA;
		_lpData.tokenB = tokenB;
		_lpData.constantProduct = aAmt * bAmt;
		// This tracks how much msg.sender has added to the liquidity pool
		_lpData.providerAmount[msg.sender] = aAmt;
	}

	/**
	 * @dev Adds funds to liquidity pool
	 * @param lpId The ID for the pool to have liquidity added to
	 * @param aAmt The amount of tokenA to be provided
	 * @param aBmt The amount of tokenB to be provided
	 * 
     * Typically less than aAmt or bAmt will be used in order to properly
	 * choose the right amount of tokens to keep the constantProduct the same.
	 * The user should have approved this contract for tokenA and tokenB to an
	 * amount equal or greater than aAmt for tokenA and bAmt for tokenB.
	 */
	function addToLp(bytes20 lpId, aAmt, bAmt) public {
		// TODO Math stuff here, I have to figure it out	
	}

	/**
	 * @dev Removes liquidity from the pool lpId
	 * @param lpId The ID for the pool to have its liquidity removed
	 * @param amount The amount of liquidity to be removed in terms of tokenA
	 */
	function removeFromLp(bytes20 lpId, uint256 amount) public {
		// TODO	
	}

	/**
	 * @dev Returns the amount of liquidity being provided by addr
	 * @param lpId The ID of the pool being checked
	 * @param addr The liquidity provider address being checked
	 * @return Amount of liquidity provided in terms of tokenA 
	 */
	function getAmountProvided(
		bytes20 lpId,
		address calldata addr
	) returns (uint256) {
		return lpData[lpId].providerAmount[addr];
	}

	/**
	 * @dev Calculates the liquidity pool ID based on token addresses.
	 * @param a1 Address of token1
	 * @param a2 Address of token2
	 * @return The unique ID for a pool between a1 and a2
	 *
	 * Calculation is done by XOR of the byte-data of both addresses.
	 * Will return a liqidity pool ID event if the given ID does not exist.
	 * It simply calculates what the ID would be.
	 */
	function calcLpId(
		address calldata a1,
		address calldata a2
	) public pure returns (bytes20) {
		return bytes20(bytesA1) ^ bytes20(bytesA2);
	}

	/**
	 * @dev Indicates whether a pool with lpId exists
	 * @param lpId The ID of the pool being checked
	 * @return True if pool exists, otherwise false
	 */
	function poolExists(bytes20 lpId) public view returns (bool) {
		if(lpData[lpId]).constantProduct == 0) {
			return false;
		}
		return true;
	}
}
