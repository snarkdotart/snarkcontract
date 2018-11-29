pragma solidity ^0.4.24;

import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkBaseLib.sol";

contract SnarkTestFunctions {
    using SnarkLoanLib for address;
    using SnarkBaseLib for address;

    address _storage;
    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    function getCountLoanRequestsForTokenOwner(address _tokenOwner) public view  returns (uint256) {
        return _storage.getCountLoanRequestsForTokenOwner(_tokenOwner);
    }

    function getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(address tokenOwner, uint tokenId, uint loanId) public view returns (uint256) {
        return _storage.getIndexOfLoanRequestForTokenOwnerByTokenAndLoan(tokenOwner,tokenId,loanId);
    }

    function getListOfLoansFromTokensLoanList(uint256 tokenId) public view returns (uint256[]) 
    {
        return _storage.getListOfLoansFromTokensLoanList(tokenId);
    }

    function getNumberOfLoansInTokensLoanList(uint256 tokenId) public view returns (uint256) 
    {
        return _storage.getNumberOfLoansInTokensLoanList(tokenId);
    }

    function getSaleTypeToToken(uint256 tokenId) public view returns (uint256)
    {
        return _storage.getSaleTypeToToken(tokenId);
    }

}
