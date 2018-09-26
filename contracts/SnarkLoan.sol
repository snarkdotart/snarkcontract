pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";
import "./SnarkLoanLib.sol";


contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;

    address private _storage;

    event LoanCreated(address indexed loanBidOwner, uint256 loanId);
    event LoanAccepted(address indexed artworkOwner, uint256 loanId, uint256 artworkId);
    event LoanStarted(uint256 loanId);
    event LoanFinished(uint256 loanId);
    event LoanOfArtworkCanceled(uint256 loanId, uint256 artworkId);

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    // Loan can be requested by user 
    // Loan can also be requested by Snark
    function createLoan(
        uint256[] artworksIds,
        uint256 startDate,
        uint256 duration
    ) 
        public 
        payable
    {
        // check if there are any own's artworks
        bool isItMyArtwork = false;
        for (uint256 i = 0; i < artworksIds.length; i++) {
            if (_storage.getOwnerOfArtwork(artworksIds[i]) == msg.sender) isItMyArtwork = true;
        }
        require(isItMyArtwork == false, "borrower can't create loan for it's own artwork");

        // Create new entry for a Loan 
        uint256 loanId = _storage.createLoan(
            artworksIds,
            msg.value,
            startDate,
            duration,
            msg.sender
        );

        // Transfer money funds into the contract 
        if (msg.value > 0) _storage.addPendingWithdrawals(_storage, msg.value);

        // Enter automatic accept for those tokens,
        // that agreed to automatic Loan acceptance 
        bool isAgree = false;
        for (i = 0; i < artworksIds.length; i++) {
            isAgree = (msg.sender == owner) ? 
                _storage.isArtworkAcceptOfLoanRequestFromSnark(artworksIds[i]) :
                _storage.isArtworkAcceptOfLoanRequestFromOthers(artworksIds[i]);
            // Check status of the token ... change of token status is only possible if it is not for sale,
            // Another words, if there is no Offer, no Auction, or no existing Loan, then change of status is possible
            uint256 saleType = _storage.getSaleTypeToArtwork(artworksIds[i]);
            if (isAgree && saleType == uint256(SaleType.None)) {
                // !!! We may need to check the number of days that the token has already been loaned 
                // !!! and if the number of days exceeds the agreed number, then decline the Loan request 
                // !!! Perhaps we should do this check on the front-end during Loan Creation
                _acceptLoan(loanId, artworksIds[i], _storage.getOwnerOfArtwork(artworksIds[i]));
            }
        }
        emit LoanCreated(msg.sender, loanId);
    }

    function acceptLoan(uint256 artworkId) public {
        address _ownerOfArtwork = _storage.getOwnerOfArtwork(artworkId);
        uint256 _saleType = _storage.getSaleTypeToArtwork(artworkId);
        uint256 _loanId = _storage.getLoanByArtwork(artworkId);

        require(msg.sender == _ownerOfArtwork, "Only an artwork owner can accept a loan request.");
        require(_saleType == uint256(SaleType.None), "Token must be free");

        _acceptLoan(_loanId, artworkId, _ownerOfArtwork);

        emit LoanAccepted(msg.sender, _loanId, artworkId);
    }

    // Only the contract can initiate loan according to schedule 
    function startLoan(uint256 loanId) public onlyOwner {
        // Get loan price of the Artwork
        uint256 _price = getLoanPriceOfArtwork(loanId);
        // Check across all tokens if the Loan has been accepted
        uint256 _totalNumberOfArtworks = _storage.getTotalNumberOfLoanArtworks(loanId);
        uint256 _artworkId;
        bool _isAccepted;
        address _currentOwnerOfArtwork;
        for (uint256 i = 0; i < _totalNumberOfArtworks; i++) {
            _artworkId = _storage.getArtworkFromLoanList(loanId, i);
            _isAccepted = _storage.isArtworkAcceptedForLoan(loanId, _artworkId);
            if (_isAccepted) {
                // if Accepted, perform transfer
                _storage.transferArtwork(
                    _artworkId, 
                    _storage.getOwnerOfArtwork(_artworkId), 
                    _storage.getDestinationWalletOfLoan(loanId)
                );
                // Transfer funds for the Loan to the token owners that accepted Loan
                if (_price > 0) {
                    _currentOwnerOfArtwork = _storage.getCurrentArtworkOwnerForLoan(loanId, _artworkId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_currentOwnerOfArtwork, _price);
                }
                // !!! We may need to reencrypt the tokens !!!!
                // !!! Perhaps we can do this on the back-end, 
                // !!! and not here and now !!!!
            } else {
                // Return funds for Art Loans that have not been accepted.
                if (_price > 0) {
                    address _borrower = _storage.getDestinationWalletOfLoan(loanId);
                    _storage.subPendingWithdrawals(_storage, _price);
                    _storage.addPendingWithdrawals(_borrower, _price);

                    // Reduce total price of Loan
                    uint256 totalPrice = _storage.getTotalPriceOfLoan(loanId);
                    _storage.setTotalPriceOfLoan(loanId, totalPrice - _price);

                    // Delete entry
                    _storage.deleteArtworkFromListOfLoan(loanId, _artworkId);
                    _storage.deleteLoanToArtwork(_artworkId);
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
        uint256 _totalNumberOfArtworks = _storage.getTotalNumberOfLoanArtworks(loanId);
        address _borrower = _storage.getDestinationWalletOfLoan(loanId);
        uint256 _artworkId;
        address _ownerOfArtwork;
        for (uint256 i = 0; i < _totalNumberOfArtworks; i++) {
            _artworkId = _storage.getArtworkFromLoanList(loanId, i);
            _ownerOfArtwork = _storage.getOwnerOfArtwork(_artworkId);
            _storage.deleteLoanToArtwork(_artworkId);
            _storage.setSaleTypeToArtwork(_artworkId, uint256(SaleType.None));
            _storage.transferArtwork(_artworkId, _borrower, _ownerOfArtwork);
        }
        emit LoanFinished(loanId);
    }

    // Ability to terminate Loan can be called only by the token owner
    function cancelLoanArtwork(uint256 artworkId) public payable {
        address _ownerOfArtwork = _storage.getOwnerOfArtwork(artworkId);
        address _borrower = _storage.getDestinationWalletOfLoan(_loanId);
        require(msg.sender == _ownerOfArtwork, "Only an artwork owner can accept a loan request.");

        // Check if the loan is active, otherwise end function
        uint256 _loanId = _storage.getLoanByArtwork(artworkId);
        uint256 _status = _storage.getLoanSaleStatus(_loanId);
        require(_status == uint256(SaleStatus.Active), "Loan has to be in 'active' status");

        // Check amount that has been transferred.  If it is less than  
        // amount for one artwork for loan - exit
        uint256 _price = getLoanPriceOfArtwork(_loanId);
        require(msg.value >= _price, "Payment has to be equal to cost of loan artwork");
        if (_price > 0) {
            _storage.addPendingWithdrawals(_borrower, _price);
        }
        if ((msg.value - _price) > 0) {
            _storage.addPendingWithdrawals(msg.sender, (msg.value - _price));
        }

        // Remove artwork token from loan entry
        _storage.deleteArtworkFromListOfLoan(_loanId, artworkId);
        _storage.deleteLoanToArtwork(artworkId);

        _storage.setSaleTypeToArtwork(artworkId, uint256(SaleType.None));
        _storage.declineArtworkForLoan(_loanId, artworkId);
        _storage.transferArtwork(artworkId, _borrower, _ownerOfArtwork);

        emit LoanOfArtworkCanceled(_loanId, artworkId);
    } 

    function getArtworkListForLoan(uint256 loanId) public view returns (uint256[]) {
        uint256 _count = _storage.getTotalNumberOfLoanArtworks(loanId);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = _storage.getArtworkFromLoanList(loanId, i);
        }
        return _retarray;
    }

    // Automatic function on token level 
    // Ability to accept artloans
    function _acceptLoan(uint256 loanId, uint256 artworkId, address artworkOwner) internal {
        _storage.setSaleTypeToArtwork(artworkId, uint256(SaleType.Loan));
        _storage.acceptArtworkForLoan(loanId, artworkId);
        _storage.setCurrentArtworkOwnerForLoan(loanId, artworkId, artworkOwner);
    }

    function getLoanPriceOfArtwork(uint256 loanId) internal view returns (uint256) {
        uint256 _commonPrice = _storage.getTotalPriceOfLoan(loanId);
        uint256 _amountOfArtworks = _storage.getTotalNumberOfLoanArtworks(loanId);
        uint256 _price = (_commonPrice > 0) ? _commonPrice / _amountOfArtworks : 0;
        return _price;
    }

}
