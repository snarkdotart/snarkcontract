pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";


/// @title Contract creates the functionality to loans tokens
/// @author Vitali Hurski
contract SnarkLoan is Ownable {

    using SnarkBaseLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    address payable private _storage;
    address private _erc721;

    event LoanCreated(address indexed loanOwner, uint256 loanId);
    event LoanDeleted(uint256 loanId);
    
    modifier restrictedAccess() {
        if (SnarkBaseLib.isRestrictedAccess(_storage)) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }    

    modifier correctLoan(uint256 loanId) {
        require(
            loanId > 0 && loanId <= SnarkLoanLib.getNumberOfLoans(_storage), 
            "Loan id is wrong"
        );
        _;
    }

    modifier onlyLoanOwner(uint256 loanId) {
        require(
            msg.sender == SnarkLoanLib.getOwnerOfLoan(_storage, loanId), 
            "Only loan owner can borrow tokens"
        );
        _;
    }

    modifier onlyLoanOwnerOrSnark(uint256 loanId) {
        require(
            msg.sender == SnarkLoanLib.getOwnerOfLoan(_storage, loanId) ||
            msg.sender == owner, 
            "Only loan owner and Snark can call this function"
        );
        _;
    }

    /// @dev Contract Constructor
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address payable storageAddress, address erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }
    
    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy the contract on the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function setDefaultLoanDuration(uint256 duration) public onlyOwner {
        SnarkLoanLib.setDefaultLoanDuration(_storage, duration);
    }

    function getDefaultLoanDuration() public view returns (uint256) {
        return SnarkLoanLib.getDefaultLoanDuration(_storage);
    }

    function getLoanDetail(uint256 loanId) public view returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (
            SnarkLoanLib.getOwnerOfLoan(_storage, loanId),
            SnarkLoanLib.getLoanStartDate(_storage, loanId),
            SnarkLoanLib.getLoanEndDate(_storage, loanId),
            SnarkLoanLib.getPreviousLoan(_storage, loanId),
            SnarkLoanLib.getNextLoan(_storage, loanId),
            SnarkLoanLib.getLoanPrice(_storage, loanId)
        );
    }

    /// @dev Attributes of timestamp_start and timestamp_end should contain 10 digits only
    /// @param timestampStart Contains date and time of loan start
    /// @param timestampEnd Contain date and time of loan end
    function createLoan(uint256 timestampStart, uint256 timestampEnd) public payable restrictedAccess {
        require(SnarkBaseLib.getOwnedTokensCount(_storage, msg.sender) > 0, "User has to have at least one token");
        require(timestampStart > block.timestamp, "Start of loan less than current time"); // solhint-disable-line
        require(timestampEnd > timestampStart, "Datetime of a loan end has to be bigger the datetime of start one.");
        uint256 duration = (timestampEnd - timestampStart);
        require(duration <= getDefaultLoanDuration().mul(86400), "Duration exceeds a max value");

        SnarkLoanLib.toShiftPointer(_storage);

        uint256 afterLoanId;
        uint256 beforeLoanId;
        bool isCrossedPeriod;
        (afterLoanId, beforeLoanId, isCrossedPeriod) = 
            SnarkLoanLib.findPosition(_storage, timestampStart, timestampEnd);
        require(!isCrossedPeriod, "Selected period has not to crossed with existing loans");

        // Add loan and set pointer
        uint256 loanId = SnarkLoanLib.increaseMaxLoanId(_storage);
        SnarkLoanLib.setOwnerOfLoan(_storage, loanId, msg.sender);
        SnarkLoanLib.setLoanStartDate(_storage, loanId, timestampStart);
        SnarkLoanLib.setLoanEndDate(_storage, loanId, timestampEnd);
        SnarkLoanLib.setNextLoan(_storage, loanId, beforeLoanId);
        SnarkLoanLib.setPreviousLoan(_storage, loanId, afterLoanId);
        SnarkLoanLib.setLoanPrice(_storage, loanId, msg.value);
        
        // Keep the ether in the storage contract
        if (msg.value > 0) _storage.transfer(msg.value);

        // Update number of loans
        SnarkLoanLib.setNumberOfLoans(_storage, SnarkLoanLib.getNumberOfLoans(_storage).add(1));
        // Add loan to the owner list
        SnarkLoanLib.addLoanToOwnerList(_storage, msg.sender, loanId);

        if (afterLoanId == 0) { 
            SnarkLoanLib.setLoanPointer(_storage, loanId);
        } else {
            SnarkLoanLib.setNextLoan(_storage, afterLoanId, loanId);
        }

        if (beforeLoanId == 0) { 
            SnarkLoanLib.setTopBoundaryOfLoansPeriod(_storage, timestampEnd);
        } else {
            SnarkLoanLib.setPreviousLoan(_storage, beforeLoanId, loanId);
        }

        emit LoanCreated(msg.sender, loanId);
    }

    function deleteLoan(uint256 loanId) public onlyLoanOwnerOrSnark(loanId) {
        bool isDeleted = SnarkLoanLib.isLoanDeleted(_storage, loanId);
        require(isDeleted == false, "Loan does not exist");

        uint256 beforeLoanId = SnarkLoanLib.getPreviousLoan(_storage, loanId);
        uint256 nextLoanId = SnarkLoanLib.getNextLoan(_storage, loanId);
        uint256 countOfLoans = SnarkLoanLib.getNumberOfLoans(_storage);

        if (beforeLoanId == 0 && nextLoanId == 0) {
            SnarkLoanLib.setLoanPointer(_storage, 0);
            SnarkLoanLib.setBottomBoundaryOfLoansPeriod(_storage, 0);
            SnarkLoanLib.setTopBoundaryOfLoansPeriod(_storage, 0);
            if (countOfLoans > 0) {
                SnarkLoanLib.setNumberOfLoans(_storage, countOfLoans.sub(1));
            }
        }
        if (beforeLoanId == 0 && nextLoanId > 0) {
            SnarkLoanLib.setPreviousLoan(_storage, nextLoanId, 0);
            uint256 pointerToLoan = SnarkLoanLib.getLoanPointer(_storage);
            if (pointerToLoan == loanId) {
                SnarkLoanLib.setLoanPointer(_storage, nextLoanId);
            }
            uint256 bottomTime = SnarkLoanLib.getLoanStartDate(_storage, nextLoanId);
            SnarkLoanLib.setBottomBoundaryOfLoansPeriod(_storage, bottomTime);
            if (countOfLoans > 0) {
                SnarkLoanLib.setNumberOfLoans(_storage, countOfLoans.sub(1));
            }
        }
        if (beforeLoanId > 0 && nextLoanId == 0) {
            SnarkLoanLib.setNextLoan(_storage, beforeLoanId, 0);
            uint256 topTime = SnarkLoanLib.getLoanEndDate(_storage, beforeLoanId);
            SnarkLoanLib.setTopBoundaryOfLoansPeriod(_storage, topTime);
            if (countOfLoans > 0) {
                SnarkLoanLib.setNumberOfLoans(_storage, countOfLoans.sub(1));
            }
        }
        if (beforeLoanId > 0 && nextLoanId > 0) {
            SnarkLoanLib.setNextLoan(_storage, beforeLoanId, nextLoanId);
            SnarkLoanLib.setPreviousLoan(_storage, nextLoanId, beforeLoanId);
            if (countOfLoans > 0) {
                SnarkLoanLib.setNumberOfLoans(_storage, countOfLoans.sub(1));
            }
        }
        // Remove loan from the owner list
        address loanOwner = SnarkLoanLib.getOwnerOfLoan(_storage, loanId);
        SnarkLoanLib.deleteLoanFromOwnerList(_storage, loanOwner, loanId);
        
        SnarkLoanLib.markLoanAsDeleted(_storage, loanId);
        toShiftPointer();
        
        emit LoanDeleted(loanId);
    }

    function getNumberOfLoans() public view returns (uint256) {
        return SnarkLoanLib.getNumberOfLoans(_storage);
    }

    function getListOfLoans() public view returns (uint256[] memory) {
        uint256 numberOfLoans = getNumberOfLoans();
        uint256[] memory loans = new uint256[](numberOfLoans);
        if (numberOfLoans > 0) {
            uint256 id = SnarkLoanLib.getLoanId(_storage);
            for (uint256 i = 0; i < numberOfLoans; i++) {
                loans[i] = id;
                id = SnarkLoanLib.getNextLoan(_storage, id);
            }
        }
        return loans;
    }

    function getListOfLoansOfOwner(address loanOwner) public view returns (uint256[] memory) {
        uint256 numberOfLoans = getCountOfOwnerLoans(loanOwner);
        uint256[] memory loansList = new uint256[](numberOfLoans);
        uint256 loanId;
        for (uint256 i = 0; i < numberOfLoans; i++) {
            loanId = SnarkLoanLib.getLoanFromOwnerListByIndex(_storage, loanOwner, i);
            if (!isLoanFinished(loanId)) {
                loansList[i] = loanId;
            }
        }
        return loansList;
    }

    function getCountOfOwnerLoans(address loanOwner) public view returns (uint256) {
        uint256 amountOfAllOwnerLoans = SnarkLoanLib.getTotalNumberOfLoansInOwnerList(_storage, loanOwner);
        uint256 amountOfActiveOwnerLoans;
        uint256 loanId;
        for (uint256 i = 0; i < amountOfAllOwnerLoans; i++) {
            loanId = SnarkLoanLib.getLoanFromOwnerListByIndex(_storage, loanOwner, i);
            if (!isLoanFinished(loanId)) {
                amountOfActiveOwnerLoans.add(1);
            }
        }
        return amountOfActiveOwnerLoans;
    }

    function getLoanId() public view returns (uint256) {
        return SnarkLoanLib.getLoanId(_storage);
    }

    function doUserHaveAccessToToken(address userWalletId, uint256 tokenId) public view returns (bool) {
        address realOwner = SnarkBaseLib.getOwnerOfToken(_storage, tokenId);
        bool isUserHasAccess = (userWalletId == realOwner);
        if (!isUserHasAccess) {
            uint256 loanId = SnarkLoanLib.getLoanId(_storage);
            if (SnarkLoanLib.isLoanActive(_storage, loanId)) {
                address loanOwner = SnarkLoanLib.getOwnerOfLoan(_storage, loanId);
                bool isApproved = SnarkLoanLib.isTokenInApprovedListForLoan(_storage, tokenId);
                isUserHasAccess = (loanOwner == userWalletId && isApproved);
            }
        }
        return isUserHasAccess;
    }

    function isLoanActive(uint256 loanId) public view returns (bool) {
        return SnarkLoanLib.isLoanActive(_storage, loanId);
    }

    function isLoanFinished(uint256 loanId) public view returns (bool) {
        return SnarkLoanLib.isLoanFinished(_storage, loanId);
    }

    function isLoanDeleted(uint256 loanId) public view returns (bool) {
        return SnarkLoanLib.isLoanDeleted(_storage, loanId);
    }

    function toShiftPointer() public {
        uint256 loanId = SnarkLoanLib.getLoanPointer(_storage);
        if (SnarkLoanLib.isLoanFinished(_storage, loanId) || 
            SnarkLoanLib.isLoanDeleted(_storage, loanId)) {
            SnarkLoanLib.toShiftPointer(_storage);
        }
    }

    function getListOfBusyDates() public view returns(uint256[] memory, uint256[] memory) {
        uint256 loanId = getLoanId();
        uint256 countOfLoans;
        while (loanId > 0) {
            countOfLoans++;
            loanId = SnarkLoanLib.getNextLoan(_storage, loanId);
        }
        uint256[] memory startBusyDate = new uint256[](countOfLoans);
        uint256[] memory endBusyDate = new uint256[](countOfLoans);
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 index;
        loanId = getLoanId();
        while (loanId > 0) {
            (, startTimestamp, endTimestamp, , ,) = getLoanDetail(loanId);
            startBusyDate[index] = startTimestamp;
            endBusyDate[index] = endTimestamp;
            loanId = SnarkLoanLib.getNextLoan(_storage, loanId);
            index = index.add(1);
        }
        return (startBusyDate, endBusyDate);
    }
}
