pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";
import "./SnarkLoanLib.sol";


contract SnarkLoan is Ownable, SnarkDefinitions {

    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;

    address private _storage;

    event LoanCreated(address indexed loanOwner, uint256 loanId);

    constructor(address storageAddress) public {
        _storage = storageAddress;
    }

    // modifier onlyLoanOwner()

    function createLoan(
        uint256 artworkId,
        uint256 price,
        uint256 startDate,
        uint256 duration,
        address destinationWallet
    ) 
        public 
    {
        uint256 loanId = _storage.createLoan(
            artworkId,
            price,
            startDate,
            duration,
            destinationWallet
        );
        emit LoanCreated(msg.sender, loanId);
    }
}
