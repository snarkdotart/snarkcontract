var SnarkOfferBid = artifacts.require('SnarkOfferBid');
var SnarkBase = artifacts.require('SnarkBase');
var SnarkERC721 = artifacts.require('SnarkERC721');
var SnarkLoan = artifacts.require('SnarkLoan');
var SnarkTestFunctions = artifacts.require('SnarkTestFunctions');


var schemeId;
var BigNumber = require('bignumber.js');

var chai = require('chai');
var testFunctions = require('./testFunctions.js')
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
expect = chai.expect;

contract('SnarkBase', async accounts => {
  let instance_snarkbase = null;
  before(async () => {
    instance_offer = await SnarkOfferBid.deployed();
    instance_snarkbase = await SnarkBase.deployed();
    instance_erc = await SnarkERC721.deployed();
    instance_loan = await SnarkLoan.deployed();
    instance_testFunctions = await SnarkTestFunctions.deployed();

  });

  it('1. Add two participant profile scheme. Total equal 100%. Should be accepted.', async () => {
    const participants = [
      '0xC04691B99EB731536E35F375ffC85249Ec713597',
      '0xB94691B99EB731536E35F375ffC85249Ec717233'
    ];
    const profits = [88, 12];

    let retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
    assert.equal(retval.toNumber(), 0);
    await instance_snarkbase.createProfitShareScheme(
      accounts[1],
      participants,
      profits
    );
    const event = instance_snarkbase.ProfitShareSchemeAdded({
      fromBlock: 'latest'
    });
    event.watch(function(error, result) {
      if (!error) {
        schemeId = result.args.profitShareSchemeId.toNumber();
        console.log(`       Scheme ID: ${schemeId}`);
      }
    });

    var bidevent = instance_offer.BidAdded({ fromBlock: 'latest' });
    bidevent.watch(function(error, result) {
      if (!error) {
        var bidder = result.args._bidder;
        var bidId = result.args._bidId;
        var value = result.args._value;
        console.log(
          `       New Bid. Bidder: ${bidder} Id: ${bidId} Value: ${value}`
        );
      }
    });

    var offerevent = instance_offer.OfferAdded({ fromBlock: 'latest' });
    offerevent.watch(function(error, result) {
      if (!error) {
        var owner = result.args._offerOwner;
        var offerId = result.args._offerId;
        var tokenId = result.args._tokenId;
        console.log(
          `       New Offer. Owner: ${owner} Id: ${offerId} Token: ${tokenId}`
        );
      }
    });

    tokenevent = instance_snarkbase.TokenCreated({ fromBlock: 'latest' });
    tokenevent.watch(function(error, result) {
      if (!error) {
        var owner = result.args.tokenOwner;
        var id = result.args.tokenId;
        console.log(`       New Token. Owner: ${owner} Id: ${id}`);
      }
    });

    loanevent = instance_loan.LoanCreated({ fromBlock: 'latest' });
    loanevent.watch(function(error, result) {
      if (!error) {
        var owner = result.args.loanBidOwner;
        var id = result.args.loanId;
        var tokens = result.args.unacceptedTokens;

        console.log(
          `       New Loan. Owner: ${owner} Id: ${id} UnacceptedTokens Number: ${
            tokens.length
          }`
        );
      }
    });

    loanaccepted = instance_loan.LoanAccepted({ fromBlock: 'latest' });
    loanaccepted.watch(function(error, result) {
      if (!error) {
        var loanId = result.args.loanId;
        var tokenId = result.args.tokenId;
        var tokenOwner = result.args.tokenOwner;

        console.log(
          `       Loan Accepted. Id: ${loanId} TokenId: ${tokenId} TokenOwner: ${tokenOwner}`
        );
      }
    });

    loandeclined = instance_loan.LoanDeclined({ fromBlock: 'latest' });
    loandeclined.watch(function(error, result) {
      if (!error) {
        var loanId = result.args.loanId;
        var tokenId = result.args.tokenId;
        var tokenOwner = result.args.tokenOwner;

        console.log(
          `       Loan Declined. Id: ${loanId} TokenId: ${tokenId} TokenOwner: ${tokenOwner}`
        );
      }
    });
  });

  it('2. Add new token.', async () => {
    const limitedEdition = 1;
    const profitShareFromSecondarySale = 0;
    const tokenUrl = 'http://snark2.art';
    const profitShareSchemeId = 1;
    const decriptionUrl = 'big-secret'
    const decorationUrl = 'ipfs://decorator.io'


    var tokenHash = web3.sha3('test');

    var a = [limitedEdition, profitShareFromSecondarySale, profitShareSchemeId]
    var b = [false, false]

    await instance_snarkbase.addToken(
      accounts[1],
      tokenHash,
      tokenUrl,
      decorationUrl,
      decriptionUrl,
      a, 
      b,
      { from: accounts[0] }
    );

    retval = await instance_snarkbase.getTokensCountByOwner(accounts[1]);
    assert.equal(retval.toNumber(), 1, 'Accounts[1] should have one token');
  });

  
  it('3. Create two loans for same period shifted only by 1 ms. Second loan should be rejected.', async () => {
    const startDateTimestamp1 = new Date().getTime() / 1000 + 0*24 * 3600;
    const duration = 10;
    await expect(instance_loan.createLoan([1], startDateTimestamp1, duration)).to.be.eventually.fulfilled;
    let count = await instance_testFunctions.getCountLoanRequestsForTokenOwner(accounts[1])
    console.log('Loan counter: ', count.toNumber())

    let loanIndex = await instance_testFunctions.getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(accounts[1], 1, 1)
    console.log('Loan index for tokenId and loanId : ', loanIndex.toNumber())

    await expect(instance_loan.createLoan([1], startDateTimestamp1 + 1, duration)).to.be.eventually.fulfilled;
    count = await instance_testFunctions.getCountLoanRequestsForTokenOwner(accounts[1])
    console.log('Loan counter: ', count.toNumber())

    loanIndex = await instance_testFunctions.getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(accounts[1], 1, 1)
    console.log('Loan index for tokenId and loanId : ', loanIndex.toNumber())
    await expect(instance_loan.acceptLoan(1,[1],{from:accounts[1]}),"Should be able to accept Loan 1").to.be.eventually.fulfilled;
    await expect(instance_loan.acceptLoan(2,[1],{from:accounts[1]})," Should be able to accept Loan 2").to.be.eventually.fulfilled;
    
    
    let tokensList1 = await instance_loan.getTokenListsOfLoanByTypes(1)
    let tokensList2 = await instance_loan.getTokenListsOfLoanByTypes(2)
    testFunctions.showLoanTokens(tokensList1,"Loan #1 Tokens")
    testFunctions.showLoanTokens(tokensList2,"Loan #2 Tokens")

    expect(tokensList1[1].length, "There should be one token in approved list for loan #1").to.be.equal(1)
    expect(tokensList2[1].length, "There should be NO token in approved list for loan #2").to.be.equal(0)
    expect(tokensList2[2].length, "There should be one token in declined list for loan #2").to.be.equal(1)
  });
});
