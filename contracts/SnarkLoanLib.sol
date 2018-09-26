pragma solidity ^0.4.24;

import "./SnarkStorage.sol";


library SnarkLoanLib {

    function addArtworkToListOfLoan(address storageAddress, uint256 loanId, uint256 artworkId) public {
        // get a total number of artworks belong to loan
        uint256 totalNumber = getTotalNumberOfLoanArtworks(storageAddress, loanId);

        // add the artworkId to loan list
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("artworkToLoanList", loanId, totalNumber)), 
            artworkId
        );

        // increase total number and save it
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfLoanArtworks", loanId)), 
            totalNumber + 1
        );
    }

    function deleteArtworkFromListOfLoan(address storageAddress, uint256 loanId, uint256 artworkId) public {
        uint256 totalNumber = getTotalNumberOfLoanArtworks(storageAddress, loanId);
        for (uint256 i = 0; i < totalNumber; i++) {
            if (getArtworkFromLoanList(storageAddress, loanId, i) == artworkId) {
                if (i < totalNumber - 1) {
                    uint256 lastArtworkId = getArtworkFromLoanList(storageAddress, loanId, totalNumber - 1);
                    SnarkStorage(storageAddress).setUint(
                        keccak256(abi.encodePacked("artworkToLoanList", loanId, i)), 
                        lastArtworkId
                    );
                }
                SnarkStorage(storageAddress).setUint(
                    keccak256(abi.encodePacked("totalNumberOfLoanArtworks", loanId)), 
                    totalNumber - 1
                );
                break;
            }
        }
    }

    function setLoanToArtwork(address storageAddress, uint256 artworkId, uint256 loanId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToArtwork", artworkId)), loanId);
    }

    function deleteLoanToArtwork(address storageAddress, uint256 artworkId) public {
        SnarkStorage(storageAddress).deleteUint(keccak256(abi.encodePacked("loanToArtwork", artworkId)));
    }
    
    function setTotalPriceOfLoan(address storageAddress, uint256 loanId, uint256 price) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("priceOfLoan", loanId)), price);
    }

    function setStartDateOfLoan(address storageAddress, uint256 loanId, uint256 startDate) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToStartDate", loanId)), startDate);
    }

    function setDurationOfLoan(address storageAddress, uint256 loanId, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToDuration", loanId)), duration);
    }

    function setDestinationWalletOfLoan(address storageAddress, uint256 loanId, address destinationWallet) public {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("loanToDestinationWallet", loanId)), 
            destinationWallet
        );
    }

    function setLoanSaleStatus(address storageAddress, uint256 loanId, uint256 saleStatus) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToSaleStatus", loanId)), saleStatus);
    }

    function acceptArtworkForLoan(address storageAddress, uint256 loanId, uint256 artworkId) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("artworkAcceptedForLoan", loanId, artworkId)), 
            true
        );
    }

    function declineArtworkForLoan(address storageAddress, uint256 loanId, uint256 artworkId) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("artworkAcceptedForLoan", loanId, artworkId)), 
            false
        );
    }

    function setCurrentArtworkOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 artworkId, 
        address ownerOfArtwork
    ) 
        public 
    {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("currentArtworkOwnerForLoan", loanId, artworkId)), 
            ownerOfArtwork
        );
    }

    function createLoan(
        address storageAddress, 
        uint256[] artworksIds,
        uint256 commonPrice,
        uint256 startDate,
        uint256 duration,
        address destinationWallet
    )
        public
        returns (uint256 loanId)
    {
        loanId = getTotalNumberOfLoans(storageAddress) + 1;
        SnarkStorage(storageAddress).setUint(keccak256("totalNumberOfLoans"), loanId);

        // в одном loan может содержаться много artworks
        for (uint256 index = 0; index < artworksIds.length; index++) {
            addArtworkToListOfLoan(storageAddress, loanId, artworksIds[index]);
            setLoanToArtwork(storageAddress, artworksIds[index], loanId);
        }
        setTotalPriceOfLoan(storageAddress, loanId, commonPrice);
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
        uint256 amountOfArtworks,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        address destinationWallet)
    {
        amountOfArtworks = getTotalNumberOfLoanArtworks(storageAddress, loanId);
        price = getTotalPriceOfLoan(storageAddress, loanId);
        startDate = getStartDateOfLoan(storageAddress, loanId);
        duration = getDurationOfLoan(storageAddress, loanId);
        saleStatus = getLoanSaleStatus(storageAddress, loanId);
        destinationWallet = getDestinationWalletOfLoan(storageAddress, loanId);
    }

    function getTotalNumberOfLoanArtworks(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfLoanArtworks", loanId))
        );
    }

    function getArtworkFromLoanList(address storageAddress, uint256 loanId, uint256 index) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("artworkToLoanList", loanId, index))
        );
    }

    function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    function getLoanByArtwork(address storageAddress, uint256 artworkId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToArtwork", artworkId)));
    }

    function getTotalPriceOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("priceOfLoan", loanId)));
    }

    function getStartDateOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToStartDate", loanId)));
    }

    function getDurationOfLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToDuration", loanId)));
    }

    function getDestinationWalletOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("loanToDestinationWallet", loanId))
        );
    }

    function getLoanSaleStatus(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToSaleStatus", loanId)));
    }

    function isArtworkAcceptedForLoan(address storageAddress, uint256 loanId, uint256 artworkId) 
        public 
        view 
        returns (bool) 
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("artworkAcceptedForLoan", loanId, artworkId))
        );
    }

    function getCurrentArtworkOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 artworkId
    ) 
        public 
        view
        returns (address)
    {
        SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("currentArtworkOwnerForLoan", loanId, artworkId))
        );
    }

}
