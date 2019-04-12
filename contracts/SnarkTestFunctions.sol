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
        SnarkLoanLib.addTokenToApprovedListForLoan(address(uint160(_storage)), tokenId);
    }

    function deleteTokenFromApprovedListForLoan(uint256 tokenId) public {
        SnarkLoanLib.deleteTokenFromApprovedListForLoan(address(uint160(_storage)), tokenId);
    }

    function getTotalNumberOfTokensInApprovedTokensForLoan() public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfTokensInApprovedTokensForLoan(address(uint160(_storage)));
    }

    function getIndexOfTokenInApprovedTokensForLoan(uint256 tokenId) public view returns (uint256) {
        return SnarkLoanLib.getIndexOfTokenInApprovedTokensForLoan(address(uint160(_storage)), tokenId);
    }

    function isTokenInApprovedListForLoan(uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInApprovedListForLoan(address(uint160(_storage)), tokenId);
    }

    function getTokenFromApprovedTokensForLoanByIndex(uint256 position) public view returns (uint256) {
        return SnarkLoanLib.getTokenFromApprovedTokensForLoanByIndex(address(uint160(_storage)), position);
    }

    //// NOT APPROVED LIST
    function addTokenToNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public {
        SnarkLoanLib.addTokenToNotApprovedListForLoan(address(uint160(_storage)), tokenOwner, tokenId);
    }

    function deleteTokenFromNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public {
        SnarkLoanLib.deleteTokenFromNotApprovedListForLoan(address(uint160(_storage)), tokenOwner, tokenId);
    }

    function getTotalNumberOfTokensInNotApprovedTokensForLoan(address tokenOwner) public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfTokensInNotApprovedTokensForLoan(address(uint160(_storage)), tokenOwner);
    }

    function getIndexOfTokenInNotApprovedTokensForLoan(address tokenOwner, uint256 tokenId) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getIndexOfTokenInNotApprovedTokensForLoan(
            address(uint160(_storage)), 
            tokenOwner, 
            tokenId
        );
    }

    function isTokenInNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInNotApprovedListForLoan(address(uint160(_storage)), tokenOwner, tokenId);
    }

    function getTokenFromNotApprovedTokensForLoanByIndex(address tokenOwner, uint256 position) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getTokenFromNotApprovedTokensForLoanByIndex(
            address(uint160(_storage)), 
            tokenOwner, 
            position
        );
    }

}
