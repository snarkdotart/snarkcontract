pragma solidity ^0.4.25;

import "./openzeppelin/Ownable.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkLoanLibExt.sol";


contract SnarkLoanExt  is Ownable {

    using SnarkLoanLib for address;
    using SnarkLoanLibExt for address;

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

    /// @notice return list of loan request by token owner 
    function getLoanRequestsListOfTokenOwner(address tokenOwner) public view returns (uint256[], uint256[]) {
        return _storage.getLoanRequestsListForTokenOwner(tokenOwner);
    }

    /// @notice return list of loan borrowers 
    function getLoansListOfLoanOwner(address loanOwner) public view returns (uint256[]) {
        return _storage.getLoansListOfLoanOwner(loanOwner);
    }

}
