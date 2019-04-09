pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./snarklibs/SnarkBaseLib.sol";
// import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";
import "./openzeppelin/SafeMath.sol";
// import "./snarklibs/SnarkLoanLibExt.sol";


/// @title Contract provides a functionality to work with loans
/// @author Vitali Hurski
contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    // using SnarkCommonLib for address;
    using SnarkLoanLib for address;
    using SafeMath for uint256;

    address private _storage;
    address private _erc721;

    // event LoanCreated(address indexed loanBidOwner, uint256 loanId);
    // event LoanStarted(uint256 loanId);
    // event LoanFinished(uint256 loanId);
    // event LoanDeleted(uint256 loanId);
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

    /// @dev Constructor of contract
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address storageAddress, address erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }
    
    /// @notice Will receive any eth sent to the contract
    function() external payable {} // solhint-disable-line

    /// @dev Function to destroy the contract in the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function setDefaultLoanDuration(uint256 duration) public onlyOwner {
        SnarkLoanLib.setDefaultLoanDuration(_storage, duration);
    }

    function getDefaultLoanDuration() public view returns (uint256) {
        return SnarkLoanLib.getDefaultLoanDuration(_storage);
    }

    function getLoanDetail(uint256 loanId) public view returns (address, uint256, uint256, uint256, uint256) {
        return (
            SnarkLoanLib.getOwnerOfLoan(_storage, loanId),
            SnarkLoanLib.getLoanStartDate(_storage, loanId),
            SnarkLoanLib.getLoanEndDate(_storage, loanId),
            SnarkLoanLib.getPreviousLoan(_storage, loanId),
            SnarkLoanLib.getNextLoan(_storage, loanId)
        );
    }

    /// @dev attributes of timestamp_start and timestamp_end should contain 10 digits only
    /// @param timestampStart Contain date and time when a loan has to start
    /// @param timestampEnd Contain date and time when a loan has to end
    function createLoan(uint256 timestampStart, uint256 timestampEnd) public payable restrictedAccess {
        require(timestampStart > block.timestamp, "Start of loan less than current time"); // solhint-disable-line
        require(timestampEnd > timestampStart, "Datetime of a loan end has to be bigger the datetime of start one.");
        uint256 duration = (timestampEnd - timestampStart).div(86400);
        require(duration <= getDefaultLoanDuration(), "Duration exceeds a max value");

        SnarkLoanLib.toShiftPointer(_storage);
        uint256 afterLoanId;
        uint256 beforeLoanId;
        bool isCrossedPeriod;
        (afterLoanId, beforeLoanId, isCrossedPeriod) = 
            SnarkLoanLib.findPosition(_storage, timestampStart, timestampEnd);
        require(isCrossedPeriod == false, "Selected period has not to crossed with existing loans");

        // а тут уже добавляем сам лоан в систему и настраиваем поинтер
        uint256 loanId = SnarkLoanLib.increaseMaxLoanId(_storage);
        SnarkLoanLib.setOwnerOfLoan(_storage, loanId, msg.sender);
        SnarkLoanLib.setLoanStartDate(_storage, loanId, timestampStart);
        SnarkLoanLib.setLoanEndDate(_storage, loanId, timestampEnd);
        SnarkLoanLib.setNextLoan(_storage, loanId, beforeLoanId);
        SnarkLoanLib.setPreviousLoan(_storage, loanId, afterLoanId);

        // изменяем количество лоанов
        SnarkLoanLib.setNumberOfLoans(_storage, SnarkLoanLib.getNumberOfLoans(_storage).add(1));

        // 1. изменить границы, если надо 
        // 2. ссылки у соседних элементов
        // 3. изменить pointer, если надо
        if (afterLoanId == 0) { 
            SnarkLoanLib.setBottomBoundaryOfLoansPeriod(_storage, timestampStart); 
            SnarkLoanLib.setLoanPointer(_storage, loanId);
        } else {
            SnarkLoanLib.setNextLoan(_storage, afterLoanId, loanId);
        }

        if (beforeLoanId == 0) { 
            SnarkLoanLib.setTopBoundaryOfLoansPeriod(_storage, timestampEnd); 
        } else {
            SnarkLoanLib.setPreviousLoan(_storage, beforeLoanId, loanId);
        }
    }

    // function getListOfLoans
    // function deleteLoan
}