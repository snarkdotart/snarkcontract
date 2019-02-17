pragma solidity ^0.4.25;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkLoanLibExt.sol";


contract SnarkLoanExt  is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkLoanLib for address;
    using SnarkLoanLibExt for address;

    event TokenDeclinedInLoanCreation(uint256 tokenId);
    event TokenAttachedToLoan(uint256 tokenId, uint256 loanId);

    address private _storage;

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy the contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    /// @notice store the gas cost of calling function StopLoan
    function setCostOfStopLoanOperationForLoan(uint256 loanId, uint256 costOfStopOperation) public onlyOwner {
        _storage.setCostOfStopLoanOperationForLoan(loanId, costOfStopOperation);
    }

    /// @notice return a total number of loans
    function getTotalNumberOfLoans() public view returns (uint256) {
        return _storage.getTotalNumberOfLoans();
    }

    function getActualTokenOwnerForLoan(uint256 loanId, uint256 tokenId) public view returns (address) {
        return _storage.getActualTokenOwnerForLoan(loanId, tokenId);
    }

    function getListOfNotFinishedLoansForToken(uint256 tokenId) public view returns (uint256[]) {
        return _storage.getListOfNotFinishedLoansForToken(tokenId);
    }

    function getListOfNotStartedLoansForToken(uint256 tokenId) public view returns (uint256[]) {
        return _storage.getListOfNotStartedLoansForToken(tokenId);
    }

    /// @notice return list of loan request by token owner 
    function getLoanRequestsListOfTokenOwner(address tokenOwner) public view returns (uint256[], uint256[]) {
        return _storage.getLoanRequestsListForTokenOwner(tokenOwner);
    }

    /// @notice return list of loan borrowers 
    function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[]) {
        return _storage.getLoansListOfLoanOwner(loanOwner);
    }

    function attachTokensToLoan(uint256 loanId, uint256[] tokensIds) public onlyOwner {
        require(
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Active) &&
            _storage.getLoanSaleStatus(loanId) != uint256(SaleStatus.Finished),
            "Loan can't be in 'Active' of 'Finished' status"
        );
        uint256 startDate = _storage.getStartDateOfLoan(loanId);
        uint256 duration = _storage.getDurationOfLoan(loanId);
        uint256[3] memory tokenIdStartDateDuration = [tokensIds[0], startDate, duration];
        address tokenOwner;
        bool isAgree = false;
        for (uint256 i = 0; i < tokensIds.length; i++) {
            tokenIdStartDateDuration[0] = tokensIds[i];
            if (_storage.getSaleTypeToToken(tokensIds[i]) != uint256(SaleType.Offer) 
                && !_storage.isTokenBusyForPeriod(tokenIdStartDateDuration)
            ) {
                tokenOwner = _storage.getOwnerOfToken(tokensIds[i]);
                _storage.setActualTokenOwnerForLoan(loanId, tokensIds[i], tokenOwner);
                isAgree = (msg.sender == owner) ? 
                    _storage.isTokenAcceptOfLoanRequestFromSnark(tokensIds[i]) :
                    _storage.isTokenAcceptOfLoanRequestFromOthers(tokensIds[i]);
                if (isAgree) {
                    _storage.makeTokenBusyForPeriod(loanId, tokenIdStartDateDuration);
                    _storage.addTokenToListOfLoan(loanId, tokensIds[i], 1);
                } else {
                    _storage.addLoanRequestToTokenOwner(tokenOwner, tokensIds[i], loanId);
                }
                emit TokenAttachedToLoan(tokensIds[i], loanId);
            } else { emit TokenDeclinedInLoanCreation(tokensIds[i]); }
        }
    }

    function isTokenBusyForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) public view returns (bool) {
        uint256[3] memory data = [tokenId, startDate, duration];
        return _storage.isTokenBusyForPeriod(data);
    }

    function getListOfLoansWithFreeSlots() public view returns (uint256[]) {
        uint256 loansCount = getTotalNumberOfLoans();
        uint256[] memory listOfLoans = new uint256[](loansCount);
        uint256 index = 0;
        for (uint256 i = 1; i < loansCount + 1; i++) {
            if (_storage.getLoanSaleStatus(i) == 0 || _storage.getLoanSaleStatus(i) == 1) {
                uint256[] memory notApprovedTokensList = _storage.getTokensListOfLoanByType(i, 0);
                uint256[] memory approvedTokensList = _storage.getTokensListOfLoanByType(i, 1);
                if (notApprovedTokensList.length + approvedTokensList.length < 10) {
                    listOfLoans[index] = i;
                    index++;
                }
            }
        }
        uint256[] memory resultList = new uint256[](index);
        for (i = 0; i < index; i++) {
            resultList[i] = listOfLoans[i];
        }

        return resultList;
    }
    
}
