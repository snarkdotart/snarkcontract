var SnarkOfferBid = artifacts.require('SnarkOfferBid');
var SnarkBase = artifacts.require('SnarkBase');
var SnarkERC721 = artifacts.require('SnarkERC721');
var SnarkLoan = artifacts.require('SnarkLoan');
var SnarkLoanLib = artifacts.require('SnarkLoanLib');

var schemeId;
var BigNumber = require('bignumber.js');

var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
expect = chai.expect;

function showLoanTokens(tokens, title) {
 
  let t0 = ''
  let t1 = ''
  let t2 = ''
  console.log('Tokens 0: ', tokens[0])
  console.log('Tokens 1: ', BigNumber(tokens[1][0]).toString())
  console.log('Tokens 2: ', tokens[2])
  
  for (let i = 0; i < tokens[0].length;i++) {
    t0 = t0 + ' ' + BigNumber(tokens[0][i]).toNumber()
  }

  for (let i = 0; i < tokens[1].length;i++) {
    t1 = t1 + ' ' + BigNumber(tokens[1][i]).toNumber()
  }

  for (let i = 0; i < tokens[2].length;i++) {
    t2 = t2 + ' ' + BigNumber(tokens[2][i]).toNumber()
  }


  var t = [{'Not Approved Tokens' : t0,
          'Approved Tokens' : t1, 
          'Declined Tokens' : t2}
          ]
  console.log('')
  console.log(`     ****** ${title} ******`)
  console.table(t)
}

contract('SnarkBase', async accounts => {
  let instance_snarkbase = null;
  before(async () => {
    instance_offer = await SnarkOfferBid.deployed();
    instance_snarkbase = await SnarkBase.deployed();
    instance_erc = await SnarkERC721.deployed();
    instance_loan = await SnarkLoan.deployed();
    instance_loanlib = await SnarkLoanLib.deployed();
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
    // event LoanDeleted(uint256 loanId);

    loandelete = instance_loan.LoanDeleted({ fromBlock: 'latest' });
    loandelete.watch(function(error, result) {
      if (!error) {
        var id = result.args.loanId;
        console.log(`       Loan deleted !!! Id: ${id}`);
      }
    });
    // event TokenCanceledInLoans(uint256 tokenId, uint256[] loanList);

    tokencancel = instance_loanlib.TokenCanceledInLoans({ fromBlock: 'latest' });
    tokencancel.watch(function(error, result) {
      if (!error) {
        var id = result.args.tokenId;
        var loans = result.args.loanList;
        console.log(`      Token Cancelled !!! Id: ${id} Loans: ${loans}`);
      }
    });

    loanfinished = instance_loan.LoanFinished({ fromBlock: 'latest' });
    loanfinished.watch(function(error, result) {
      if (!error) {
        var id = result.args.loanId;
        console.log(`       Loan finished !!! Id: ${id}`);
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
    let loanstarted = instance_loan.LoanStarted({ fromBlock: 'latest' });
    loanstarted.watch(function(error, result) {
      if (!error) {
        var loanId = result.args.loanId;
        console.log(`       Loan Started. Id: ${loanId}`);
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
    var b = [true, true]

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
    const startDateTimestamp1 = new Date().getTime() / 1000 + 0 *24 * 3600;
    const duration = 1;
    // function createLoan(uint256[] tokensIds, uint256 startDate, uint256 duration) public payable restrictedAccess {
      let tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
      showLoanTokens(tokens, "Before Loan Creation")
      let num = await instance_loan.getNumberOfLoansInTokensLoanList(1)
      console.log('Loans for token 1: ', num.toNumber())

    await expect(instance_loan.createLoan([1,3], startDateTimestamp1, duration)).to.be.eventually.fulfilled;

    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    showLoanTokens(tokens, "After Loan Creation")
    let listOfLoans = await instance_loan.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)

    num = await instance_loan.getNumberOfLoansInTokensLoanList(1)
    console.log('Loans for token 1: ', num.toNumber())

    let saleType = await instance_loan.getSaleTypeToToken(1)
    console.log('Token #1 Sale Type: ', saleType.toNumber())
    
    await expect(instance_loan.startLoan(1,{from:accounts[0]}), "It should be possible to start a Loan").to.be.eventually.fulfilled;
    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    showLoanTokens(tokens, "After Starting Loan")
    listOfLoans = await instance_loan.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)

    saleType = await instance_snarkbase.getSaleTypeToToken(1)
    console.log('Token #1 Sale Type: ', saleType.toNumber())


  });
  
  it('4. Create one offer. Should be rejected because there is active loan.', async () => {
    await expect(instance_offer.addOffer(1,web3.toWei(1,"ether"),{from:accounts[1]}),"Loan is started. Should not be possible to add Offer. ").to.be.eventually.fulfilled
 
    tokens = await instance_loan.getTokenListsOfLoanByTypes(1)
    showLoanTokens(tokens, "After Adding Offer.")

    let listOfLoans = await instance_loan.getListOfLoansFromTokensLoanList(1)
    console.log('List of Loans: ', listOfLoans)
  });

  



});
