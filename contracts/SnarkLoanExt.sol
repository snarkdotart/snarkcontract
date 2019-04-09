pragma solidity >=0.5.0;

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
        selfdestruct(msg.sender);
    }

    // /// @notice store the gas cost of calling function StopLoan
    // function setCostOfStopLoanOperationForLoan(uint256 loanId, uint256 costOfStopOperation) public onlyOwner {
    //     SnarkLoanLib.setCostOfStopLoanOperationForLoan(address(uint160(_storage)), loanId, costOfStopOperation);
    // }
    // /// @notice return a total number of loans
    // function getTotalNumberOfLoans() public view returns (uint256) {
    //     return SnarkLoanLibExt.getTotalNumberOfLoans(address(uint160(_storage)));
    // }

    // function getActualTokenOwnerForLoan(uint256 loanId, uint256 tokenId) public view returns (address) {
    //     return SnarkLoanLib.getActualTokenOwnerForLoan(address(uint160(_storage)), loanId, tokenId);
    // }

    // function getListOfNotFinishedLoansForToken(uint256 tokenId) public view returns (uint256[] memory) {
    //     return SnarkLoanLib.getListOfNotFinishedLoansForToken(address(uint160(_storage)), tokenId);
    // }

    // function getListOfNotStartedLoansForToken(uint256 tokenId) public view returns (uint256[] memory) {
    //     return SnarkLoanLib.getListOfNotStartedLoansForToken(address(uint160(_storage)), tokenId);
    // }

    // /// @notice return list of loan request by token owner 
    // function getLoanRequestsListOfTokenOwner(address tokenOwner) 
    //     public view returns (uint256[] memory, uint256[] memory) 
    // {
    //     return SnarkLoanLib.getLoanRequestsListForTokenOwner(address(uint160(_storage)), tokenOwner);
    // }

    // /// @notice return list of loan borrowers 
    // function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[] memory) {
    //     return SnarkLoanLib.getLoansListOfLoanOwner(address(uint160(_storage)), loanOwner);
    // }

    // function attachTokensToLoan(uint256 loanId, uint256[] memory tokensIds) public onlyOwner {
    //     require(
    //         SnarkLoanLibExt.getLoanSaleStatus(address(uint160(_storage)), loanId) != uint256(SaleStatus.Active) &&
    //         SnarkLoanLibExt.getLoanSaleStatus(address(uint160(_storage)), loanId) != uint256(SaleStatus.Finished),
    //         "Loan can't be in 'Active' of 'Finished' status"
    //     );
    //     uint256 startDate = SnarkLoanLibExt.getStartDateOfLoan(address(uint160(_storage)), loanId);
    //     uint256 duration = SnarkLoanLibExt.getDurationOfLoan(address(uint160(_storage)), loanId);
    //     uint256[3] memory tokenIdStartDateDuration = [tokensIds[0], startDate, duration];
    //     address tokenOwner;
    //     bool isAgree = false;
    //     for (uint256 i = 0; i < tokensIds.length; i++) {
    //         tokenIdStartDateDuration[0] = tokensIds[i];
    //         if (SnarkBaseLib.getSaleTypeToToken(address(uint160(_storage)), tokensIds[i]) != uint256(SaleType.Offer) 
    //             && !SnarkLoanLib.isTokenBusyForPeriod(address(uint160(_storage)), tokenIdStartDateDuration)
    //         ) {
    //             tokenOwner = SnarkBaseLib.getOwnerOfToken(address(uint160(_storage)), tokensIds[i]);
    //             SnarkLoanLib.setActualTokenOwnerForLoan(
    //              address(uint160(_storage)), loanId, tokensIds[i], tokenOwner);
    //             SnarkBaseLib.isTokenAcceptOfLoanRequest(address(uint160(_storage)), tokensIds[i]);
    //             if (isAgree) {
    //                 SnarkLoanLib.makeTokenBusyForPeriod(
    //                  address(uint160(_storage)), loanId, tokenIdStartDateDuration);
    //                 SnarkLoanLib.addTokenToListOfLoan(address(uint160(_storage)), loanId, tokensIds[i], 1);
    //             } else {
    //                 SnarkLoanLib.addLoanRequestToTokenOwner(
    //                     address(uint160(_storage)), tokenOwner, tokensIds[i], loanId);
    //             }
    //             emit TokenAttachedToLoan(tokensIds[i], loanId);
    //         } else { emit TokenDeclinedInLoanCreation(tokensIds[i]); }
    //     }
    // }

    // function isTokenBusyForPeriod(uint256 tokenId, uint256 startDate, uint256 duration) public view returns (bool) {
    //     uint256[3] memory data = [tokenId, startDate, duration];
    //     return SnarkLoanLib.isTokenBusyForPeriod(address(uint160(_storage)), data);
    // }

    // function getListOfLoansWithFreeSlots() public view returns (uint256[] memory) {
    //     uint256 loansCount = getTotalNumberOfLoans();
    //     uint256[] memory listOfLoans = new uint256[](loansCount);
    //     uint256 index = 0;
    //     for (uint256 i = 1; i < loansCount + 1; i++) {
    //         if (SnarkLoanLibExt.getLoanSaleStatus(address(uint160(_storage)), i) == 0 || 
    //             SnarkLoanLibExt.getLoanSaleStatus(address(uint160(_storage)), i) == 1) {
    //             uint256[] memory notApprovedTokensList = 
    //                 SnarkLoanLibExt.getTokensListOfLoanByType(address(uint160(_storage)), i, 0);
    //             uint256[] memory approvedTokensList = 
    //                 SnarkLoanLibExt.getTokensListOfLoanByType(address(uint160(_storage)), i, 1);
    //             if (notApprovedTokensList.length + approvedTokensList.length < 10) {
    //                 listOfLoans[index] = i;
    //                 index++;
    //             }
    //         }
    //     }
    //     uint256[] memory resultList = new uint256[](index);
    //     for (uint256 i = 0; i < index; i++) {
    //         resultList[i] = listOfLoans[i];
    //     }

    //     return resultList;
    // }
    
}
