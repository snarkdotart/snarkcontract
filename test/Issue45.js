var SnarkOfferBid = artifacts.require('SnarkOfferBid');
var SnarkBase = artifacts.require('SnarkBase');
var SnarkERC721 = artifacts.require('SnarkERC721');
var SnarkLoan = artifacts.require('SnarkLoan');
var SnarkLoanLib = artifacts.require('SnarkLoanLib');
var SnarkTestFunctions = artifacts.require('SnarkTestFunctions');

var schemeId;
var BigNumber = require('bignumber.js');
var datetime = require('node-datetime');

var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
expect = chai.expect;
var testFunctions = require('./testFunctions.js')


contract('SnarkBase', async accounts => {
  let instance_snarkbase = null;
  before(async () => {
    instance_offer = await SnarkOfferBid.deployed();
    instance_snarkbase = await SnarkBase.deployed();
    instance_erc = await SnarkERC721.deployed();
    instance_loan = await SnarkLoan.deployed();
    instance_loanlib = await SnarkLoanLib.deployed();
    instance_testFunctions = await SnarkTestFunctions.deployed();
  });

  it('1. Add two participant profile scheme. Total equal 100%. Should be accepted.', async () => {
    const participants = [
      accounts[0],
      accounts[1]
    ];
    const profits = [88, 12];

    let retval = await instance_snarkbase.getProfitShareSchemesTotalCount();
    assert.equal(retval.toNumber(), 0);
    await instance_snarkbase.createProfitShareScheme(
      accounts[1],
      participants,
      profits
    );
    
    instance_snarkbase.ProfitShareSchemeAdded({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        schemeId = result.args.profitShareSchemeId.toNumber();
        console.log(`       Scheme ID: ${schemeId}`);
      }
    });

    instance_offer.BidAdded({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var bidder = result.args._bidder;
        var bidId = result.args._bidId;
        var value = result.args._value;
        console.log(
          `       New Bid. Bidder: ${bidder} Id: ${bidId} Value: ${value}`
        );
      }
    });

    instance_offer.OfferAdded({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var owner = result.args._offerOwner;
        var offerId = result.args._offerId;
        var tokenId = result.args._tokenId;
        console.log(
          `       New Offer. Owner: ${owner} Id: ${offerId} Token: ${tokenId}`
        );
      }
    });

    instance_loan.LoanDeleted({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var id = result.args.loanId;
        console.log(`       Loan deleted !!! Id: ${id}`);
      }
    });

    instance_loanlib.TokenCanceledInLoans({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var id = result.args.tokenId;
        var loans = result.args.loanList;
        console.log(`      Token Cancelled !!! Id: ${id} Loans: ${loans}`);
      }
    });

    loanfinished = instance_loan.LoanFinished({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var id = result.args.loanId;
        console.log(`       Loan finished !!! Id: ${id}`);
      }
    });

    instance_snarkbase.TokenCreated({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var owner = result.args.tokenOwner;
        var id = result.args.tokenId;
        console.log(`       New Token. Owner: ${owner} Id: ${id}`);
      }
    });

    instance_loan.LoanCreated({ fromBlock: 'latest' }, function(error, result) {
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

    instance_loan.LoanAccepted({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var loanId = result.args.loanId;
        var tokenId = result.args.tokenId;
        var tokenOwner = result.args.tokenOwner;

        console.log(
          `       Loan Accepted. Id: ${loanId} TokenId: ${tokenId} TokenOwner: ${tokenOwner}`
        );
      }
    });

    instance_loan.LoanStarted({ fromBlock: 'latest' }, function(error, result) {
      if (!error) {
        var loanId = result.args.loanId;
        console.log(`       Loan Started. Id: ${loanId}`);
      }
    });

    instance_loan.LoanDeclined({ fromBlock: 'latest' }, function(error, result) {
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
    const decriptionUrl = 'big-secret';
    const decorationUrl = 'ipfs://decorator.io';
    var tokenHash = web3.utils.sha3('test');

    var a = [limitedEdition, profitShareFromSecondarySale, profitShareSchemeId];
    var b = [true, true];

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
    await instance_snarkbase.addToken(
      accounts[1],
      tokenHash+'1',
      tokenUrl,
      decorationUrl,
      decriptionUrl,
      a, 
      b,
      { from: accounts[0] }
  );
    await instance_snarkbase.addToken(
      accounts[1],
      tokenHash+'2',
      tokenUrl,
      decorationUrl,
      decriptionUrl,
      a, 
      b,
      { from: accounts[0] }
  );

    retval = await instance_snarkbase.getTokensCountByOwner(accounts[1]);
    assert.equal(retval.toNumber(), 3, 'Accounts[1] should have one token');
  });

  it('3. Create and start loan. Should be accepted. Loan is auto accepted.', async () => {
    const startDateTimestamp1 = datetime.create(new Date()).getTime();
    const duration = 1;
    // function createLoan(uint256[] tokensIds, uint256 startDate, uint256 duration) public payable restrictedAccess {
      let tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
      testFunctions.showLoanTokens(tokens, "Before Loan Creation")
      let num = await instance_testFunctions.getNumberOfLoansInTokensLoanList(1)
      console.log('Loans for token 1: ', num.toNumber())

    await expect(instance_loan.createLoan([1,3], startDateTimestamp1, duration)).to.be.eventually.fulfilled;

    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    testFunctions.showLoanTokens(tokens, "After Loan Creation")
    let listOfLoans = await instance_testFunctions.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)

    num = await instance_testFunctions.getNumberOfLoansInTokensLoanList(1)
    console.log('Loans for token 1: ', num.toNumber())

    let saleType = await instance_testFunctions.getSaleTypeToToken(1)
    console.log('Token #1 Sale Type: ', saleType.toNumber())
    
    await expect(instance_loan.startLoan(1,{from:accounts[0]}), "It should be possible to start a Loan").to.be.eventually.fulfilled;
    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    testFunctions.showLoanTokens(tokens, "After Starting Loan")
    listOfLoans = await instance_testFunctions.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)

    saleType = await instance_testFunctions.getSaleTypeToToken(1)
    console.log('Token #1 Sale Type: ', saleType.toNumber())


  });
  
  it('4. Create one offer. Should be rejected because there is active loan.', async () => {
    await expect(instance_offer.addOffer(1,web3.utils.toWei('1',"ether"),{from:accounts[1]}),"Loan is started. Should not be possible to add Offer. ").to.be.eventually.rejected
 
    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    testFunctions.showLoanTokens(tokens, "After Adding Offer.")

    let listOfLoans = await instance_testFunctions.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)
  });

  



});
