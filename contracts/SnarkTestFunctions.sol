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

    function setTotalNumberOfTokensInApprovedTokensForLoan(uint256 newAmount) public {
        SnarkLoanLib.setTotalNumberOfTokensInApprovedTokensForLoan(_storage, newAmount);
    }

    function getIndexOfTokenInApprovedTokensForLoan(uint256 tokenId) public view returns (uint256) {
        return SnarkLoanLib.getIndexOfTokenInApprovedTokensForLoan(_storage, tokenId);
    }

    function setIndexOfTokenInApprovedTokensForLoan(uint256 tokenId, uint256 position) public {
        SnarkLoanLib.setIndexOfTokenInApprovedTokensForLoan(_storage, tokenId, position);
    }

    function isTokenInApprovedListForLoan(uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInApprovedListForLoan(_storage, tokenId);
    }

    function setIsTokenInApprovedListForLoan(uint256 tokenId, bool isInList) public {
        SnarkLoanLib.setIsTokenInApprovedListForLoan(_storage, tokenId, isInList);
    }

    function getTokenFromApprovedTokensForLoanByIndex(uint256 position) public view returns (uint256) {
        return SnarkLoanLib.getTokenFromApprovedTokensForLoanByIndex(_storage, position);
    }

    function setTokenIdToPositionInApprovedTokensForLoan(uint256 position, uint256 tokenId) public {
        SnarkLoanLib.setTokenIdToPositionInApprovedTokensForLoan(_storage, position, tokenId);
    }

    //// NOT APPROVED LIST
    function addTokenToNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public onlyOwner {
        SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function deleteTokenFromNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public onlyOwner {
        SnarkLoanLib.deleteTokenFromNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function setTokenIdToPositionInNotApprovedTokensForLoan(
        address tokenOwner, 
        uint256 position, 
        uint256 tokenId
    ) 
        public 
    {
        SnarkLoanLib.setTokenIdToPositionInNotApprovedTokensForLoan(
            _storage,
            tokenOwner,
            position,
            tokenId
        );
    }

    function getTotalNumberOfTokensInNotApprovedTokensForLoan(address tokenOwner) public view returns (uint256) {
        return SnarkLoanLib.getTotalNumberOfTokensInNotApprovedTokensForLoan(_storage, tokenOwner);
    }

    function setTotalNumberOfTokensInNotApprovedTokensForLoan(address tokenOwner, uint256 newAmount) public {
        SnarkLoanLib.setTotalNumberOfTokensInNotApprovedTokensForLoan(_storage, tokenOwner, newAmount);
    }

    function getIndexOfTokenInNotApprovedTokensForLoan(address tokenOwner, uint256 tokenId) 
        public view returns (uint256) 
    {
        return SnarkLoanLib.getIndexOfTokenInNotApprovedTokensForLoan(_storage, tokenOwner, tokenId);
    }

    function setIndexOfTokenInNotApprovedTokensForLoan(
        address tokenOwner, 
        uint256 tokenId, 
        uint256 position
    ) 
        public 
        onlyOwner 
    {
        SnarkLoanLib.setIndexOfTokenInNotApprovedTokensForLoan(_storage, tokenOwner, tokenId, position);
    }

    function isTokenInNotApprovedListForLoan(address tokenOwner, uint256 tokenId) public view returns (bool) {
        return SnarkLoanLib.isTokenInNotApprovedListForLoan(_storage, tokenOwner, tokenId);
    }

    function setIsTokenInNotApprovedTokensForLoan(address tokenOwner, uint256 tokenId, bool isInList) public onlyOwner {
        SnarkLoanLib.setIsTokenInNotApprovedListForLoan(_storage, tokenOwner, tokenId, isInList);
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

    function restoreNotApprovedArray(uint256 fromTokenId, uint256 toTokenId) public onlyOwner {
        address tokenOwner;
        bool isInNotApprovedList;
        uint256 index;

        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {            
            tokenOwner = SnarkBaseLib.getOwnerOfToken(_storage, tokenId);
            isInNotApprovedList = isTokenInNotApprovedListForLoan(tokenOwner, tokenId);
            if (isInNotApprovedList) {
                index = SnarkLoanLib.getIndexOfTokenInNotApprovedTokensForLoan(_storage, tokenOwner, tokenId);
                if (index == 0) {
                    setIsTokenInNotApprovedTokensForLoan(tokenOwner, tokenId, false);
                    addTokenToNotApprovedListForLoan(tokenOwner, tokenId);
                }
            }
        }

    }

    function resetAutoLoanForWallet(address tokenOwner, uint256 fromIndex, uint256 toIndex) public onlyOwner {
        uint256 tokenId;
        bool isAcceptOfLoanRequest;

        for (uint256 i = fromIndex; i <= toIndex; i++) {
            tokenId = SnarkBaseLib.getTokenIdOfOwner(_storage, tokenOwner, i);
            isAcceptOfLoanRequest = SnarkBaseLib.isTokenAcceptOfLoanRequest(_storage, tokenId);
            if (isAcceptOfLoanRequest) {
                SnarkLoanLib.deleteTokenFromApprovedListForLoan(_storage, tokenId);
                SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, tokenOwner, tokenId);
            }
        }
    }

}
