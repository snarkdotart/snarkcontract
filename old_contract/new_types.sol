    mapping (string => uint256)                         private arrayNameToItemsCount; // "artworks" = 5

    mapping (string => mapping (bytes32 => bool))       private storageBytes32ToBool;
    mapping (string => mapping (uint8 => uint256[]))    private storageUint8ToUint256Array;
    mapping (string => mapping (uint256 => bytes32))    private storageUint256ToBytes32;
    mapping (string => mapping (uint256 => uint8))      private storageUint256ToUint8;
    mapping (string => mapping (uint256 => uint8[]))    private storageUint256ToUint8Array;
    mapping (string => mapping (uint256 => uint16))     private storageUint256ToUint16;
    mapping (string => mapping (uint256 => uint64))     private storageUint256ToUint64;
    mapping (string => mapping (uint256 => uint256))    private storageUint256ToUint256;
    mapping (string => mapping (uint256 => uint256[]))  private storageUint256ToUint256Array;
    mapping (string => mapping (uint256 => address))    private storageUint256ToAddress;
    mapping (string => mapping (uint256 => address[]))  private storageUint256ToAddressArray;
    mapping (string => mapping (uint256 => string))     private storageUint256ToString;

    mapping (string => mapping (address => address[]))  private storageAddressToAddressArray;
    mapping (string => mapping (address => uint256))    private storageAddressToUint256;
    mapping (string => mapping (address => uint256[]))  private storageAddressToUint256Array;
    mapping (string => mapping (address => bool))       private storageAddressToBool;


    mapping (uint256 => mapping (address => bool))      private tokenToParticipantApprovingMap; // Mapping token of revenue participant to their approval confirmation

    // use storageAddressToAddressArray instead of operatorToApprovalsMap
    mapping (address => mapping (address => bool))      private operatorToApprovalsMap; // Mapping from owner to approved operator



    ////////////////////////////////////////////////////////////////////////////////////////////////////

    // mapping (bytes32 => bool) private hashToUsedMap;                 // Mapping from hash to previously used indicator
    // mapping (uint8 => uint256[]) private saleStatusToOffersMap;      // Mapping status to offers
    // mapping (uint256 => bytes32) tokenToHashOfArtwork;               // struct Artwork
    // mapping (uint256 => uint8) internal tokenToSaleTypeMap;          // Artwork can only be in one of four states: 1. Not being sold, 2. Offered for sale at an offer price, 3. Auction sale, 4. Art loan. Must avoid any possibility of a double sale
    // mapping (uint256 => uint8) tokenToProfitShareFromSecondarySale;  // struct Artwork
    // mapping (uint256 => uint8) auctionToSaleStatus;                  // struct Auction
    // mapping (uint256 => uint8) offerToSaleStatus;                    // struct Offer
    // mapping (uint256 => uint8) bidToSaleStatus;                      // struct Bid
    // mapping (uint256 => uint8[]) schemeToProfits;                    // struct ProfitShareScheme
    // mapping (uint256 => uint16) tokenToLimitedEdition;               // struct Artwork
    // mapping (uint256 => uint16) tokenToEditionNumber;                // struct Artwork
    // mapping (uint256 => uint16) auctionToDuration;                   // struct Auction
    // mapping (uint256 => uint64) auctionToStartingDate;               // struct Auction
    // mapping (uint256 => uint256) private tokenToOfferMap;            // Mapping of artwork to offers
    // mapping (uint256 => uint256) internal tokenToAuctionMap;         // Mapping of the digital artwork to the auction in which it is participating
    // mapping (uint256 => uint256) internal tokenToLoanMap;            // Mapping of the digital artwork to the loan in which it is participating
    // mapping (uint256 => uint256) tokenToLastPrice;                   // struct Artwork
    // mapping (uint256 => uint256) tokenToProfitShareSchemaId;         // struct Artwork
    // mapping (uint256 => uint256) auctionToStartingPrice;             // struct Auction
    // mapping (uint256 => uint256) auctionToEndingPrice;               // struct Auction
    // mapping (uint256 => uint256) auctionToWorkingPrice;              // struct Auction
    // mapping (uint256 => uint256) auctionToCountOfArtworks;           // struct Auction
    // mapping (uint256 => uint256) offerToTokenId;                     // struct Offer
    // mapping (uint256 => uint256) offerToPrice;                       // struct Offer
    // mapping (uint256 => uint256) bidToTokenId;                       // struct Bid
    // mapping (uint256 => uint256) bidToPrice;                         // struct Bid
    // mapping (uint256 => uint256[]) internal auctionToTokensMap;      // Mapping of an auction to tokens
    // mapping (uint256 => uint256[]) private tokenToBidsMap;           // Mapping of artwork to bid
    // mapping (uint256 => uint256[]) internal loanToTokensMap;         // Mapping of a loan to tokens
    // mapping (uint256 => address) private tokenToApprovalsMap;        // Mapping from token ID to approved address
    // mapping (uint256 => address) private offerToOwnerMap;            // Mapping of offers to owner
    // mapping (uint256 => address) internal auctionToOwnerMap;         // Mapping of an auction with its owner
    // mapping (uint256 => address) internal loanToOwnerMap;            // Mapping of a loan with its owner
    // mapping (uint256 => address) private bidToOwnerMap;              // Mapping of bids to owner
    // mapping (uint256 => address) private tokenToOwnerMap;            // Mapping from token ID to owner
    // mapping (uint256 => address) tokenToArtist;                      // struct Artwork
    // mapping (uint256 => address[]) schemeToParticipants;             // struct ProfitShareScheme
    // mapping (uint256 => string) tokenToArtworkURL;                   // struct Artwork

    // mapping (address => uint256) internal ownerToCountAuctionsMap;   // Count of auctions belonging to the same owner
    // mapping (address => uint256) internal ownerToCountLoansMap;      // Count of loans belonging to the same owner
    // mapping (address => uint256) private pendingWithdrawals;         // Mapping of an address with its balance
    // mapping (address => uint256[]) private ownerToBidsMap;           // Mapping of owner to bids
    // mapping (address => uint256[]) private ownerToOffersMap;         // Mapping of owner to offers
    // mapping (address => uint256[]) private addressToPSSMap;          // Mapping from address of owner to profit share schemes (PSS)    
    // mapping (address => uint256[]) private artistToTokensMap;        // Mapping from artist to their Token IDs
    
    // mapping (address => uint256[]) private ownerToTokensMap;         // Mapping from owner to their Token IDs

    // mapping (address => bool) private accessAllowed; // Mapping from a contract address to access indicator



    ////////////////////////////////////////////////////////////////////////////////////////////////////

    enum SaleStatus { Preparing, NotActive, Active, Finished }

    // Sale type (none, offer sale, auction, art loan)
    enum SaleType { None, Offer, Auction, Loan }


    // Artwork[] private artworks;
    // ProfitShareScheme[] private profitShareSchemes;
    // Offer[] private offers;
    // Bid[] private bids;
    // Auction[] internal auctions;

    /// @dev The main Artwork struct. Every digital artwork created by Snark 
    /// is represented by a copy of this structure.

    struct Artwork {
        // address artist;                     // Address of artist
        // bytes32 hashOfArtwork;              // Hash of file SHA3 (32 bytes)
        // uint16 limitedEdition;              // Number of editions available for sale
        // uint16 editionNumber;               // Edition number or id (2 bytes)
        // uint256 lastPrice;                  // Last sale price (32 bytes)
        // uint256 profitShareSchemaId;        // Id of profit share schema
        // uint8 profitShareFromSecondarySale; // Profit share % during secondary sale going back to the artist and their list of participants
        // string artworkUrl;                  // URL link to the artwork
    }

    /// @dev Structure contains a list of profit share schemes
    struct ProfitShareScheme {
        // address[] participants;             // Address list of all participants involved in profit sharing
        // uint8[] profits;                    // Profits list of all participants involved in profit sharing
    }

    struct Offer {
        // uint256 tokenId;                    // Artwork ID
        // uint256 price;                      // Proposed sale price in Ether for all artworks
        // SaleStatus saleStatus;              // Offer status (2 possible states: Active, Finished)
    }

    struct Bid {
        // uint256 tokenId;                    // Artwork ID
        // uint256 price;                      // Offered price for the digital artwork
        // SaleStatus saleStatus;              // Offer status (2 possible states: Active, Finished)
    }

    struct Auction {
        // uint256 startingPrice;              // Starting price in wei
        // uint256 endingPrice;                // Ending price in wei
        // uint256 workingPrice;               // Current price
        // uint64 startingDate;                // Block number when an auction should to start
        // uint16 duration;                    // Auction duration in days
        // uint256 countOfArtworks;            // Number of artworks offered in the Auction
        // SaleStatus saleStatus;              // Status of the Auctioned artwork (4 possible states)
    }