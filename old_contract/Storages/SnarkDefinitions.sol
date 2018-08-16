pragma solidity ^0.4.24;


contract SnarkDefinitions {

    // There are 4 states for an Offer and an Auction:
    // Preparing -recently created and not approved by participants
    // NotActive - created and approved by participants, but is not yet active (auctions only) 
    // Active - created, approved, and active 
    // Finished - finished when the artwork has sold 
    enum SaleStatus { Preparing, NotActive, Active, Finished }

    // Sale type (none, offer sale, auction, art loan)
    enum SaleType { None, Offer, Auction, Loan }

    /// @dev The main Artwork struct. Every digital artwork created by Snark 
    /// is represented by a copy of this structure.
    struct Artwork {
        address artist;                     // Address of artist
        bytes32 hashOfArtwork;              // Hash of file SHA3 (32 bytes)
        uint16 limitedEdition;              // Number of editions available for sale
        uint16 editionNumber;               // Edition number or id (2 bytes)
        uint256 lastPrice;                  // Last sale price (32 bytes)
        uint256 profitShareSchemaId;        // Id of profit share schema
        uint8 profitShareFromSecondarySale; // Profit share % during secondary sale going back to the artist and their list of participants
        string artworkUrl;                  // URL link to the artwork
    }

    /// @dev Structure contains a list of profit share schemes
    struct ProfitShareScheme {
        address[] participants;             // Address list of all participants involved in profit sharing
        uint8[] profits;                    // Profits list of all participants involved in profit sharing
    }

    struct Offer {
        uint256 tokenId;                    // Artwork ID
        uint256 price;                      // Proposed sale price in Ether for all artworks
        SaleStatus saleStatus;              // Offer status (2 possible states: Active, Finished)
    }

    struct Bid {
        uint256 tokenId;                    // Artwork ID
        uint256 price;                      // Offered price for the digital artwork
        SaleStatus saleStatus;              // Offer status (2 possible states: Active, Finished)
    }

    struct Auction {
        uint256 startingPrice;              // Starting price in wei
        uint256 endingPrice;                // Ending price in wei
        uint256 workingPrice;               // Current price
        uint64 startingDate;                // Block number when an auction should to start
        uint16 duration;                    // Auction duration in days
        uint256 countOfArtworks;            // Number of artworks offered in the Auction
        SaleStatus saleStatus;              // Status of the Auctioned artwork (4 possible states)
    }

}