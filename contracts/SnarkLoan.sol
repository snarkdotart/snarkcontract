pragma solidity ^0.4.24;

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

    event LoanCreated(
        address indexed loanBidOwner, 
        uint256 loanId, 
        uint256[] unacceptedTokens
    );

    event LoanAccepted(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanDeclined(address indexed tokenOwner, uint256 loanId, uint256 tokenId);
    event LoanStarted(uint256 loanId);
    event LoanFinished(uint256 loanId);
    event LoanOfTokenCanceled(uint256 loanId, uint256 tokenId);

    uint256 private ONEDAY_DATETIME = 86400000;

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

    function createLoan(uint256[] tokensIds, uint256 startDate, uint256 duration) public payable restrictedAccess {
        require(duration <= getDefaultLoanDuration(), "Duration exceeds a max value");
        // check if the user requested their own tokens
        for (uint256 i = 0; i < tokensIds.length; i++) {
            require(tokensIds[i] <= _storage.getTotalNumberOfTokens(), "Token id has to be valid");
            require(
                _storage.getOwnerOfToken(tokensIds[i]) != msg.sender,
                "Borrower can't request loan for their own tokens"
            );
            // проверяем, чтобы токен сейчас не продавался
            require(_storage.getSaleTypeToToken(
                tokensIds[i]) != uint256(SaleType.Offer), 
                "Token's sale type cannot be 'Offer'"
            );
        }
         // Transfer money funds into the contract 
        if (msg.value > 0) _storage.addPendingWithdrawals(_storage, msg.value);
        // Create new entry for a Loan
        uint256 loanId = _storage.createLoan(msg.sender, msg.value, tokensIds, startDate, duration);
        bool isAgree = false;
        for (i = 0; i < tokensIds.length; i++) {
            address tokenOwner = _storage.getOwnerOfToken(tokensIds[i]);
            // запоминаем владельца токена, чтобы потом знать кому возвращать токен
            _storage.setCurrentTokenOwnerForLoan(loanId, tokensIds[i], tokenOwner);
            if (_isTokenBusyForPeriod(tokensIds[i], startDate, duration)) {
                // токен уже занят. перекидываем его в Declined List - 2
                _storage.addTokenToListOfLoan(loanId, tokensIds[i], 2);
            } else {
                isAgree = (msg.sender == owner) ? 
                    _storage.isTokenAcceptOfLoanRequestFromSnark(tokensIds[i]) :
                    _storage.isTokenAcceptOfLoanRequestFromOthers(tokensIds[i]);
                if (isAgree) {
                    // занимаем период в календаре и какой лоан застолбил его день
                    _makeTokenBusyForPeriod(loanId, tokensIds[i], startDate, duration);
                    // перекидываем токен в Approved List - 1
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

    function acceptLoan(uint256 loanId, uint256[] tokenIds) public {
        require(tokenIds.length > 0, "Array of tokens can't be empty");

        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        uint256 numberOfTokens = _storage.getOwnedTokensCount(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] <= numberOfTokens, "Token has to be exist");

            address _ownerOfToken = _storage.getOwnerOfToken(tokenIds[i]);
            require(msg.sender == _ownerOfToken, "Only the token owner can accept a loan request.");

            uint256 _saleType = _storage.getSaleTypeToToken(tokenIds[i]);
            require(_saleType != uint256(SaleType.Offer), "Token's sale type cannot be 'Offer'");

            // проверяем, занят ли этот токен на запрашиваемые даты или нет
            if (_isTokenBusyForPeriod(tokenIds[i], startDate, duration)) {
                // занятый токен перемещаем в Declined list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 2);
                // Оповещаем, что токен отвергнут
                emit LoanDeclined(msg.sender, loanId, tokenIds[i]);
            } else {
                // свободный токен перемещаем в Approved list
                _storage.addTokenToListOfLoan(loanId, tokenIds[i], 1);
                // Оповещаем, что токен аппрувнут
                emit LoanAccepted(msg.sender, loanId, tokenIds[i]);
            }
            // удаляем request у пользователя на данный токен для этого кредита
            _storage.deleteLoanRequestFromTokenOwner(loanId, tokenIds[i]);
        }
    }

    function getTokenListsOfLoanByTypes(uint256 loanId) public view returns (
        uint256[] notApprovedTokensList,
        uint256[] approvedTokensList,
        uint256[] declinedTokensList)
    {
        notApprovedTokensList = _storage.getTokensListOfLoanByType(loanId, 0);
        approvedTokensList = _storage.getTokensListOfLoanByType(loanId, 1);
        declinedTokensList = _storage.getTokensListOfLoanByType(loanId, 2);
    }

    // // FIXME: When the loan time is occure we have to do:
    // // 1. Change token's sale type to "Loan"
    // // 2. Notify a loan owner  only a loan owner has to get
    // // Only the contract can initiate loan according to schedule 
    // function startLoan(uint256 loanId) public onlyOwner {
    //     // Get loan price of the Token
    //     uint256 _price = _getLoanPriceOfToken(loanId);
    //     // Check across all tokens if the Loan has been accepted
    //     uint256 _totalNumberOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
    //     uint256 _tokenId;
    //     bool _isAccepted;
    //     address _currentOwnerOfToken;
    //     for (uint256 i = 0; i < _totalNumberOfTokens; i++) {
    //         _tokenId = _storage.getTokenFromLoanList(loanId, i);
    //         _isAccepted = _storage.isTokenAcceptedForLoan(loanId, _tokenId);
    //         if (_isAccepted) {
    //             // if Accepted, perform transfer
    //             _storage.transferToken(
    //                 _tokenId, 
    //                 _storage.getOwnerOfToken(_tokenId), 
    //                 _storage.getDestinationWalletOfLoan(loanId)
    //             );
    //             // Transfer funds for the Loan to the token owners that accepted Loan
    //             if (_price > 0) {
    //                 _currentOwnerOfToken = _storage.getCurrentTokenOwnerForLoan(loanId, _tokenId);
    //                 _storage.subPendingWithdrawals(_storage, _price);
    //                 _storage.addPendingWithdrawals(_currentOwnerOfToken, _price);
    //             }
    //             // !!! We may need to reencrypt the tokens !!!!
    //             // !!! Perhaps we can do this on the back-end, 
    //             // !!! and not here and now !!!!
    //         } else {
    //             // Return funds related to Loans that have not been accepted.
    //             if (_price > 0) {
    //                 address _borrower = _storage.getDestinationWalletOfLoan(loanId);
    //                 _storage.subPendingWithdrawals(_storage, _price);
    //                 _storage.addPendingWithdrawals(_borrower, _price);

    //                 // Reduce total price of Loan
    //                 uint256 totalPrice = _storage.getTotalPriceOfLoan(loanId);
    //                 _storage.setTotalPriceOfLoan(loanId, totalPrice - _price);

    //                 // Delete entry
    //                 _storage.deleteTokenFromListOfLoan(loanId, _tokenId);
    //                 _storage.deleteLoanToToken(_tokenId);
    //             }
    //         }
    //     }
    //     // Mark that the Loan is active and working
    //     _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Active));
        
    //     emit LoanStarted(loanId);
    // }

    // // Only contract can end loan according to schedule
    // function stopLoan(uint256 loanId) public onlyOwner {
    //     _storage.setLoanSaleStatus(loanId, uint256(SaleStatus.Finished));
    //     // Transfer all loans back into place
    //     uint256 _totalNumberOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
    //     address _borrower = _storage.getDestinationWalletOfLoan(loanId);
    //     uint256 _tokenId;
    //     address _ownerOfToken;
    //     for (uint256 i = 0; i < _totalNumberOfTokens; i++) {
    //         _tokenId = _storage.getTokenFromLoanList(loanId, i);
    //         _ownerOfToken = _storage.getCurrentTokenOwnerForLoan(loanId, _tokenId);
    //         _storage.deleteLoanToToken(_tokenId);
    //         _storage.setSaleTypeToToken(_tokenId, uint256(SaleType.None));
    //         _storage.transferToken(_tokenId, _borrower, _ownerOfToken);
    //     }
    //     emit LoanFinished(loanId);
    // }

    // // Ability to terminate Loan can be called only by the token owner
    // function cancelLoanToken(uint256 tokenId) public payable {
    //     uint256 _loanId = _storage.getLoanByToken(tokenId);
    //     uint256 _loanSaleStatus = getLoanSaleStatus(_loanId);
    //     address _ownerOfToken = (_loanSaleStatus == uint256(SaleStatus.NotActive)) ? 
    //         _storage.getOwnerOfToken(tokenId) :
    //         _storage.getCurrentTokenOwnerForLoan(_loanId, tokenId);
    //     address _borrower = _storage.getDestinationWalletOfLoan(_loanId);
    //     require(msg.sender == _ownerOfToken, "Only an token owner can accept a loan request.");

    //     // Check if the loan is active, otherwise end function
    //     // uint256 _status = _storage.getLoanSaleStatus(_loanId);
    //     // require(_status == uint256(SaleStatus.Active), "Loan has to be in 'active' status");

    //     // Check amount that has been transferred.  If it is less than  
    //     // amount for one token for loan - exit
    //     uint256 _price = _getLoanPriceOfToken(_loanId);
    //     require(msg.value >= _price, "Payment has to be equal to cost of loan token");
    //     if (_price > 0) {
    //         _storage.addPendingWithdrawals(_borrower, _price);
    //     }
    //     uint256 amountToWithdraw = msg.value.sub(_price);
    //     if (amountToWithdraw > 0) {
    //         _storage.addPendingWithdrawals(msg.sender, amountToWithdraw);
    //     }

    //     // Remove token from loan entry
    //     _storage.deleteTokenFromListOfLoan(_loanId, tokenId);
    //     _storage.deleteLoanToToken(tokenId);

    //     _storage.setSaleTypeToToken(tokenId, uint256(SaleType.None));
    //     _storage.declineTokenForLoan(_loanId, tokenId);
    //     _storage.transferToken(tokenId, _borrower, _ownerOfToken);

    //     emit LoanOfTokenCanceled(_loanId, tokenId);
    // } 

    // function getTokenListForLoan(uint256 loanId) public view returns (uint256[]) {
    //     uint256 _count = _storage.getTotalNumberOfLoanTokens(loanId);
    //     uint256[] memory _retarray = new uint256[](_count);
    //     for (uint256 i = 0; i < _count; i++) {
    //         _retarray[i] = _storage.getTokenFromLoanList(loanId, i);
    //     }
    //     return _retarray;
    // }

    // function getTokenAcceptedStatusListForLoan(uint256 loanId) public view returns (bool[]) {
    //     uint256 _count = _storage.getTotalNumberOfLoanTokens(loanId);
    //     bool[] memory _retarray = new bool[](_count);
    //     uint256 _tokenId;
    //     for (uint256 i = 0; i < _count; i++) {
    //         _tokenId = _storage.getTokenFromLoanList(loanId, i);
    //         _retarray[i] = _storage.isTokenAcceptedForLoan(loanId, _tokenId);
    //     }
    //     return _retarray;
    // }

    // function getLoanSaleStatus(uint256 loanId) public view returns (uint256) {
    //     return _storage.getLoanSaleStatus(loanId);
    // }

    // function getCurrentTokenOwnerForLoan(uint256 loanId, uint256 tokenId) public view returns (address) {
    //     return _storage.getCurrentTokenOwnerForLoan(loanId, tokenId);
    // }

    // function _getLoanPriceOfToken(uint256 loanId) internal view returns (uint256) {
    //     uint256 _commonPrice = _storage.getTotalPriceOfLoan(loanId);
    //     uint256 _amountOfTokens = _storage.getTotalNumberOfLoanTokens(loanId);
    //     uint256 _price = (_commonPrice > 0) ? _commonPrice / _amountOfTokens : 0;
    //     return _price;
    // }
    function _isTokenBusyForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) internal view returns (bool) {
        bool isBusy = false;
        uint256 checkDay = startDate;
        for (uint256 i = 0; i < duration; i++) {
            checkDay = startDate + ONEDAY_DATETIME * i;
            isBusy = isBusy || _storage.isTokenBusyOnDay(tokenId, checkDay);
        }
        return isBusy;
    }

    function _makeTokenBusyForPeriod(uint256 loanId, uint256 tokenId, uint256 startDate, uint256 duration) internal {
        uint256 busyDay;
        for (uint256 i = 0; i < duration; i++) {
            busyDay = startDate + ONEDAY_DATETIME * i;
            _storage.makeTokenBusyOnDay(loanId, tokenId, busyDay);
        }
    }

    function _makeTokenFreeForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) internal {
        uint256 busyDay;
        for (uint256 i = 0; i < duration; i++) {
            busyDay = startDate + ONEDAY_DATETIME * i;
            _storage.makeTokenFreeOnDay(tokenId, busyDay);
        }
    }

}
