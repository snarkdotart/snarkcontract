pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkLoanLib {

    // event LoanAdded(address borrower, uint256 tokenId, uint256 loanId);
    
    function setArtworkByLoan(address storageAddress, uint256 loanId, uint256 artworkId) external {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToToken", loanId)), artworkId);
    }

    function setLoanByArtwork(address storageAddress, uint256 artworkId, uint256 loanId) external {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("tokenToLoan", artworkId)), loanId);
    }

    function setPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) external {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToPrice", loanId)), price);
    }

    function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) external {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    }

    function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) external {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    }

    function setBorrowerOfLoan(address storageAddress, uint256 loanId, address borrower) external {
        SnarkStorage(storageAddress).setAddress(keccak256(abi.encodePacked("loanToBorrower", loanId)), borrower);
    }

    function addLoan(
        address storageAddress, 
        uint256 artworkId,
        address borrower,
        uint256 startDate,
        uint256 duration,
        uint256 price
    )
        external
        returns (uint256 loanId)
    {
        loanId = SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans")) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfLoans"), loanId);
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToToken", loanId)), artworkId);
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("tokenToLoan", artworkId)), loanId);

        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToPrice", loanId)), price);
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
        SnarkStorage(storageAddress).setAddress(keccak256(abi.encodePacked("loanToBorrower", loanId)), borrower);
        // enum SaleStatus { Preparing, NotActive, Active, Finished }
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), uint256(1));

        // не факт, что здесь нужно будет вызывать событие, 
        // т.к. вероятно в основном контракте потребуется выполнение дополнительных действий
        // emit LoanAdded(borrower, tokenId, loanId);
        // ждать подтверждения или согласия на заем
        // 
    }

    function getLoanDetails(address storageAddress, uint256 loanId) external view returns (
        uint256 artworkId,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        address borrower) 
    {
        artworkId = SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", loanId)));
        price = SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToPrice", loanId)));
        startDate = SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
        duration = SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
        borrower = SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("loanToBorrower", loanId)));
    }

    function getTotalNumberOfLoans(address storageAddress) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    function getArtworkByLoan(address storageAddress, uint256 loanId) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", loanId)));
    }

    function getLoanByArtwork(address storageAddress, uint256 artworkId) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("tokenToLoan", artworkId)));
    }

    function getPriceOfLoan(address storageAddress, uint256 loanId) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToPrice", loanId)));
    }

    function getStartDateOfLoan(address storageAddress, uint256 loanId) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    }

    function getDurationOfLoan(address storageAddress, uint256 loanId) external view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    }

    function getBorrowerOfLoan(address storageAddress, uint256 loanId) external view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("loanToBorrower", loanId)));
    }
}
