pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkLoanLib {

    function setArtworkByLoan(address storageAddress, uint256 loanId, uint256 artworkId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToToken", loanId)), artworkId);
    }

    function setLoanByArtwork(address storageAddress, uint256 artworkId, uint256 loanId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("tokenToLoan", artworkId)), loanId);
    }

    function setPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToPrice", loanId)), price);
    }

    function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    }

    function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    }

    function setDestinationWalletOfLoan(address storageAddress, uint256 loanId, address destinationWallet) public {
        SnarkStorage(storageAddress).setAddress(keccak256(abi.encodePacked("loanToDestinationWallet", loanId)), destinationWallet);
    }

    function setLoanSaleStatus(address storageAddress, uint256 loanId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), saleStatus);
    }

    function createLoan(
        address storageAddress, 
        uint256 artworkId,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        address destinationWallet
    )
        public
        returns (uint256 loanId)
    {
        loanId = getTotalNumberOfLoans(storageAddress) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfLoans"), loanId);

        setArtworkByLoan(storageAddress, loanId, artworkId);
        setLoanByArtwork(storageAddress, artworkId, loanId);

        setPriceOfLoan(storageAddress, loanId, price);
        setStartDateOfLoan(storageAddress, loanId, startDate);
        setDurationOfLoan(storageAddress, loanId, duration);
        setDestinationWalletOfLoan(storageAddress, loanId, destinationWallet);
        setLoanSaleStatus(storageAddress, loanId, 0);
    }

    function getLoanDetails(address storageAddress, uint256 loanId) 
        public 
        view 
        returns 
    (
        uint256 artworkId,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        address destinationWallet)
    {
        artworkId = getArtworkByLoan(storageAddress, loanId);
        price = getPriceOfLoan(storageAddress, loanId);
        startDate = getStartDateOfLoan(storageAddress, loanId);
        duration = getDurationOfLoan(storageAddress, loanId);
        saleStatus = getLoanSaleStatus(storageAddress, loanId);
        destinationWallet = getDestinationWalletOfLoan(storageAddress, loanId);
    }

    function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    function getArtworkByLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", loanId)));
    }

    function getLoanByArtwork(address storageAddress, uint256 artworkId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("tokenToLoan", artworkId)));
    }

    function getPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToPrice", loanId)));
    }

    function getStartDateOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    }

    function getDurationOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    }

    function getDestinationWalletOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("loanToDestinationWallet", loanId)));
    }

    function getLoanSaleStatus(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToSaleStatus", loanId)));
    }

}
