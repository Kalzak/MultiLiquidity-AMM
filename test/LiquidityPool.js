const { expect } = require("chai");

describe("LiquidityPool contract", function() {

	// Contract variables
	let liquidityPool;
	let token1;
	let token2;
	let token3;
	// Account variables
	let owner;
	let addr1;
	let addr2;
	// Misc useful variables
	const amountToMint = 50000n * 10n ** 18n
	
	before(async function() {
		// Deploy the liquidity pool contract
		const liquidityPoolFactory = await ethers.getContractFactory("LiquidityPool");
		liquidityPool = await liquidityPoolFactory.deploy();
		// Get accounts
		[owner, addr1, addr2] = await ethers.getSigners();
	});

	beforeEach(async function() {
		// Deploy tokens
		const tokenFactory = await ethers.getContractFactory("GenericToken");
		token1 = await tokenFactory.deploy("t1", "token1");
		token2 = await tokenFactory.deploy("t2", "token2");
		token3 = await tokenFactory.deploy("t3", "token3");
		// Mint 150,000 of each token
		await token1.mint(owner.address, amountToMint);
		await token1.mint(addr1.address, amountToMint);
		await token1.mint(addr2.address, amountToMint);
		await token2.mint(owner.address, amountToMint);
		await token2.mint(addr1.address, amountToMint);
		await token2.mint(addr2.address, amountToMint);
		await token3.mint(owner.address, amountToMint);
		await token3.mint(addr1.address, amountToMint);
		await token3.mint(addr2.address, amountToMint);
	});

	describe("createLp", function() {
		it("Pool of size zero cannot be made", async function() {
			// Approve spend of token	
			await approveSpend(token1, owner, liquidityPool, -1);	
			await approveSpend(token2, owner, liquidityPool, -1);	
			// Attempt to create pool with zero amount
			await expect(
				liquidityPool.createLp(token1.address, token2.address, '0', '0')
			).to.be.revertedWith("aAmt or bAmt is zero");
		});
		
		it("Pool is not made when user tokens are not approved", async function() {
			let ownerBalT1 = await token1.balanceOf(owner.address);
			let ownerBalT2 = await token2.balanceOf(owner.address);
			// Attempt to crete pool 
			await expect(
				liquidityPool.createLp(token1.address, token2.address, ownerBalT1, ownerBalT2)
			).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
		});

		it("Pool can be created", async function() {
			// Approve spend of token	
			let ownerBalT1 = await approveSpend(token1, owner, liquidityPool, -1);
			let ownerBalT2 = await approveSpend(token2, owner, liquidityPool, -1);
			// Create pool
			await liquidityPool.createLp(token1.address, token2.address, ownerBalT1, ownerBalT2);
		});

		it("Same token pool cannot be created twice", async function() {
			// Approve spend of token	
			let ownerBalT1 = await approveSpend(token1, owner, liquidityPool, -1);
			let ownerBalT2 = await approveSpend(token2, owner, liquidityPool, -1);
			// Create pool
			await liquidityPool.createLp(token1.address, token2.address, ownerBalT1, ownerBalT2);
			// Create pool again
			await expect(
				liquidityPool.createLp(token1.address, token2.address, ownerBalT1, ownerBalT2)
			).to.be.revertedWith("Already exists");
		});


	});
});

// A function to approve a spend on a token to de-clutter test code
// If `amount` is -1 then approve for max balance of `account`
async function approveSpend(token, fromAccount, toAccount, amount) {
	// Get amount to approve
	let amountToApprove;
	if(amount == -1) {
		amountToApprove = await token.balanceOf(fromAccount.address);
	} else {
		amountToApprove = amount;
	}
	await token.connect(fromAccount).approve(toAccount.address, amountToApprove);
	// Return the amount approved
	return amountToApprove;
}
