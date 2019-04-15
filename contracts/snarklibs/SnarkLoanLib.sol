pragma solidity >=0.5.0;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";


/// @author Vitali Hurski
library SnarkLoanLib {

    using SafeMath for uint256;

    /// @notice returns maximum duration for which a token can be loaned  
    function getDefaultLoanDuration(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("defaultLoanDuration"));
    }

    /// @notice set maximum duration for which a token can be loaned  
    function setDefaultLoanDuration(address storageAddress, uint256 duration) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("defaultLoanDuration"), duration);
    }

    function increaseMaxLoanId(address storageAddress) public returns (uint256) {
        uint256 maxLoanId = getMaxLoanId(storageAddress);
        maxLoanId = maxLoanId.add(1);
        setMaxLoanId(storageAddress, maxLoanId);
        return maxLoanId;
    }

    function getMaxLoanId(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("MaxLoanId"));
    }

    function setMaxLoanId(address storageAddress, uint256 loanId) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("MaxLoanId"), loanId);
    }

    function getNumberOfLoans(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("NumberOfLoans"));
    }

    function setNumberOfLoans(address storageAddress, uint256 newAmount) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("NumberOfLoans"), newAmount);
    }

    function getLoanPointer(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("CurrentLoan"));
    }

    function setLoanPointer(address storageAddress, uint256 loanId) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("CurrentLoan"), loanId);
    }

    function isEmptyPointer(address storageAddress) public view returns (bool) {
        return (getLoanPointer(storageAddress) == 0);
    }

    function toShiftPointer(address storageAddress) public returns (uint256) {
        uint256 loanId = getLoanPointer(storageAddress);
        while (isLoanFinished(storageAddress) && loanId > 0) {
            setNumberOfLoans(storageAddress, getNumberOfLoans(storageAddress).sub(1));
            loanId = getLoanPointer(storageAddress);
            loanId = getNextLoan(storageAddress, loanId);
            setLoanPointer(storageAddress, loanId);
        }
        return loanId;
    }

    function isLoanActive(address storageAddress) public view returns (bool) {
        uint256 loanId = getLoanPointer(storageAddress);
        uint256 startDate = getLoanStartDate(storageAddress, loanId);
        uint256 endDate = getLoanEndDate(storageAddress, loanId);
        uint256 currentTime = block.timestamp; // solhint-disable-line
        return (startDate <= currentTime && endDate > currentTime);
    }

    function isLoanFinished(address storageAddress) public view returns (bool) {
        uint256 loanId = getLoanPointer(storageAddress);
        uint256 endDate = getLoanEndDate(storageAddress, loanId);
        return (endDate < block.timestamp); // solhint-disable-line
    }

    function getBottomBoundaryOfLoansPeriod(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("BottomBoundaryOfLoanPeriod"));
    }

    function setBottomBoundaryOfLoansPeriod(address storageAddress, uint256 minDate) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("BottomBoundaryOfLoanPeriod"), minDate);
    }

    function getTopBoundaryOfLoansPeriod(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress))).uintStorage(keccak256("TopBoundaryOfLoanPeriod"));
    }

    function setTopBoundaryOfLoansPeriod(address storageAddress, uint256 maxDate) public {
        SnarkStorage(address(uint160(storageAddress))).setUint(keccak256("TopBoundaryOfLoanPeriod"), maxDate);
    }

    function getOwnerOfLoan(address storageAddress, uint256 loanId) public view returns (address) {
        return SnarkStorage(address(uint160(storageAddress)))
            .addressStorage(keccak256(abi.encodePacked("OwnerOfLoan", loanId)));
    }

    function setOwnerOfLoan(address storageAddress, uint256 loanId, address loanOwner) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setAddress(keccak256(abi.encodePacked("OwnerOfLoan", loanId)), loanOwner);
    }

    function getLoanStartDate(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("LoanStartDate", loanId)));
    }

    function setLoanStartDate(address storageAddress, uint256 loanId, uint256 startDateTime) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("LoanStartDate", loanId)), startDateTime);
    }

    function getLoanEndDate(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("LoanEndDate", loanId)));
    }

    function setLoanEndDate(address storageAddress, uint256 loanId, uint256 endDateTime) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("LoanEndDate", loanId)), endDateTime);
    }

    function getNextLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("NextLoan", loanId)));
    }

    function setNextLoan(address storageAddress, uint256 loanId, uint256 nextLoanId) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("NextLoan", loanId)), nextLoanId);
    }

    function getPreviousLoan(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("PreviousLoan", loanId)));
    }

    function setPreviousLoan(address storageAddress, uint256 loanId, uint256 previousLoanId) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("PreviousLoan", loanId)), previousLoanId);
    }

    function getLoanPrice(address storageAddress, uint256 loanId) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("LoanPrice", loanId)));
    }

    function setLoanPrice(address storageAddress, uint256 loanId, uint256 loanPrice) public {
        SnarkStorage(address(uint160(storageAddress)))
            .setUint(keccak256(abi.encodePacked("LoanPrice", loanId)), loanPrice);
    }

    function findPosition(address storageAddress, uint256 timestampStart, uint256 timestampEnd) 
        public view returns (uint256, uint256, bool)
    {
        uint256 afterLoanId = 0;
        uint256 beforeLoanId = 0;
        bool isCrossedPeriod = false;
        if (isEmptyPointer(storageAddress)) {
            require(timestampStart > getTopBoundaryOfLoansPeriod(storageAddress),
                "Start of loan has to be bigger the last loan's end datetime");
        } else {
            if (timestampStart < getBottomBoundaryOfLoansPeriod(storageAddress) &&
                timestampEnd < getBottomBoundaryOfLoansPeriod(storageAddress)) {
                beforeLoanId = getLoanPointer(storageAddress);
            } else if (
                timestampStart > getTopBoundaryOfLoansPeriod(storageAddress) &&
                timestampEnd > getTopBoundaryOfLoansPeriod(storageAddress)
            ) {
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
                    if (timestampStart > startDate && timestampEnd > endDate) {
                        afterLoanId = loanId;
                    } else if (timestampStart < startDate && timestampEnd < endDate) {
                        beforeLoanId = loanId;
                    } else {
                        isCrossedPeriod = true;
                        break;
                    }
                    loanId = getNextLoan(storageAddress, loanId);
                }
            }
        }
        return (afterLoanId, beforeLoanId, isCrossedPeriod);
    }

    function addTokenToApprovedListForLoan(address storageAddress, uint256 tokenId) public {
        if (!isTokenInApprovedListForLoan(storageAddress, tokenId)) {
            uint256 position = getTotalNumberOfTokensInApprovedTokensForLoan(storageAddress);
            SnarkStorage(address(uint160(storageAddress))).
                setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)), tokenId);
            setIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId, position);
            SnarkStorage(address(uint160(storageAddress))).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), true);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, position.add(1));
        }
    }

    function deleteTokenFromApprovedListForLoan(address storageAddress, uint256 tokenId) public {
        if (isTokenInApprovedListForLoan(storageAddress, tokenId)) {
            uint256 position = getIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId);
            uint256 maxPosition = getTotalNumberOfTokensInApprovedTokensForLoan(storageAddress);
            maxPosition = maxPosition.sub(1);
            if (position < maxPosition) {
                uint256 maxTokenId = getTokenFromApprovedTokensForLoanByIndex(storageAddress, maxPosition);
                setIndexOfTokenInApprovedTokensForLoan(storageAddress, tokenId, 0);
                setIndexOfTokenInApprovedTokensForLoan(storageAddress, maxTokenId, position);
                SnarkStorage(address(uint160(storageAddress))).
                    setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)), maxTokenId);
            }
            SnarkStorage(address(uint160(storageAddress))).
                setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", maxPosition)), 0);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, maxPosition);
            SnarkStorage(address(uint160(storageAddress))).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), false);
        }
    }

    function getTotalNumberOfTokensInApprovedTokensForLoan(address storageAddress) public view returns (uint256) {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256("totalNumberOfTokensInApprovedTokensForLoan"));
    }

    function setTotalNumberOfTokensInApprovedTokensForLoan(address storageAddress, uint256 newAmount) public {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256("totalNumberOfTokensInApprovedTokensForLoan"), newAmount);
    }

    function getIndexOfTokenInApprovedTokensForLoan(address storageAddress, uint256 tokenId) 
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("IndexOfTokenInApprovedTokensForLoan", tokenId)));
    }

    function setIndexOfTokenInApprovedTokensForLoan(
        address storageAddress, 
        uint256 tokenId, 
        uint256 position
    ) 
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("IndexOfTokenInApprovedTokensForLoan", tokenId)), position);
    }

    function isTokenInApprovedListForLoan(address storageAddress, uint256 tokenId) public view returns (bool) {
        return SnarkStorage(address(uint160(storageAddress))).
            boolStorage(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)));
    }

    function getTokenFromApprovedTokensForLoanByIndex(address storageAddress, uint256 position) 
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("ApprovedTokensForLoan", position)));
    }

    // not approved list for owner
    function addTokenToNotApprovedListForLoan(address storageAddress, address tokenOwner, uint256 tokenId) public {
        if (!isTokenInNotApprovedListForLoan(storageAddress, tokenOwner, tokenId)) {
            uint256 position = getTotalNumberOfTokensInNotApprovedTokensForLoan(storageAddress, tokenOwner);
            SnarkStorage(address(uint160(storageAddress))).
                setUint(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)), tokenId);
            setIndexOfTokenInNotApprovedTokensForLoan(storageAddress, tokenOwner, tokenId, position);
            SnarkStorage(address(uint160(storageAddress))).
                setBool(keccak256(abi.encodePacked("isTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)), true);
            setTotalNumberOfTokensInNotApprovedTokensForLoan(storageAddress, tokenOwner, position.add(1));
        }
    }

    function deleteTokenFromNotApprovedListForLoan(
        address storageAddress, 
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
                SnarkStorage(address(uint160(storageAddress))).
                    setUint(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)), 
                        maxTokenId);
            }
            SnarkStorage(address(uint160(storageAddress))).
                setUint(keccak256(abi.encodePacked("ApprovedTokensForLoan", maxPosition)), 0);
            setTotalNumberOfTokensInApprovedTokensForLoan(storageAddress, maxPosition);
            SnarkStorage(address(uint160(storageAddress))).
                setBool(keccak256(abi.encodePacked("isTokenInApprovedTokensForLoan", tokenId)), false);
        }
    }

    function getTotalNumberOfTokensInNotApprovedTokensForLoan(address storageAddress, address tokenOwner) 
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress)))
            .uintStorage(keccak256(abi.encodePacked("totalNumberOfTokensInNotApprovedTokensForLoan", tokenOwner)));
    }

    function setTotalNumberOfTokensInNotApprovedTokensForLoan(
        address storageAddress, 
        address tokenOwner, 
        uint256 newAmount
    ) 
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("totalNumberOfTokensInNotApprovedTokensForLoan", tokenOwner)), 
            newAmount
        );
    }

    function getIndexOfTokenInNotApprovedTokensForLoan(address storageAddress, address tokenOwner, uint256 tokenId)
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("IndexOfTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)));
    }

    function setIndexOfTokenInNotApprovedTokensForLoan(
        address storageAddress, 
        address tokenOwner, 
        uint256 tokenId, 
        uint256 position
    ) 
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("IndexOfTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)), 
            position
        );
    }

    function isTokenInNotApprovedListForLoan(address storageAddress, address tokenOwner, uint256 tokenId) 
        public view returns (bool) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            boolStorage(keccak256(abi.encodePacked("isTokenInNotApprovedTokensForLoan", tokenOwner, tokenId)));
    }

    function getTokenFromNotApprovedTokensForLoanByIndex(
        address storageAddress, 
        address tokenOwner, 
        uint256 position
    ) 
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("NotApprovedTokensForLoan", tokenOwner, position)));
    }

    // array of owner loans
    function addLoanToOwnerList(address storageAddress, address loanOwner, uint256 loanId) public {
        if (!isLoanInOwnerList(storageAddress, loanOwner, loanId)) {
            uint256 position = getTotalNumberOfLoansInOwnerList(storageAddress, loanOwner);
            setLoanInOwnerListToIndex(storageAddress, loanOwner, position, loanId);
            setIndexOfLoanInOwnerList(storageAddress, loanOwner, loanId, position);
            setLoanInOwnerList(storageAddress, loanOwner, loanId, true);
            setTotalNumberOfLoansInOwnerList(storageAddress, loanOwner, position.add(1));
        }
    }

    function deleteLoanFromOwnerList(address storageAddress, address loanOwner, uint256 loanId) public {
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

    function getTotalNumberOfLoansInOwnerList(address storageAddress, address loanOwner) 
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("totalNumberOfLoansInOwnerList", loanOwner)));
    }

    function setTotalNumberOfLoansInOwnerList(address storageAddress, address loanOwner, uint256 newAmount) public {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("totalNumberOfLoansInOwnerList", loanOwner)), newAmount);
    }

    function getIndexOfLoanInOwnerList(address storageAddress, address loanOwner, uint256 loanId)
        public view returns (uint256) 
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("IndexOfLoanInOwnerList", loanOwner, loanId)));
    }

    function setIndexOfLoanInOwnerList(address storageAddress, address loanOwner, uint256 loanId, uint256 position)
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("IndexOfLoanInOwnerList", loanOwner, loanId)), position);
    }

    function isLoanInOwnerList(address storageAddress, address loanOwner, uint256 loanId)
        public view returns (bool)
    {
        return SnarkStorage(address(uint160(storageAddress))).
            boolStorage(keccak256(abi.encodePacked("isLoanInOwnerList", loanOwner, loanId)));
    }

    function setLoanInOwnerList(address storageAddress, address loanOwner, uint256 loanId, bool isInList)
        public 
    {
        SnarkStorage(address(uint160(storageAddress))).
            setBool(keccak256(abi.encodePacked("isLoanInOwnerList", loanOwner, loanId)), isInList);
    }

    function getLoanFromOwnerListByIndex(address storageAddress, address loanOwner, uint256 position)
        public view returns (uint256)
    {
        return SnarkStorage(address(uint160(storageAddress))).
            uintStorage(keccak256(abi.encodePacked("OwnerLoansList", loanOwner, position)));

    }

    function setLoanInOwnerListToIndex(address storageAddress, address loanOwner, uint256 position, uint256 loanId)
        public
    {
        SnarkStorage(address(uint160(storageAddress))).
            setUint(keccak256(abi.encodePacked("OwnerLoansList", loanOwner, position)), loanId);
    }
}
