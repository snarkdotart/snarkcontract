pragma solidity >=0.5.4;


contract SnarkDefinitions {

    // There are 4 states for an Offer:
    // Preparing -recently created and not approved by participants
    // NotActive - created and approved by participants, but is not yet active (auctions only) 
    // Active - created, approved, and active 
    // Finished - finished when the artwork has sold 
    enum SaleStatus { Preparing, NotActive, Active, Finished }

    // Sale type (none, offer sale, art loan)
    enum SaleType { None, Offer, Loan }
}
