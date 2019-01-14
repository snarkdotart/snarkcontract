pragma solidity ^0.4.25;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


/// @title Contract provides a functionality to work with loans
/// @author Vitali Hurski
contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    address private _storage;
    address private _erc721;

    event LoanCreated(
        address indexed loanBidOwner, 
        uint256 loanId, 
        uint256[] unacceptedTokens
    );

    event LoanAccepted(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanDeclined(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanStarted(uint256 loanId);
    event TokensBorrowed(address indexed loanOwner, uint256[] tokens);
    event LoanFinished(uint256 loanId);
    event LoanDeleted(uint256 loanId);
    event TokenCanceledInLoans(uint256 tokenId, uint256[] loanList);

    modifier restrictedAccess() {
        if (_storage.isRestrictedAccess()) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }    

    modifier correctLoan(uint256 loanId) {
        require(loanId > 0 && loanId <= _storage.getTotalNumberOfLoans(), "Loan id is wrong");
        _;
    }

    modifier onlyLoanOwner(uint256 loanId) {
        require(msg.sender == _storage.getOwnerOfLoan(loanId), "Only loan owner can borrow tokens");
        _;
    }

    /// @dev Constructor of contract
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address storageAddress, address erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }
    
    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy the contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    function setDefaultLoanDuration(uint256 duration) public onlyOwner {
        _storage.setDefaultLoanDuration(duration);
    }

    function getDefaultLoanDuration() public view returns (uint256) {
        return _storage.getDefaultLoanDuration();
    }

    /// @dev attributes of startDate input should be in the format datetime
    /// without consideration for time, for example: 1298851200000 => 2011-02-28T00:00:00.000Z
    /// duration - simple number in days, example 10 (days)
    function createLoan(uint256[] tokensIds, uint256 startDate, uint256 duration) public payable restrictedAccess {
        require(duration <= getDefaultLoanDuration(), "Duration exceeds a max value");
        // check if the user requested their own tokens
        for (uint256 i = 0; i < tokensIds.length; i++) {
            require(tokensIds[i] <= _storage.getTotalNumberOfTokens(), "Token id has to be valid");
            require(
                _storage.getOwnerOfToken(tokensIds[i]) != msg.sender,
                "Borrower can't request loan for their own tokens"
            );
            // check that the token is not being sold 
            require(_storage.getSaleTypeToToken(
                tokensIds[i]) != uint256(SaleType.Offer), 
                "Token's sale type cannot be 'Offer'"
            );
        }
         // Transfer money funds into the contract 
        if (msg.value > 0) { 
            _storage.transfer(msg.value);
            _storage.addPendingWithdrawals(_storage, msg.value); 
        }
        // Create new entry for a Loan
        uint256 loanId = _storage.createLoan(msg.sender, msg.value, tokensIds, startDate, duration);
        bool isAgree = false;
        for (i = 0; i < tokensIds.length; i++) {
            address tokenOwner = _storage.getOwnerOfToken(tokensIds[i]);
            // storing the token's owner so that the token can be returned to them 
            _storage.setActualTokenOwnerForLoan(loanId, tokensIds[i], tokenOwner);
            if (_storage.isTokenBusyForPeriod(tokensIds[i], startDate, duration)) {
                // if there is a schedule conflict, token is moved to Declined List - 2
                _storage.addTokenToListOfLoan(loanId, tokensIds[i], 2);
            } else {
                isAgree = (msg.sender == owner) ? 
                    _storage.isTokenAcceptOfLoanRequestFromSnark(tokensIds[i]) :
                    _storage.isTokenAcceptOfLoanRequestFromOthers(tokensIds[i]);
                if (isAgree) {
                    // storing the reserved period in the calendar and the loan that created the reserve 
                    _storage.makeTokenBusyForPeriod(loanId, tokensIds[i], startDate, duration);
                    // token is moved to the Approved List - 1
                    _storage.addTokenToListOfLoan(loanId, tokensIds[i], 1);
                } else {
                    _storage.addLoanRequestToTokenOwner(
                        tokenOwner,
                        tokensIds[i],
                        loanId
                    );
                }
            }
        }
        emit LoanCreated(msg.sender, loanId, _storage.getTokensListOfLoanByType(loanId, 0));
    }

    /// @notice owner agrees with the loan request for their token 
    function acceptLoan(uint256 loanId, uint256[] tokenIds) public {
        require(tokenIds.length > 0, "Array of tokens can't be empty");
        // it is possible to accept loan request only prior to loan start 
        // and need to make sure that the loan request is still active and was not cancelled 
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' of 'Finished' status"
        );

        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        uint256 numberOfTokens = _storage.getOwnedTokensCount(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] <= numberOfTokens, "Token doesnt exist or you are not an owner.");

            address _ownerOfToken = _storage.getOwnerOfToken(tokenIds[i]);
            require(msg.sender == _ownerOfToken, "Only the token owner can accept a loan request.");

            uint256 _saleType = _storage.getSaleTypeToToken(tokenIds[i]);
            require(_saleType != uint256(SaleType.Offer), "Token's sale type cannot be 'Offer'");

            // check if the token is available for the requested dates 
            if (_storage.isTokenBusyForPeriod(tokenIds[i], startDate, duration)) {
                // tokens with date conflicts are moved to Declined list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 2);
                // Create notification that loan request is declined
                emit LoanDeclined(msg.sender, loanId, tokenIds[i]);
            } else {
                // available token is moved to Approved list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 1);
                // mark the requested loan dates in the calendar 
                _storage.makeTokenBusyForPeriod(loanId, tokenIds[i], startDate, duration);
                // Create notification that loan request is Approved
                emit LoanAccepted(msg.sender, loanId, tokenIds[i]);
            }
            // remove loan request from the token owner for the specific token and specific loan
            _storage.deleteLoanRequestFromTokenOwner(loanId, tokenIds[i]);
        }
    }

    /// @notice Mark that the loan started. Function should be very simple,
    /// since the payment will be made by Snark
    /// @dev After the function is called it is necessary to assess the need to estimate cost of the function StopLoan
    /// from backend with the help of contractInstance.method.estimateGas(ARGS...) and write
    /// this cost with the help of setCostOfStopLoanOperationForLoan, so that when the call is made for
    /// function borrowTokensOfLoan the user will see the cost necessary to pay for all transfers.
    /// Function should be called only after 1 minute after the start of day (in 0:01), so that
    /// there is certainty that the previous loan has ended. For example, there was a loan 
    /// from 14th of the month for 3 days. So the start should occur on 14th at 0:01, because 13th must be over
    /// if there was a loan for that date and it should end on 14th at 0:00
    /// when the previous loan stops and the next loan begins at 0:01
    function startLoan(uint256 loanId) public onlyOwner correctLoan(loanId) {
        // check that there was not an accidental double launch
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' of 'Finished' status"
        );
        // store for the loan saleStatus = Active
        _storage.setLoanSaleStatus(loanId, 2); // 2 - Active
        uint256 loanPrice = _storage.getPriceOfLoan(loanId);
        // receive the list of tokens that will participate in the loan
        uint256[] memory tokenList = _storage.getTokensListOfLoanByType(loanId, 1);
        require(tokenList.length > 0, "Can not start loan with empty token list");
        // calculate the amount that will be sent to each token owner that agreed to the loan 
        uint256 income = loanPrice.div(tokenList.length);
        for (uint256 i = 0; i < tokenList.length; i++) {
            address tokenOwner = _storage.getActualTokenOwnerForLoan(loanId, tokenList[i]);
            _storage.setSaleTypeToToken(tokenList[i], uint256(SaleType.Loan));
            // share money for the loan between the participants of the accepted tokens 
            if (income > 0) {    
                // withdraw the sum from the contract balance 
                _storage.subPendingWithdrawals(_storage, income);
                // and add the amount to the balance of the token owner 
                // _storage.addPendingWithdrawals(tokenOwner, income);
                SnarkStorage(_storage).transferFunds(tokenOwner, income);
            }
        }
        emit LoanStarted(loanId);
    }

    /// @notice function initiates the transfer of tokens into the wallet of the loan requester,
    /// and the requester needs to pay gas for both transfer to and for transfer back of the tokens 
    function borrowLoanedTokens(uint256 loanId) public payable onlyLoanOwner(loanId) correctLoan(loanId) {
        // call of this function can only be made if the loan is aActive 
        require(_storage.getLoanSaleStatus(loanId) == uint256(SaleStatus.Active), "Loan is not active");
        /*************************************************************/
        // Check that the amount of money that arrived is correct
        uint256 price = _storage.getCostOfStopLoanOperationForLoan(loanId);
        require(msg.value >= price, "");
        // Move the funds to Snark wallet, because it will be used to call 
        // the return of the tokens to their rightful owners after loan ends 
        address snarkWallet = _storage.getSnarkWalletAddress();
        snarkWallet.transfer(msg.value);
        /*************************************************************/
        // if there are tokens left in the list NotApproved, then move them to Declined
        // and delete all loan requests from the list of these token owners 
        uint256[] memory notApprovedTokens = _storage.getTokensListOfLoanByType(loanId, 0);
        for (uint256 i = 0; i < notApprovedTokens.length; i++) {
            _storage.addTokenToListOfLoan(loanId, notApprovedTokens[i], 2);
            // remove requests from tokenOwners
            _storage.deleteLoanRequestFromTokenOwner(loanId, notApprovedTokens[i]);
        }
        // for all tokens in Approved list set saleType = Loan
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (i = 0; i < approvedTokens.length; i++) {
            _storage.setSaleTypeToToken(approvedTokens[i], uint256(SaleType.Loan));
            _storage.transferToken(
                approvedTokens[i], 
                _storage.getOwnerOfToken(approvedTokens[i]), 
                msg.sender
            );
        }

        emit TokensBorrowed(msg.sender, approvedTokens);
    }

    /// @notice Only contract can end loan according to schedule
    /// @dev function must be called at the start of the day, after the end of period, for example,
    /// if the loan is from the 12th of the month for 3 days. 
    /// This means that the function should be called on the 15th at 0:00.
    function stopLoan(uint256 loanId) public onlyOwner correctLoan(loanId) {
        // we can only end an active loan 
        require(_storage.getLoanSaleStatus(loanId) == uint256(SaleStatus.Active), "Loan is not active");
        address loanOwner = _storage.getOwnerOfLoan(loanId);
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (uint256 i = 0; i < approvedTokens.length; i++) {
            _storage.setSaleTypeToToken(approvedTokens[i], uint256(SaleType.None));
            address currentOwnerOfToken = _storage.getOwnerOfToken(approvedTokens[i]);
            // check just in case that the token still belongs to the borrower 
            require(loanOwner == currentOwnerOfToken, "Token owner is not a loan owner yet");
            _storage.transferToken(
                approvedTokens[i],
                loanOwner,
                _storage.getActualTokenOwnerForLoan(loanId, approvedTokens[i])
            );
        }
        // remove loan from the loan owner list 
        _storage.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId);
        
        emit LoanFinished(loanId);
    }

    /// @notice token owner can cancel their loan prior to start of loan 
    function deleteLoan(uint256 loanId) public onlyLoanOwner(loanId) correctLoan(loanId) {
        // check loan status - it must not be Active or Finished
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' or in 'Finished' status"
        );
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        address loanOwner = _storage.getOwnerOfLoan(loanId);
        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        // only need to perform the action on tokens in the Approved list
        uint256[] memory approvedTokens = _storage.getTokensListOfLoanByType(loanId, 1);
        for (uint256 i = 0; i < approvedTokens.length; i++) {
            // remove the booked days from the token calendar 
            _storage.makeTokenFreeForPeriod(approvedTokens[i], startDate, duration);
            // remove the loan request from the token owners 
            _storage.deleteLoanRequestFromTokenOwner(loanId, approvedTokens[i]);
            // remove loan from the loan owner list 
            _storage.deleteLoanFromLoanListOfLoanOwner(loanOwner, loanId);
        }
        // return any loan compensation from the token owner to the loan owner
        uint256 loanPrice = _storage.getPriceOfLoan(loanId);
        if (loanPrice > 0) {
            // withdraw the amount from the contract balance
            _storage.subPendingWithdrawals(_storage, loanPrice);
            // and move it to the balance of loan owner
            // _storage.addPendingWithdrawals(loanOwner, loanPrice);
            SnarkStorage(_storage).transferFunds(loanOwner, loanPrice);
        }

        emit LoanDeleted(loanId);
    }

    /// @notice allow token owner to the remove their token from participation in a loan 
    function cancelTokenInLoan(uint256 tokenId) public {
        require(
            msg.sender == _storage.getOwnerOfToken(tokenId), 
            "Only owner of token can withdraw its token from participation in a loan"
        );
        _storage.setSaleTypeToToken(tokenId, uint256(SaleType.None));
        _storage.cancelTokenInLoan(tokenId);
    }

    /// @notice return tokens in all 3 loan lists
    function getTokenListsOfLoanByTypes(uint256 loanId) public view returns (
        uint256[] notApprovedTokensList,
        uint256[] approvedTokensList,
        uint256[] declinedTokensList)
    {
        notApprovedTokensList = _storage.getTokensListOfLoanByType(loanId, 0);
        approvedTokensList = _storage.getTokensListOfLoanByType(loanId, 1);
        declinedTokensList = _storage.getTokensListOfLoanByType(loanId, 2);
    }

    /// @notice return list of loan request by token owner 
    function getLoanRequestsListOfTokenOwner(address tokenOwner) public view returns (uint256[]) {
        return _storage.getLoanRequestsListForTokenOwner(tokenOwner);
    }

    /// @notice return list of loan borrowers 
    function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[]) {
        return _storage.getLoansListOfLoanOwner(loanOwner);
    }

    /// @notice Return loan detail
    function getLoanDetail(uint256 loanId) public view returns (
        uint256 amountOfNonApprovedTokens,
        uint256 amountOfApprovedTokens,
        uint256 amountOfDeclinedTokens,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        uint256 loanPrice,
        address loanOwner) 
    {
        return _storage.getLoanDetail(loanId);
    }

    /// @notice return cost of gas associated with function StopLoan, 
    /// so that it would be possible to charge this amount to the loan requester during call of borrowLoanedTokens
    function getCostOfStopLoanOperationForLoan(uint256 loanId) public view returns (uint256) {
        return _storage.getCostOfStopLoanOperationForLoan(loanId);
    }

    /// @notice store the gas cost of calling function StopLoan
    function setCostOfStopLoanOperationForLoan(uint256 loanId, uint256 costOfStopOperation) public onlyOwner {
        _storage.setCostOfStopLoanOperationForLoan(loanId, costOfStopOperation);
    }

}
