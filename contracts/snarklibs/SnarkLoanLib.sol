pragma solidity ^0.4.24;

import "../SnarkStorage.sol";


library SnarkLoanLib {

    function addTokenToListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        // get a total number of tokens belong to loan
        uint256 totalNumber = getTotalNumberOfLoanTokens(storageAddress, loanId);

        // add the tokenId to loan list
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("tokenToLoanList", loanId, totalNumber)), 
            tokenId
        );

        // increase total number and save it
        SnarkStorage(storageAddress).setUint(
            keccak256(abi.encodePacked("totalNumberOfLoanTokens", loanId)), 
            totalNumber + 1
        );
    }

    function deleteTokenFromListOfLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        uint256 totalNumber = getTotalNumberOfLoanTokens(storageAddress, loanId);
        for (uint256 i = 0; i < totalNumber; i++) {
            if (getTokenFromLoanList(storageAddress, loanId, i) == tokenId) {
                if (i < totalNumber - 1) {
                    uint256 lastTokenId = getTokenFromLoanList(storageAddress, loanId, totalNumber - 1);
                    SnarkStorage(storageAddress).setUint(
                        keccak256(abi.encodePacked("tokenToLoanList", loanId, i)), 
                        lastTokenId
                    );
                }
                SnarkStorage(storageAddress).setUint(
                    keccak256(abi.encodePacked("totalNumberOfLoanTokens", loanId)), 
                    totalNumber - 1
                );
                break;
            }
        }
    }

    function setLoanToToken(address storageAddress, uint256 tokenId, uint256 loanId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("loanToToken", tokenId)), loanId);
    }

    function deleteLoanToToken(address storageAddress, uint256 tokenId) public {
        SnarkStorage(storageAddress).deleteUint(keccak256(abi.encodePacked("loanToToken", tokenId)));
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

    function acceptTokenForLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId)), 
            true
        );
    }

    function declineTokenForLoan(address storageAddress, uint256 loanId, uint256 tokenId) public {
        SnarkStorage(storageAddress).setBool(
            keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId)), 
            false
        );
    }

    function setCurrentTokenOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 tokenId, 
        address tokenOwner
    ) 
        public 
    {
        SnarkStorage(storageAddress).setAddress(
            keccak256(abi.encodePacked("currentTokenOwnerForLoan", loanId, tokenId)),
            tokenOwner
        );
    }

    function createLoan(
        address storageAddress, 
        uint256[] tokensIds,
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

        // в одном loan может содержаться много tokens
        for (uint256 index = 0; index < tokensIds.length; index++) {
            addTokenToListOfLoan(storageAddress, loanId, tokensIds[index]);
            setLoanToToken(storageAddress, tokensIds[index], loanId);
        }
        setTotalPriceOfLoan(storageAddress, loanId, commonPrice);
        setStartDateOfLoan(storageAddress, loanId, startDate);
        setDurationOfLoan(storageAddress, loanId, duration);
        setDestinationWalletOfLoan(storageAddress, loanId, destinationWallet);
        setLoanSaleStatus(storageAddress, loanId, 1);
    }

    function getLoanDetails(address storageAddress, uint256 loanId) 
        public 
        view 
        returns 
    (
        uint256 amountOfTokens,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        uint256 saleStatus,
        address destinationWallet)
    {
        amountOfTokens = getTotalNumberOfLoanTokens(storageAddress, loanId);
        price = getTotalPriceOfLoan(storageAddress, loanId);
        startDate = getStartDateOfLoan(storageAddress, loanId);
        duration = getDurationOfLoan(storageAddress, loanId);
        saleStatus = getLoanSaleStatus(storageAddress, loanId);
        destinationWallet = getDestinationWalletOfLoan(storageAddress, loanId);
    }

    function getTotalNumberOfLoanTokens(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("totalNumberOfLoanTokens", loanId))
        );
    }

    function getTokenFromLoanList(address storageAddress, uint256 loanId, uint256 index) 
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(
            keccak256(abi.encodePacked("tokenToLoanList", loanId, index))
        );
    }

    function getTotalNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfLoans"));
    }

    function getLoanByToken(address storageAddress, uint256 tokenId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("loanToToken", tokenId)));
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

    function isTokenAcceptedForLoan(address storageAddress, uint256 loanId, uint256 tokenId) 
        public 
        view 
        returns (bool) 
    {
        return SnarkStorage(storageAddress).boolStorage(
            keccak256(abi.encodePacked("tokenAcceptedForLoan", loanId, tokenId))
        );
    }

    function getCurrentTokenOwnerForLoan(
        address storageAddress, 
        uint256 loanId, 
        uint256 tokenId
    ) 
        public 
        view
        returns (address)
    {
        return SnarkStorage(storageAddress).addressStorage(
            keccak256(abi.encodePacked("currentTokenOwnerForLoan", loanId, tokenId))
        );
    }

}
