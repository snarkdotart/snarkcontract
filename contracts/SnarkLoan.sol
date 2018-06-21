pragma solidity ^0.4.24;

import "./SnarkAuction.sol";


contract SnarkLoan is SnarkAuction {
    mapping (uint256 => uint256) internal tokenToLoanMap;        // Mapping of the digital artwork to the loan in which it is participating
    mapping (uint256 => uint256[]) internal loanToTokensMap;     // Mapping of a loan to tokens
    mapping (uint256 => address) internal loanToOwnerMap;        // Mapping of a loan with its owner
    mapping (address => uint256) internal ownerToCountLoansMap;  // Count of loans belonging to the same owner
}