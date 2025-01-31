pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./snarklibs/SnarkBaseLib.sol";


contract SnarkTestFunctions is Ownable {

    using SnarkLoanLib for address;
    using SnarkBaseLib for address;

    address payable private _storage;

    constructor(address payable storageAddress) public {
        _storage = storageAddress;
    }

    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function addTokenToApprovedListForLoan(uint256 tokenId) public onlyOwner {
        SnarkLoanLib.addTokenToApprovedListForLoan(_storage, tokenId);
    }

    function deleteTokenFromApprovedListForLoan(uint256 tokenId) public onlyOwner {
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
    function addTokenToNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public onlyOwner {
        SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function deleteTokenFromNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public onlyOwner {
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

    function getMaxLoanId() public view returns (uint256) {
        return SnarkLoanLib.getMaxLoanId(_storage);
    }

    function getLoanPointer() public view returns (uint256) {
        return SnarkLoanLib.getLoanPointer(_storage);
    }

    function getOwnerOfLoan(uint256 loanId) public view returns (address) {
        return SnarkLoanLib.getOwnerOfLoan(_storage, loanId);
    }

    function getTotalNumberOfLoansInOwnerList(address loanOwner) public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfLoansInOwnerList(_storage, loanOwner);
    }

    function getLoanFromOwnerListByIndex(address loanOwner, uint256 index) public view returns (uint256) {
        return SnarkLoanLib.getLoanFromOwnerListByIndex(_storage, loanOwner, index);
    }

    function deleteAllLoans(uint256 countOfLoans) public onlyOwner {
        SnarkLoanLib.setNumberOfLoans(_storage, 0);
        SnarkLoanLib.setMaxLoanId(_storage, 0);
        SnarkLoanLib.setBottomBoundaryOfLoansPeriod(_storage, 0);
        SnarkLoanLib.setTopBoundaryOfLoansPeriod(_storage, 0);
        SnarkLoanLib.setLoanPointer(_storage, 0);

        address loanOwner;
        for (uint256 i = 1; i < countOfLoans; i++) {
            SnarkStorage(_storage).setBool(keccak256(abi.encodePacked("isLoanDeleted", i)), false);
            loanOwner = SnarkLoanLib.getOwnerOfLoan(_storage, i);
            if (loanOwner != address(0)) {
                SnarkLoanLib.deleteLoanFromOwnerList(_storage, loanOwner, i);
            }
        }
    }

    function updateTokens(uint256 fromTokenId, uint256 toTokenId) public onlyOwner {
        // каждый из указанных токенов нужно поместить либо 
        bool isAutoLoan;
        address tokenOwner;
        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            isAutoLoan = SnarkBaseLib.isTokenAcceptOfLoanRequest(_storage, i);
            if (isAutoLoan) {
                isAutoLoan = isTokenInApprovedListForLoan(i);
                if (!isAutoLoan) {
                    addTokenToApprovedListForLoan(i);
                }
            } else {
                tokenOwner = SnarkBaseLib.getOwnerOfToken(_storage, i);
                isAutoLoan = isTokenInNotApprovedListForLoan(tokenOwner, i);
                if (!isAutoLoan) {
                    addTokenToNotApprovedListForLoan(tokenOwner, i);
                }
            }
        }
    }
}
