pragma solidity >=0.5.0;

import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkBaseLib.sol";


contract SnarkTestFunctions {

    using SnarkLoanLib for address;
    using SnarkBaseLib for address;

    address private _storage;

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    function addTokenToApprovedListForLoan(uint256 tokenId) public {
        SnarkLoanLib.addTokenToApprovedListForLoan(_storage, tokenId);
    }

    function deleteTokenFromApprovedListForLoan(uint256 tokenId) public {
        SnarkLoanLib.deleteTokenFromApprovedListForLoan(_storage, tokenId);
    }

    function getTotalNumberOfTokensInApprovedTokensForLoan() public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfTokensInApprovedTokensForLoan(_storage);
    }

    function getIndexOfTokenInApprovedTokensForLoan(uint256 tokenId) public view returns (uint256) {
        return SnarkLoanLib.getIndexOfTokenInApprovedTokensForLoan(_storage, tokenId);
    }

    function isTokenInApprovedListForLoan(uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInApprovedListForLoan(_storage, tokenId);
    }

    function getTokenFromApprovedTokensForLoanByIndex(uint256 position) public view returns (uint256) {
        return SnarkLoanLib.getTokenFromApprovedTokensForLoanByIndex(_storage, position);
    }

    //// NOT APPROVED LIST
    function addTokenToNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public {
        SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function deleteTokenFromNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public {
        SnarkLoanLib.deleteTokenFromNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function getTotalNumberOfTokensInNotApprovedTokensForLoan(address tokenOwner) public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfTokensInNotApprovedTokensForLoan(_storage, tokenOwner);
    }

    function getIndexOfTokenInNotApprovedTokensForLoan(address tokenOwner, uint256 tokenId) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getIndexOfTokenInNotApprovedTokensForLoan(_storage, tokenOwner, tokenId);
    }

    function isTokenInNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function getTokenFromNotApprovedTokensForLoanByIndex(address tokenOwner, uint256 position) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getTokenFromNotApprovedTokensForLoanByIndex(_storage, tokenOwner, position);
    }

    /// TEST FUNCTION OF NEW LOAN
    function getTopBoundaryOfLoansPeriod() public view returns (uint256) {
        return SnarkLoanLib.getTopBoundaryOfLoansPeriod(_storage);
    }

    function getBottomBoundaryOfLoansPeriod() public view returns (uint256) {
        return SnarkLoanLib.getBottomBoundaryOfLoansPeriod(_storage);
    }

    function findPosition(uint256 _start, uint256 _finish) public view returns (uint256, uint256, bool) {
        return SnarkLoanLib.findPosition(_storage, _start, _finish);
    }
}
