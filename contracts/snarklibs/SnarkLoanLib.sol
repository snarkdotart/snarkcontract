pragma solidity >=0.5.0;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";


/// @author Vitali Hurski
library SnarkLoanLib {

    using SafeMath for uint256;

    /// @notice returns maximum duration for which a token can be loaned  
    function getDefaultLoanDuration(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("defaultLoanDuration"));
    }

    /// @notice set maximum duration for which a token can be loaned  
    function setDefaultLoanDuration(address payable storageAddress, uint256 duration) public {
        SnarkStorage(storageAddress).setUint(keccak256("defaultLoanDuration"), duration);
    }

    function increaseMaxLoanId(address payable storageAddress) public returns (uint256) {
        uint256 maxLoanId = getMaxLoanId(storageAddress);
        maxLoanId = maxLoanId.add(1);
        setMaxLoanId(storageAddress, maxLoanId);
        return maxLoanId;
    }

    function getMaxLoanId(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("MaxLoanId"));
    }

    function setMaxLoanId(address payable storageAddress, uint256 loanId) public {
        SnarkStorage(storageAddress).setUint(keccak256("MaxLoanId"), loanId);
    }

    function getNumberOfLoans(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("NumberOfLoans"));
    }

    function setNumberOfLoans(address payable storageAddress, uint256 newAmount) public {
        SnarkStorage(storageAddress).setUint(keccak256("NumberOfLoans"), newAmount);
    }

    function getLoanPointer(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("CurrentLoan"));
    }

    function setLoanPointer(address payable storageAddress, uint256 loanId) public {
        SnarkStorage(storageAddress).setUint(keccak256("CurrentLoan"), loanId);
        uint256 startDate = getLoanStartDate(storageAddress, loanId);
        setBottomBoundaryOfLoansPeriod(storageAddress, startDate);
    }

    function getLoanId(address payable storageAddress) public view returns (uint256) {
        uint256 loanId = getLoanPointer(storageAddress);
        while (isLoanFinished(storageAddress, loanId) && loanId > 0) {
            loanId = getNextLoan(storageAddress, loanId);
        }
        return loanId;
    }

    function isEmptyPointer(address payable storageAddress) public view returns (bool) {
        return (getLoanPointer(storageAddress) == 0);
    }

    function toShiftPointer(address payable storageAddress) public returns (uint256) {
        uint256 loanId = getLoanPointer(storageAddress);
        while (isLoanFinished(storageAddress, loanId) && (loanId > 0)) {
            setNumberOfLoans(storageAddress, getNumberOfLoans(storageAddress).sub(1));
            loanId = getLoanPointer(storageAddress);
            loanId = getNextLoan(storageAddress, loanId);
            setLoanPointer(storageAddress, loanId);
        }
        return loanId;
    }

    function isLoanActive(address payable storageAddress, uint256 loanId) public view returns (bool) {
        uint256 startDate = getLoanStartDate(storageAddress, loanId);
        uint256 endDate = getLoanEndDate(storageAddress, loanId);
        uint256 currentTime = block.timestamp; // solhint-disable-line
        return (startDate <= currentTime && endDate > currentTime);
    }

    function isLoanFinished(address payable storageAddress, uint256 loanId) public view returns (bool) {
        uint256 endDate = getLoanEndDate(storageAddress, loanId);
        return (endDate < block.timestamp); // solhint-disable-line
    }

    function getBottomBoundaryOfLoansPeriod(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("BottomBoundaryOfLoanPeriod"));
    }

    function setBottomBoundaryOfLoansPeriod(address payable storageAddress, uint256 minDate) public {
        SnarkStorage(storageAddress).setUint(keccak256("BottomBoundaryOfLoanPeriod"), minDate);
    }

    function getTopBoundaryOfLoansPeriod(address payable storageAddress) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256("TopBoundaryOfLoanPeriod"));
    }

    function setTopBoundaryOfLoansPeriod(address payable storageAddress, uint256 maxDate) public {
        SnarkStorage(storageAddress).setUint(keccak256("TopBoundaryOfLoanPeriod"), maxDate);
    }

    function getOwnerOfLoan(address payable storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(storageAddress).addressStorage(keccak256(abi.encodePacked("OwnerOfLoan", loanId)));
    }

    function setOwnerOfLoan(address payable storageAddress, uint256 loanId, address loanOwner) public {
        SnarkStorage(storageAddress).setAddress(keccak256(abi.encodePacked("OwnerOfLoan", loanId)), loanOwner);
    }

    function getLoanStartDate(address payable storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("LoanStartDate", loanId)));
    }

    function setLoanStartDate(address payable storageAddress, uint256 loanId, uint256 startDateTime) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("LoanStartDate", loanId)), startDateTime);
    }

    function getLoanEndDate(address payable storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("LoanEndDate", loanId)));
    }

    function setLoanEndDate(address payable storageAddress, uint256 loanId, uint256 endDateTime) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("LoanEndDate", loanId)), endDateTime);
    }

    function getNextLoan(address payable storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("NextLoan", loanId)));
    }

    function setNextLoan(address payable storageAddress, uint256 loanId, uint256 nextLoanId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("NextLoan", loanId)), nextLoanId);
    }

    function getPreviousLoan(address payable storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("PreviousLoan", loanId)));
    }

    function setPreviousLoan(address payable storageAddress, uint256 loanId, uint256 previousLoanId) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("PreviousLoan", loanId)), previousLoanId);
    }

    function getLoanPrice(address payable storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(storageAddress).uintStorage(keccak256(abi.encodePacked("LoanPrice", loanId)));
    }

    function setLoanPrice(address payable storageAddress, uint256 loanId, uint256 loanPrice) public {
        SnarkStorage(storageAddress).setUint(keccak256(abi.encodePacked("LoanPrice", loanId)), loanPrice);
    }

    function findPosition(address payable storageAddress, uint256 timestampStart, uint256 timestampEnd) 
        public view returns (uint256, uint256, bool)
    {
        uint256 afterLoanId;
        uint256 beforeLoanId;
        bool isCrossedPeriod;
        uint256 topBoundary = getTopBoundaryOfLoansPeriod(storageAddress);
        uint256 bottomBoundary = getBottomBoundaryOfLoansPeriod(storageAddress);
        if (isEmptyPointer(storageAddress)) {
            require(timestampStart > topBoundary,
                "Start of loan has to be bigger the last loan's end datetime");
        } else {
            if ((timestampStart < bottomBoundary && timestampEnd > topBoundary) ||
                (timestampStart < bottomBoundary && timestampEnd > bottomBoundary && timestampEnd < topBoundary) ||
                (timestampEnd > topBoundary && timestampStart > bottomBoundary && timestampStart < topBoundary)
            ) {
                isCrossedPeriod = true;
            } else {
                if (timestampStart < bottomBoundary && timestampEnd < bottomBoundary) {
                    beforeLoanId = getLoanPointer(storageAddress);
                } else if (timestampStart > topBoundary && timestampEnd > topBoundary) {
                    afterLoanId = getLoanPointer(storageAddress);
                    uint256 nloans = getNumberOfLoans(storageAddress);
                    if (nloans > 0) {
                        for (uint i = 0; i < nloans - 1; i++) {
                            afterLoanId = getNextLoan(storageAddress, afterLoanId);
                        }
                    }
                } else {
                    uint256 loanId = getLoanPointer(storageAddress);
                    uint256 startDate;
                    uint256 endDate;
                    while (loanId > 0) {
                        startDate = getLoanStartDate(storageAddress, loanId);
                        endDate = getLoanEndDate(storageAddress, loanId);

                        if ((timestampStart >= startDate && timestampStart <= endDate) || 
                            (timestampEnd >= startDate && timestampEnd <= endDate) ||
                            (timestampStart <= startDate && timestampEnd >= startDate)) {
                            beforeLoanId = 0;
                            afterLoanId = 0;
                            isCrossedPeriod = true;
                            break;
                        }

                        if (timestampEnd < startDate) {
                            beforeLoanId = loanId;
                            break;
                        }

                        if (timestampStart > endDate) {
                            afterLoanId = loanId;
                        }
                        
                        loanId = getNextLoan(storageAddress, loanId);
                    }
                }
            }
        }
        return (afterLoanId, beforeLoanId, isCrossedPeriod);
    }

    function addTokenToApprovedListForLoan(address payable storageAddress, uint256 tokenId) public {
        if (!isTokenInApprovedListForLoan(storageAddress, tokenId)) {
            uint256 position = getTotalNumberOfTokensInApprovedTokensForLoan(storageAddress);
            SnarkStorage(storageAddress)
                .setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)), tokenId);
            setIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId, position);
            SnarkStorage(storageAddress).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), true);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, position.add(1));
        }
    }

    function deleteTokenFromApprovedListForLoan(address payable storageAddress, uint256 tokenId) public {
        if (isTokenInApprovedListForLoan(storageAddress, tokenId)) {
            uint256 position = getIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId);
            uint256 maxPosition = getTotalNumberOfTokensInApprovedTokensForLoan(storageAddress);
            maxPosition = maxPosition.sub(1);
            if (position < maxPosition) {
                uint256 maxTokenId = getTokenFromApprovedTokensForLoanByIndex(storageAddress, maxPosition);
                setIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId, 0);
                setIndexOfTokenInApprovedTokensForLoan(storageAddress, maxTokenId, position);
                SnarkStorage(storageAddress).
                    setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)), maxTokenId);
            }
            SnarkStorage(storageAddress).
                setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", maxPosition)), 0);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, maxPosition);
            SnarkStorage(storageAddress).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), false);
        }
    }

    function getTotalNumberOfTokensInApprovedTokensForLoan(address payable storageAddress)
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).uintStorage(keccak256("totalNumberOfTokensInApprovedTokensForLoan"));
    }

    function setTotalNumberOfTokensInApprovedTokensForLoan(address payable storageAddress, uint256 newAmount) public {
        SnarkStorage(storageAddress).
            setUint(keccak256("totalNumberOfTokensInApprovedTokensForLoan"), newAmount);
    }

    function getIndexOfTokenInApprovedTokensForLoan(address payable storageAddress, uint256 tokenId) 
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("IndexOfTokenInApprovedTokensForLoan", tokenId)));
    }

    function setIndexOfTokenInApprovedTokensForLoan(
        address payable storageAddress, 
        uint256 tokenId, 
        uint256 position
    ) 
        public 
    {
        SnarkStorage(storageAddress).
            setUint(keccak256(abi.encodePacked("IndexOfTokenInApprovedTokensForLoan", tokenId)), position);
    }

    function isTokenInApprovedListForLoan(address payable storageAddress, uint256 tokenId) public view returns (bool) {
        return SnarkStorage(storageAddress).
            boolStorage(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)));
    }

    function getTokenFromApprovedTokensForLoanByIndex(address payable storageAddress, uint256 position) 
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)));
    }

    // not approved list for owner
    function addTokenToNotApprovedListForLoan(address payable storageAddress, address tokenOwner, uint256 tokenId)
        public 
    {
        if (!isTokenInNotApprovedListForLoan(storageAddress, tokenOwner, tokenId)) {
            uint256 position = getTotalNumberOfTokensInNotApprovedTokensForLoan(storageAddress, tokenOwner);
            SnarkStorage(storageAddress).
                setUint(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)), tokenId);
            setIndexOfTokenInNotApprovedTokensForLoan(storageAddress, tokenOwner, tokenId, position);
            SnarkStorage(storageAddress).
                setBool(keccak256(abi.encodePacked("isTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)), true);
            setTotalNumberOfTokensInNotApprovedTokensForLoan(storageAddress, tokenOwner, position.add(1));
        }
    }

    function deleteTokenFromNotApprovedListForLoan(
        address payable storageAddress, 
        address tokenOwner, 
        uint256 tokenId
    ) 
        public 
    {
        if (isTokenInNotApprovedListForLoan(storageAddress, tokenOwner, tokenId)) {
            uint256 position = getIndexOfTokenInNotApprovedTokensForLoan(storageAddress, tokenOwner, tokenId);
            uint256 maxPosition = getTotalNumberOfTokensInNotApprovedTokensForLoan(storageAddress, tokenOwner);
            maxPosition = maxPosition.sub(1);
            if (position < maxPosition) {
                uint256 maxTokenId = 
                    getTokenFromNotApprovedTokensForLoanByIndex(storageAddress, tokenOwner, maxPosition);
                setIndexOfTokenInNotApprovedTokensForLoan(storageAddress, tokenOwner, tokenId, 0);
                setIndexOfTokenInNotApprovedTokensForLoan(storageAddress, tokenOwner, maxTokenId, position);
                SnarkStorage(storageAddress).
                    setUint(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)), 
                        maxTokenId);
            }
            SnarkStorage(storageAddress).
                setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", maxPosition)), 0);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, maxPosition);
            SnarkStorage(storageAddress).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), false);
        }
    }

    function getTotalNumberOfTokensInNotApprovedTokensForLoan(address payable storageAddress, address tokenOwner) 
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress)
            .uintStorage(keccak256(abi.encodePacked("totalNumberOfTokensInNotApprovedTokensForLoan", tokenOwner)));
    }

    function setTotalNumberOfTokensInNotApprovedTokensForLoan(
        address payable storageAddress, 
        address tokenOwner, 
        uint256 newAmount
    ) 
        public 
    {
        SnarkStorage(storageAddress).
            setUint(keccak256(abi.encodePacked("totalNumberOfTokensInNotApprovedTokensForLoan", tokenOwner)), 
            newAmount
        );
    }

    function getIndexOfTokenInNotApprovedTokensForLoan(
        address payable storageAddress, 
        address tokenOwner, 
        uint256 tokenId
    )
        public 
        view 
        returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("IndexOfTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)));
    }

    function setIndexOfTokenInNotApprovedTokensForLoan(
        address payable storageAddress, 
        address tokenOwner, 
        uint256 tokenId, 
        uint256 position
    ) 
        public 
    {
        SnarkStorage(storageAddress).
            setUint(keccak256(abi.encodePacked("IndexOfTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)), 
            position
        );
    }

    function isTokenInNotApprovedListForLoan(address payable storageAddress, address tokenOwner, uint256 tokenId) 
        public view returns (bool) 
    {
        return SnarkStorage(storageAddress).
            boolStorage(keccak256(abi.encodePacked("isTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)));
    }

    function getTokenFromNotApprovedTokensForLoanByIndex(
        address payable storageAddress, 
        address tokenOwner, 
        uint256 position
    ) 
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)));
    }

    // array of owner loans
    function addLoanToOwnerList(address payable storageAddress, address loanOwner, uint256 loanId) public {
        if (!isLoanInOwnerList(storageAddress, loanOwner, loanId)) {
            uint256 position = getTotalNumberOfLoansInOwnerList(storageAddress, loanOwner);
            setLoanInOwnerListToIndex(storageAddress, loanOwner, position, loanId);
            setIndexOfLoanInOwnerList(storageAddress, loanOwner, loanId, position);
            setLoanInOwnerList(storageAddress, loanOwner, loanId, true);
            setTotalNumberOfLoansInOwnerList(storageAddress, loanOwner, position.add(1));
        }
    }

    function deleteLoanFromOwnerList(address payable storageAddress, address loanOwner, uint256 loanId) public {
        if (isLoanInOwnerList(storageAddress, loanOwner, loanId)) {
            uint256 position = getIndexOfLoanInOwnerList(storageAddress, loanOwner, loanId);
            uint256 maxPosition = getTotalNumberOfLoansInOwnerList(storageAddress, loanOwner);
            maxPosition = maxPosition.sub(1);
            if (position < maxPosition) {
                uint256 maxLoanId = getLoanFromOwnerListByIndex(storageAddress, loanOwner, maxPosition);
                setIndexOfLoanInOwnerList(storageAddress, loanOwner, maxLoanId, position);
                setLoanInOwnerListToIndex(storageAddress, loanOwner, position, maxLoanId);
            }
            setIndexOfLoanInOwnerList(storageAddress, loanOwner, loanId, 0);
            setTotalNumberOfLoansInOwnerList(storageAddress, loanOwner, maxPosition);
            setLoanInOwnerList(storageAddress, loanOwner, loanId, false);
        }
    }

    function getTotalNumberOfLoansInOwnerList(address payable storageAddress, address loanOwner) 
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("totalNumberOfLoansInOwnerList", loanOwner)));
    }

    function setTotalNumberOfLoansInOwnerList(
        address payable storageAddress,
        address loanOwner,
        uint256 newAmount
    ) 
        public
    {
        SnarkStorage(storageAddress).
            setUint(keccak256(abi.encodePacked("totalNumberOfLoansInOwnerList", loanOwner)), newAmount);
    }

    function getIndexOfLoanInOwnerList(address payable storageAddress, address loanOwner, uint256 loanId)
        public view returns (uint256) 
    {
        return SnarkStorage(storageAddress).
            uintStorage(keccak256(abi.encodePacked("IndexOfLoanInOwnerList", loanOwner, loanId)));
    }

    function setIndexOfLoanInOwnerList(
        address payable storageAddress, 
        address loanOwner, 
        uint256 loanId, 
        uint256 position
    )
        public 
    {
        SnarkStorage(storageAddress).
            setUint(keccak256(abi.encodePacked("IndexOfLoanInOwnerList", loanOwner, loanId)), position);
    }

    function isLoanInOwnerList(address payable storageAddress, address loanOwner, uint256 loanId)
        public view returns (bool)
    {
        return SnarkStorage(storageAddress).
            boolStorage(keccak256(abi.encodePacked("isLoanInOwnerList", loanOwner, loanId)));
    }

    function setLoanInOwnerList(address payable storageAddress, address loanOwner, uint256 loanId, bool isInList)
        public 
    {
        SnarkStorage(storageAddress).
            setBool(keccak256(abi.encodePacked("isLoanInOwnerList", loanOwner, loanId)), isInList);
    }

    function getLoanFromOwnerListByIndex(address payable storageAddress, address loanOwner, uint256 position)
        public view returns (uint256)
    {
        return SnarkStorage(storageAddress)
            .uintStorage(keccak256(abi.encodePacked("OwnerLoansList", loanOwner, position)));
    }

    function setLoanInOwnerListToIndex(
        address payable storageAddress, 
        address loanOwner, 
        uint256 position, 
        uint256 loanId
    )
        public
    {
        SnarkStorage(storageAddress)
            .setUint(keccak256(abi.encodePacked("OwnerLoansList", loanOwner, position)), loanId);
    }

    function markLoanAsDeleted(address payable storageAddress, uint256 loanId) public {
        SnarkStorage(storageAddress)
            .setBool(keccak256(abi.encodePacked("isLoanDeleted", loanId)), true);
    }

    function isLoanDeleted(address payable storageAddress, uint256 loanId) public view returns (bool) {
        return SnarkStorage(storageAddress)
            .boolStorage(keccak256(abi.encodePacked("isLoanDeleted", loanId)));
    }
}
