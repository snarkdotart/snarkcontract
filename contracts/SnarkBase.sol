/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @dev See the Snark contract documentation to understand how the contract is structured.
pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./openzeppelin/SafeMath.sol";
import "./snarklibs/SnarkBaseExtraLib.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";


contract SnarkBase is Ownable { 
    
    using SafeMath for uint256;
    using SnarkBaseExtraLib for address;
    using SnarkBaseLib for address;
    using SnarkCommonLib for address;
    using SnarkLoanLib for address;

    /*** STORAGE ***/

    address payable private _storage;
    address payable private _erc721;

    /*** EVENTS ***/

    /// @dev TokenCreatedEvent is executed when a new token is created.
    event TokenCreated(address indexed tokenOwner, string hashOfToken, uint256 tokenId);
    /// @dev Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address indexed schemeOwner, uint256 profitShareSchemeId);
    /// @dev Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address indexed participant, uint256 tokenId);
    
    modifier restrictedAccess() {
        if (SnarkBaseLib.isRestrictedAccess(_storage)) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

    /// @dev Modifier that checks that an owner has a specific token
    /// @param tokenId Token ID
    modifier onlyOwnerOf(uint256 tokenId) {
        require(msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenId));
        _;
    }

    /// @dev Modifier that checks that an owner possesses multiple tokens
    /// @param tokenIds Array of token IDs
    modifier onlyOwnerOfMany(uint256[] memory tokenIds) {
        bool isOwnerOfAll = true;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            isOwnerOfAll = isOwnerOfAll && 
                (msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenIds[i]));
        }
        require(isOwnerOfAll);
        _;
    }
    
    /// @dev Modifier that only allows the artist to do an operation
    /// @param tokenId Token Id
    modifier onlyArtistOf(uint256 tokenId) {
        address artist = SnarkBaseLib.getTokenArtist(_storage, tokenId);
        require(msg.sender == artist);
        _;
    }

    modifier onlyProfitShareSchemeOfOwner(uint256 tokenId, uint256 schemeId) {
        require(schemeId > 0, "id of scheme can't be zero");
        
        address artist = SnarkBaseLib.getTokenArtist(_storage, tokenId);
        require(msg.sender == artist, "Only artist can change the profit share scheme");

        bool isSchemeOwner = false;
        uint256 schemeNumber = getNumberOfProfitShareSchemesForOwner(artist);        
        for (uint256 i = 0; i < schemeNumber; i++) {
            uint256 schId = getProfitShareSchemeIdForOwner(artist, i);
            isSchemeOwner = isSchemeOwner || (schId == schemeId);
        }
        require(isSchemeOwner == true, "Profit share scheme is not your");
        _;
    }

    /// @dev Modifier that allows access for a participant only
    modifier onlyParticipantOf(uint256 tokenId) {
        bool isItParticipant = false;
        uint256 schemeId = SnarkBaseExtraLib.getTokenProfitShareSchemeId(_storage, tokenId);
        uint256 participantsCount = 
            SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(_storage, schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = 
                SnarkBaseExtraLib.getParticipantOfProfitShareScheme(_storage, schemeId, i);
            if (msg.sender == participant) { 
                isItParticipant = true; 
                break; 
            }
        }
        require(isItParticipant);
        _;
    }

    /// @dev Contract Constructor 
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address payable storageAddress, address payable erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }

    /// @dev Function to destroy the contract on the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    /// @dev Generate event to get approval from each participant of the token
    /// @param tokenId Id of token
    function sendRequestForApprovalOfProfitShareRemovalForSecondarySale(uint tokenId) external onlyArtistOf(tokenId) {
        uint256 schemeId = SnarkBaseExtraLib.getTokenProfitShareSchemeId(_storage, tokenId);
        uint256 participantsCount = 
            SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(_storage, schemeId);
        address participant;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) =
                SnarkBaseExtraLib.getParticipantOfProfitShareScheme(_storage, schemeId, i);
            SnarkBaseExtraLib.setTokenToParticipantApproving(_storage, tokenId, participant, false);
            emit NeedApproveProfitShareRemoving(participant, tokenId);
        }
    }

    /// @dev Delete profit share from secondary sale
    /// @param tokenId Token Id
    function approveRemovingProfitShareFromSecondarySale(uint256 tokenId) external onlyParticipantOf(tokenId) {
        SnarkBaseExtraLib.setTokenToParticipantApproving(_storage, tokenId, msg.sender, true);
        uint256 schemeId = SnarkBaseExtraLib.getTokenProfitShareSchemeId(_storage, tokenId);
        uint256 participantsCount = 
            SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(_storage, schemeId);
        address participant;
        bool isApproved = true;
        for (uint256 i = 0; i < participantsCount; i++) {
            (participant,) = 
                SnarkBaseExtraLib.getParticipantOfProfitShareScheme(_storage, schemeId, i);
            isApproved = isApproved && 
                SnarkBaseLib.getTokenToParticipantApproving(_storage, tokenId, participant);
        }
        if (isApproved) SnarkBaseLib.setTokenProfitShareFromSecondarySale(_storage, tokenId, 0);
    }

    function setTokenAcceptOfLoanRequest(uint256 tokenId, bool isAcceptForSnark) public {
        require(
            msg.sender == owner || 
            msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenId)
        );
        SnarkBaseLib.setTokenAcceptOfLoanRequest(_storage, tokenId, isAcceptForSnark);
        if (!isAcceptForSnark) {
            SnarkLoanLib.deleteTokenFromApprovedListForLoan(_storage, tokenId);
            SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, msg.sender, tokenId);
        } else {
            SnarkLoanLib.addTokenToApprovedListForLoan(_storage, tokenId);
            SnarkLoanLib.deleteTokenFromNotApprovedListForLoan(_storage, msg.sender, tokenId);
        }
    }

    function setTokenName(string memory tokenName) public onlyOwner {
        SnarkBaseLib.setTokenName(_storage, tokenName);
    }

    function setTokenSymbol(string memory tokenSymbol) public onlyOwner {
        SnarkBaseLib.setTokenSymbol(_storage, tokenSymbol);
    }

    function changeRestrictAccess(bool isRestrict) public onlyOwner {
        SnarkBaseLib.setRestrictAccess(_storage, isRestrict);
    }

    /// @dev Create a scheme of profit share for user
    /// @param participants List of profit sharing participants
    /// @param percentAmount List of profit share % of participants
    /// @return A scheme id
    function createProfitShareScheme(
        address artistAddress, 
        address[] memory participants, 
        uint256[] memory percentAmount
    )
        public
        restrictedAccess
        returns(uint256)
    {
        require(participants.length == percentAmount.length);
        require(participants.length <= 5);
        uint256 sum = 0;
        for (uint i = 0; i < percentAmount.length; i++) {
            require(percentAmount[i] > 0, "Percent value has to be greater than zero");
            sum = sum.add(percentAmount[i]);
        }
        require(sum == 100, "Sum of all percentages has to be equal 100");
        uint256 schemeId = SnarkBaseExtraLib.addProfitShareScheme(
            _storage, artistAddress, participants, percentAmount);
        emit ProfitShareSchemeAdded(artistAddress, schemeId);
    }

    /// @dev Return a total number of profit share schemes
    function getProfitShareSchemesTotalCount() public view returns (uint256) {
        return SnarkBaseExtraLib.getTotalNumberOfProfitShareSchemes(_storage);
    }

    /// @dev Return a total number of user's profit share schemes
    function getProfitShareSchemeCountByAddress(address schemeOwner) public view onlyOwner returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfProfitShareSchemesForOwner(_storage, schemeOwner);
    }

    /// @dev Return a scheme Id for user by index
    /// @param index Index of scheme for current user's address
    function getProfitShareSchemeIdByIndex(address schemeOwner, uint256 index) public view onlyOwner returns (uint256) {
        return SnarkBaseExtraLib.getProfitShareSchemeIdForOwner(_storage, schemeOwner, index);
    }

    /// @dev Return a list of user profit share schemes
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount(address schemeOwner) public view onlyOwner returns(uint256) {
        return SnarkBaseExtraLib.getNumberOfUniqueParticipantsForOwner(_storage, schemeOwner);
    }

    /// @dev Return a list of unique profit share participants
    function getProfitShareParticipantsList(address schemeOwner) public view onlyOwner returns (address[] memory) {
        return SnarkBaseExtraLib.getListOfUniqueParticipantsForOwner(_storage, schemeOwner);
    }

    function getOwnerOfToken(uint256 tokenId) public view returns (address) {
        return SnarkBaseLib.getOwnerOfToken(_storage, tokenId);
    }

    /// @dev Function to add a new digital token to the blockchain. Only Snark can call this function.
    /// @param artistAddress Address of artist
    /// @param hashOfToken Unique hash of the token
    /// @param tokenUrl IPFS URL to digital work
    /// @param decorationUrl IPFS URL to json decoration file
    /// @param decriptionKey Decription key for digital work
    /// @param limitedEditionProfitSFSSProfitSSID Array of 3 variables: 
    ///         0 - Number of token edititons,
    ///         1 - Profit share % during secondary sale, going back to the artist and their list of participants
    ///         2 - Profit share scheme Id,
    /// @param isAcceptOfLoanRequest sign of auto accept of requests from Snark and other users
    function addToken(
        address artistAddress,
        string memory hashOfToken,
        string memory tokenUrl,
        string memory decorationUrl,
        string memory decriptionKey,
        uint256[] memory limitedEditionProfitSFSSProfitSSID,
        bool isAcceptOfLoanRequest
    ) 
        public
        restrictedAccess
    {
        // check if profitShareSchemeId belongs to artistAddress
        require(SnarkBaseExtraLib.doesProfitShareSchemeIdBelongsToOwner(
            _storage, artistAddress, limitedEditionProfitSFSSProfitSSID[2]) == true,
            "Artist has to have the profit share schemeId");
        // Check for an identical hash of the digital token in existence to prevent uploading a duplicate token
        require(SnarkBaseLib.getTokenHashAsInUse(_storage, hashOfToken) == false, 
            "Token is already exist with the same hash"
        );
        // Check that the number of token editions is >= 1 and <= 10
        // otherwise there is a chance to spend all the Gas
        require(limitedEditionProfitSFSSProfitSSID[0] >= 1 && limitedEditionProfitSFSSProfitSSID[0] <= 25,
            "Limited edition should be less or equal 25"
        );
        require(limitedEditionProfitSFSSProfitSSID[1] <= 100, 
            "Profit Share for secondary sale has to be less or equal 100"
        );
        uint256[] memory lEeNlPpSSIDpSFSS = new uint256[](5);
        for (uint8 i = 0; i < limitedEditionProfitSFSSProfitSSID[0]; i++) {
            lEeNlPpSSIDpSFSS[0] = limitedEditionProfitSFSSProfitSSID[0];    // limitedEdition
            lEeNlPpSSIDpSFSS[1] = i + 1;                                    // editionNumber
            lEeNlPpSSIDpSFSS[2] = 0;                                        // lastPrice
            lEeNlPpSSIDpSFSS[3] = limitedEditionProfitSFSSProfitSSID[2];    // profitShareSchemeId
            lEeNlPpSSIDpSFSS[4] = limitedEditionProfitSFSSProfitSSID[1];    // profitShareForSecondarySale

            uint256 tokenId = SnarkBaseLib.addToken(
                _storage,
                artistAddress,                                              // artistAddress
                hashOfToken,                                                // tokenHash
                lEeNlPpSSIDpSFSS,
                tokenUrl,                                                   // tokenUrl
                isAcceptOfLoanRequest
            );
            if (isAcceptOfLoanRequest)
                SnarkLoanLib.addTokenToApprovedListForLoan(_storage, tokenId);
            else 
                SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, artistAddress, tokenId);
            SnarkBaseLib.setTokenHashAsInUse(_storage, hashOfToken, true);
            SnarkBaseLib.addTokenToArtistList(_storage, tokenId, artistAddress);
            SnarkBaseLib.setTokenDecryptionKey(_storage, tokenId, decriptionKey);
            SnarkBaseLib.setDecorationUrl(_storage, tokenId, decorationUrl);
            SnarkBaseLib.setOwnerOfToken(_storage, tokenId, artistAddress);
            SnarkBaseLib.addTokenToOwner(_storage, artistAddress, tokenId);
            emit TokenCreated(artistAddress, hashOfToken, tokenId);
            SnarkERC721(_erc721).echoTransfer(address(0), artistAddress, tokenId);
        }
    }

    function getTokenDecryptionKey(uint256 tokenId) public view returns (string memory) {
        require(
            msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenId) ||
            msg.sender == owner
        );
        return SnarkBaseLib.getTokenDecryptionKey(_storage, tokenId);
    }

    function getTokensCount() public view returns (uint256) {
        return SnarkBaseLib.getTotalNumberOfTokens(_storage);
    }

    function getTokensCountByArtist(address artist) public view returns (uint256) {
        return SnarkBaseLib.getNumberOfArtistTokens(_storage, artist);
    }

    function getTokenListForArtist(address artist) public view returns (uint256[] memory) {
        uint256 _count = SnarkBaseLib.getNumberOfArtistTokens(_storage, artist);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = SnarkBaseLib.getTokenIdForArtist(_storage, artist, i);
        }
        return _retarray;
    }

    function getTokensCountByOwner(address tokenOwner) public view returns (uint256) {
        return SnarkBaseLib.getOwnedTokensCount(_storage, tokenOwner);
    }

    function getTokenListForOwner(address tokenOwner) public view returns (uint256[] memory) {
        uint256 _count = SnarkBaseLib.getOwnedTokensCount(_storage, tokenOwner);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = SnarkBaseLib.getTokenIdOfOwner(_storage, tokenOwner, i);
        }
        return _retarray;
    }

    function isTokenAcceptOfLoanRequest(uint256 tokenId) public view returns (bool) {
        return SnarkBaseLib.isTokenAcceptOfLoanRequest(_storage, tokenId);
    }

    // /// @dev Return details about token
    // /// @param tokenId Token Id of digital work
    function getTokenDetail(uint256 tokenId) 
        public 
        view 
        returns (
            address currentOwner,
            address artist,
            string memory hashOfToken, 
            uint256 limitedEdition, 
            uint256 editionNumber, 
            uint256 lastPrice,
            uint256 profitShareSchemeId,
            uint256 profitShareFromSecondarySale, 
            string memory tokenUrl,
            string memory decorationUrl,
            bool isAcceptOfLoanRequest
        ) 
    {
        return SnarkBaseLib.getTokenDetail(_storage, tokenId);
    }

    /// @dev Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
    /// @param tokenId Token to which a change in profit sharing will be applied.
    /// @param newProfitShareSchemeId Id of profit share scheme
    function changeProfitShareSchemeForToken(
        uint256 tokenId,
        uint256 newProfitShareSchemeId
    ) 
        public
        onlyProfitShareSchemeOfOwner(tokenId, newProfitShareSchemeId)
    {
        SnarkBaseLib.setTokenProfitShareSchemeId(_storage, tokenId, newProfitShareSchemeId);
    }
    
    /// @dev Function to view the balance in our contract that an owner can withdraw 
    function getWithdrawBalance(address tokenOwner) public view returns (uint256) {
        return SnarkBaseLib.getPendingWithdrawals(_storage, tokenOwner);
    }

    /// @dev Return number of particpants
    function getNumberOfParticipantsForProfitShareScheme(uint256 schemeId) public view returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(_storage, schemeId);
    }

    /// @dev Function returns a participant address and its profit
    /// @param schemeId Id of Profit Share Scheme
    /// @param index index of element in array of ProfitShareSchemes
    function getParticipantOfProfitShareScheme(uint256 schemeId, uint256 index) 
        public 
        view 
        returns (address, uint256) 
    {
        return SnarkBaseExtraLib.getParticipantOfProfitShareScheme(_storage, schemeId, index);
    }

    /// @dev Function to withdraw funds to the owners wallet 
    function withdrawFunds() public {
        uint256 balance = SnarkBaseLib.getPendingWithdrawals(_storage, msg.sender);
        require(balance > 0);
        SnarkBaseLib.subPendingWithdrawals(_storage, msg.sender, balance);
        SnarkStorage(_storage).transferFunds(msg.sender, balance);
    }

    function setSnarkWalletAddress(address snarkWalletAddr) public onlyOwner {
        SnarkBaseLib.setSnarkWalletAddress(_storage, snarkWalletAddr);
    }

    function setPlatformProfitShare(uint256 profit) public onlyOwner {
        SnarkBaseLib.setPlatformProfitShare(_storage, profit);
    }

    function changeTokenData(
        uint256 tokenId,
        string memory hashOfToken,
        string memory tokenUrl,
        string memory decorationUrl,
        string memory decriptionKey
    ) 
        public 
        onlyOwner 
    {
        SnarkStorage(_storage).setString(
            keccak256(abi.encodePacked("token", "hashOfToken", tokenId)), hashOfToken);
        SnarkStorage(_storage).setString(
            keccak256(abi.encodePacked("token", "url", tokenId)), tokenUrl);

        SnarkBaseLib.setDecorationUrl(_storage, tokenId, decorationUrl);
        SnarkBaseLib.setTokenDecryptionKey(_storage, tokenId, decriptionKey);
    }

    function getSnarkWalletAddressAndProfit() public view returns (address snarkWalletAddr, uint256 platformProfit) {
        snarkWalletAddr = SnarkBaseLib.getSnarkWalletAddress(_storage);
        platformProfit = SnarkBaseLib.getPlatformProfitShare(_storage);
    }

    function getPlatformProfitShare() public view returns (uint256) {
        return SnarkBaseLib.getPlatformProfitShare(_storage);
    }

    function getSaleTypeToToken(uint256 tokenId) public view returns (uint256) {
        return SnarkBaseLib.getSaleTypeToToken(_storage, tokenId);
    }

    function getTokenHashAsInUse(string memory tokenHash) public view returns (bool) {
        return SnarkBaseLib.getTokenHashAsInUse(_storage, tokenHash);
    }

    function getNumberOfProfitShareSchemesForOwner(address schemeOwner) public view returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfProfitShareSchemesForOwner(_storage, schemeOwner);
    }

    function getProfitShareSchemeIdForOwner(address schemeOwner, uint256 index)
        public
        view
        returns (uint256)
    {
        return SnarkBaseExtraLib.getProfitShareSchemeIdForOwner(_storage, schemeOwner, index);
    }

    function getListOfAllArtists() public view returns (address[] memory) {
        return SnarkBaseLib.getListOfAllArtists(_storage);
    }

    function setLinkDropPrice(uint256 tokenId, uint256 price) public onlyOwner {
        SnarkBaseLib.setTokenLastPrice(_storage, tokenId, price);
    }

    function toGiftToken(uint256 tokenId, address to) public onlyOwnerOf(tokenId) {
        require(to != address(0), "Receiver's  address can't be equal zero");
        SnarkCommonLib.transferToken(_storage, tokenId, msg.sender, to);
        SnarkERC721(_erc721).echoTransfer(msg.sender, to, tokenId);
    }    
}
