const { expect } = require("chai");

describe("Exchange contract", function() {

	// Contract variables
	let exchange;
	let token1;
	let token2;
	let token3;
	// Account variables
	let owner;
	let addr1;
	let addr2;
	// Misc useful variables
	const amountToMint = 50000n * 10n ** 18n;
	
	before(async function() {
		// Deploy the liquidity pool contract
		const exchangeFactory = await ethers.getContractFactory("Exchange");
		exchange = await exchangeFactory.deploy();
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
		// Approve spend of token	
		let addr2BalT1 = await approveSpend(token1, addr2, exchange, -1);
		let addr2BalT2 = await approveSpend(token2, addr2, exchange, -1);
		// Create pool
		await exchange.connect(addr2).createLp(token1.address, token2.address, addr2BalT1, addr2BalT2.div(2));
	});

	describe("quoteExchange", function() {
		it("Cannot quote invalid lpId", async function() {
			await expect(
				// Attempt to quote with invalid liquidity pool ID
				exchange.quoteExchange("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", true, 1)
			).to.be.revertedWith("Pool non-existent");
		});

		it("Correct return value", async function() {
			let lpId = await exchange.calcLpId(token1.address, token2.address);
			let quote = await exchange.quoteExchange(lpId, true, 1000n * 10n ** 18n);
			expect(quote.toString()).to.equal("490196078431372549020");
		});
	});

	describe("exchange", function() {
		it("Cannot quote invalid lpId", async function() {
			await expect(
				// Attempt to quote with invalid liquidity pool ID
				exchange.exchange("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", true, 1)
			).to.be.revertedWith("Pool non-existent");
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
