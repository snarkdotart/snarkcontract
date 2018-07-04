pragma solidity ^0.4.24;


contract SnarkDefinitions {
    
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

}