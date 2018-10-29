pragma solidity ^0.4.24;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    address private _storage;

    event LoanCreated(
        address indexed loanBidOwner, 
        uint256 loanId, 
        uint256[] unacceptedTokens, 
        uint256 numberOfUnaccepted
    );

    event LoanAccepted(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanStarted(uint256 loanId);
    event LoanFinished(uint256 loanId);
    event LoanOfTokenCanceled(uint256 loanId, uint256 tokenId);

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

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }
    
    /// @dev Function to destroy a contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    function setDefaultLoanDuration(uint256 duration) public onlyOwner {
        _storage.setDefaultLoanDuration(duration);
    }

    function getDefaultLoanDuration() public view returns (uint256) {
        return _storage.getDefaultLoanDuration();
    }

    // Loan can be requested by user 
    // Loan can also be requested by Snark
    function createLoan(
        uint256[] tokensIds,
        uint256 startDate,
        uint256 duration
    ) 
        public 
        payable
    {
        require(duration <= getDefaultLoanDuration(), "Duration exceeds a max value");
        // check if the user requested their own tokens
        for (uint256 i = 0; i < tokensIds.length; i++) {
            require(
                _storage.getOwnerOfToken(tokensIds[i]) != msg.sender,
                "Borrower can't request loan for their own tokens"
            );
        }

        // Create new entry for a Loan 
        uint256 loanId = _storage.createLoan(
            tokensIds,
            msg.value,
            startDate,
            duration,
            msg.sender
        );

        // Transfer money funds into the contract 
        if (msg.value > 0) _storage.addPendingWithdrawals(_storage, msg.value);

        // Enter automatic accept for those tokens,
        // that agreed to automatic Loan acceptance 
        uint256 _counter = 0;
        uint256[] memory _unacceptedTokens = new uint256[](tokensIds.length);
        bool isAgree = false;
        for (i = 0; i < tokensIds.length; i++) {
            isAgree = (msg.sender == owner) ? 
                _storage.isTokenAcceptOfLoanRequestFromSnark(tokensIds[i]) :
                _storage.isTokenAcceptOfLoanRequestFromOthers(tokensIds[i]);
            if (!isAgree) {
                _unacceptedTokens[_counter] = tokensIds[i];
                _counter++;
            }
            // Check status of the token ... change of token status is only possible if it is not for sale,
            // Another words, if there is no Offer or existing Loan, then change of status is possible
            uint256 saleType = _storage.getSaleTypeToToken(tokensIds[i]);
            if (isAgree && saleType == uint256(SaleType.None)) {
                // !!! We may need to check the number of days that the token has already been loaned 
                // !!! and if the number of days exceeds the agreed number, then decline the Loan request 
                // !!! Perhaps we should do this check on the front-end during Loan Creation
                address tokenOwner = _storage.getOwnerOfToken(tokensIds[i]);
                _acceptLoan(loanId, tokensIds[i], tokenOwner);
            }
        }

        emit LoanCreated(msg.sender, loanId, _unacceptedTokens, _counter);
    }

    function acceptLoan(uint256[] tokenIds) public {
        require(tokenIds.length > 0, "Array of tokens can't be empty");
        uint256 numberOfTokens = _storage.getOwnedTokensCount(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] <= numberOfTokens, "Token has to be exist");

            address _ownerOfToken = _storage.getOwnerOfToken(tokenIds[i]);
            uint256 _saleType = _storage.getSaleTypeToToken(tokenIds[i]);
            uint256 _loanId = _storage.getLoanByToken(tokenIds[i]);

            require(msg.sender == _ownerOfToken, "Only the token owner can accept a loan request.");
            require(_saleType == uint256(SaleType.None), "Token must be available");

            _acceptLoan(_loanId, tokenIds[i], msg.sender);
            emit LoanAccepted(msg.sender, _loanId, tokenIds[i]);
        }
    }

    // FIXME: When the loan time is occure we have to do:
    // 1. Change token's sale type to "Loan"
    // 2. Notify a loan owner  only a loan owner has to get
    // Only the contract can initiate loan according to schedule 
    function startLoan(uint256 loanId) public onlyOwner {
        // Get loan price of the Token
        uint256 _price = _getLoanPriceOfToken(loanId);
        // Check across all tokens if the Loan has been accepted
        uint256 _totalNumberOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
        uint256 _tokenId;
        bool _isAccepted;
        address _currentOwnerOfToken;
        for (uint256 i = 0; i < _totalNumberOfTokens; i++) {
            _tokenId = _storage.getTokenFromLoanList(loanId, i);
            _isAccepted = _storage.isTokenAcceptedForLoan(loanId, _tokenId);
            if (_isAccepted) {
                // if Accepted, perform transfer
                _storage.transferToken(
                    _tokenId, 
                    _storage.getOwnerOfToken(_tokenId), 
                    _storage.getDestinationWalletOfLoan(loanId)
                );
                // Transfer funds for the Loan to the token owners that accepted Loan
                if (_price > 0) {
                    _currentOwnerOfToken = _storage.getCurrentTokenOwnerForLoan(loanId, _tokenId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_currentOwnerOfToken, _price);
                }
                // !!! We may need to reencrypt the tokens !!!!
                // !!! Perhaps we can do this on the back-end, 
                // !!! and not here and now !!!!
            } else {
                // Return funds related to Loans that have not been accepted.
                if (_price > 0) {
                    address _borrower = _storage.getDestinationWalletOfLoan(loanId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_borrower, _price);

                    // Reduce total price of Loan
                    uint256 totalPrice = _storage.getTotalPriceOfLoan(loanId);
                    _storage.setTotalPriceOfLoan(loanId, totalPrice - _price);

                    // Delete entry
                    _storage.deleteTokenFromListOfLoan(loanId, _tokenId);
                    _storage.deleteLoanToToken(_tokenId);
                }
            }
        }
        // Mark that the Loan is active and working
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Active));
        
        emit LoanStarted(loanId);
    }

    // Only contract can end loan according to schedule
    function stopLoan(uint256 loanId) public onlyOwner {
        _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
        // Transfer all loans back into place
        uint256 _totalNumberOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
        address _borrower = _storage.getDestinationWalletOfLoan(loanId);
        uint256 _tokenId;
        address _ownerOfToken;
        for (uint256 i = 0; i < _totalNumberOfTokens; i++) {
            _tokenId = _storage.getTokenFromLoanList(loanId, i);
            _ownerOfToken = _storage.getCurrentTokenOwnerForLoan(loanId, _tokenId);
            _storage.deleteLoanToToken(_tokenId);
            _storage.setSaleTypeToToken(_tokenId, uint256(SaleType.None));
            _storage.transferToken(_tokenId, _borrower, _ownerOfToken);
        }
        emit LoanFinished(loanId);
    }

    // Ability to terminate Loan can be called only by the token owner
    function cancelLoanToken(uint256 tokenId) public payable {
        uint256 _loanId = _storage.getLoanByToken(tokenId);
        uint256 _loanSaleStatus = getLoanSaleStatus(_loanId);
        address _ownerOfToken = (_loanSaleStatus == uint256(SaleStatus.NotActive)) ? 
            _storage.getOwnerOfToken(tokenId) :
            _storage.getCurrentTokenOwnerForLoan(_loanId, tokenId);
        address _borrower = _storage.getDestinationWalletOfLoan(_loanId);
        require(msg.sender == _ownerOfToken, "Only an token owner can accept a loan request.");

        // Check if the loan is active, otherwise end function
        // uint256 _status = _storage.getLoanSaleStatus(_loanId);
        // require(_status == uint256(SaleStatus.Active), "Loan has to be in 'active' status");

        // Check amount that has been transferred.  If it is less than  
        // amount for one token for loan - exit
        uint256 _price = _getLoanPriceOfToken(_loanId);
        require(msg.value >= _price, "Payment has to be equal to cost of loan token");
        if (_price > 0) {
            _storage.addPendingWithdrawals(_borrower, _price);
        }
        uint256 amountToWithdraw = msg.value.sub(_price);
        if (amountToWithdraw > 0) {
            _storage.addPendingWithdrawals(msg.sender, amountToWithdraw);
        }

        // Remove token from loan entry
        _storage.deleteTokenFromListOfLoan(_loanId, tokenId);
        _storage.deleteLoanToToken(tokenId);

        _storage.setSaleTypeToToken(tokenId, uint256(SaleType.None));
        _storage.declineTokenForLoan(_loanId, tokenId);
        _storage.transferToken(tokenId, _borrower, _ownerOfToken);

        emit LoanOfTokenCanceled(_loanId, tokenId);
    } 

    function getTokenListForLoan(uint256 loanId) public view returns (uint256[]) {
        uint256 _count = _storage.getTotalNumberOfLoanTokens(loanId);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = _storage.getTokenFromLoanList(loanId, i);
        }
        return _retarray;
    }

    function getTokenAcceptedStatusListForLoan(uint256 loanId) public view returns (bool[]) {
        uint256 _count = _storage.getTotalNumberOfLoanTokens(loanId);
        bool[] memory _retarray = new bool[](_count);
        uint256 _tokenId;
        for (uint256 i = 0; i < _count; i++) {
            _tokenId = _storage.getTokenFromLoanList(loanId, i);
            _retarray[i] = _storage.isTokenAcceptedForLoan(loanId, _tokenId);
        }
        return _retarray;
    }

    function getLoanSaleStatus(uint256 loanId) public view returns (uint256) {
        return _storage.getLoanSaleStatus(loanId);
    }

    function getCurrentTokenOwnerForLoan(uint256 loanId, uint256 tokenId) public view returns (address) {
        return _storage.getCurrentTokenOwnerForLoan(loanId, tokenId);
    }

    // Automatic function on token level 
    // Allows for acceptance of art loans
    function _acceptLoan(uint256 loanId, uint256 tokenId, address tokenOwner) internal {
        _storage.setCurrentTokenOwnerForLoan(loanId, tokenId, tokenOwner);
        _storage.setSaleTypeToToken(tokenId, uint256(SaleType.Loan));
        _storage.acceptTokenForLoan(loanId, tokenId);
    }

    function _getLoanPriceOfToken(uint256 loanId) internal view returns (uint256) {
        uint256 _commonPrice = _storage.getTotalPriceOfLoan(loanId);
        uint256 _amountOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
        uint256 _price = (_commonPrice > 0) ? _commonPrice / _amountOfTokens : 0;
        return _price;
    }

}
