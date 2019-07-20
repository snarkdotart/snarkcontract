pragma solidity >=0.5.0;

import "./openzeppelin/Ownable.sol";
import "./openzeppelin/SafeMath.sol";
import "./snarklibs/SnarkBaseExtraLib.sol";
import "./snarklibs/SnarkBaseLib.sol";
import "./snarklibs/SnarkCommonLib.sol";
import "./snarklibs/SnarkLoanLib.sol";


/// @title Base contract for Snark. Holds all common structs, events and base variables.
/// @author Vitali Hurski
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

    /// @notice TokenCreatedEvent is executed when a new token is created.
    event TokenCreated(address indexed tokenOwner, string hashOfToken, uint256 tokenId);
    /// @notice Event occurs when profit share scheme is created.
    event ProfitShareSchemeAdded(address indexed schemeOwner, uint256 profitShareSchemeId);
    /// @notice Event occurs when an artist wants to remove the profit share for secondary sale
    event NeedApproveProfitShareRemoving(address indexed participant, uint256 tokenId);
    
    /// @notice Snark's contracts and wallets only can call functions marked 
    /// this modifier if restricted access were set up by Snark.
    modifier restrictedAccess() {
        if (SnarkBaseLib.isRestrictedAccess(_storage)) {
            require(msg.sender == owner, "only Snark can perform the function");
        }
        _;
    }

    /// @notice Modifier that checks that an owner has a specific token
    /// @param tokenId Token ID
    modifier onlyOwnerOf(uint256 tokenId) {
        require(msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenId));
        _;
    }

    /// @notice Modifier that checks that an owner possesses multiple tokens
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
    
    /// @notice Modifier that only allows the artist to do an operation
    /// @param tokenId Token Id
    modifier onlyArtistOf(uint256 tokenId) {
        address artist = SnarkBaseLib.getTokenArtist(_storage, tokenId);
        require(msg.sender == artist);
        _;
    }

    /// @notice Modifier allows access to functions to the owner of a profit share scheme only
    /// @param tokenId Id of token
    /// @param schemeId Id of profit share scheme
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

    /// @notice Modifier that allows access for a participant only
    /// @param tokenId Id of token
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

    /// @notice Contract constructor 
    /// @param storageAddress Address of a storage contract
    /// @param erc721Address Address of a ERC721 contract
    constructor(address payable storageAddress, address payable erc721Address) public {
        _storage = storageAddress;
        _erc721 = erc721Address;
    }

    /// @notice Function to destroy the contract on the blockchain
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    /// @notice Generate event to get approval from each participant of the token
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

    /// @notice Delete profit share from secondary sale
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

    /// @notice Allows user to approve participate particular token in loans or exclude it's participating
    /// @param tokenId Id of token
    /// @param isAcceptForSnark Contains "true" if the user allows participating the token in loans, 
    /// otherwise it has to be "false"
    function setTokenAcceptOfLoanRequest(uint256 tokenId, bool isAcceptForSnark) public {
        address tokenOwner = SnarkBaseLib.getOwnerOfToken(_storage, tokenId);
        require(msg.sender == owner || msg.sender == tokenOwner);
        SnarkBaseLib.setTokenAcceptOfLoanRequest(_storage, tokenId, isAcceptForSnark);
        if (!isAcceptForSnark) {
            SnarkLoanLib.deleteTokenFromApprovedListForLoan(_storage, tokenId);
            SnarkLoanLib.addTokenToNotApprovedListForLoan(_storage, tokenOwner, tokenId);
        } else {
            SnarkLoanLib.addTokenToApprovedListForLoan(_storage, tokenId);
            SnarkLoanLib.deleteTokenFromNotApprovedListForLoan(_storage, tokenOwner, tokenId);
        }
    }

    /// @notice Allows to change the name of tokens for the entire project
    /// @param tokenName New name of tokens
    function setTokenName(string memory tokenName) public onlyOwner {
        SnarkBaseLib.setTokenName(_storage, tokenName);
    }

    /// @notice Allows to change the symbol of tokens for the entire project
    /// @param tokenSymbol New symbol of tokens
    function setTokenSymbol(string memory tokenSymbol) public onlyOwner {
        SnarkBaseLib.setTokenSymbol(_storage, tokenSymbol);
    }

    /// @notice Allows to contract's owner to set a restriction to performing functions
    /// @param isRestrict "True" if the Snark wants to set up a restriction, otherwise - "false"
    function changeRestrictAccess(bool isRestrict) public onlyOwner {
        SnarkBaseLib.setRestrictAccess(_storage, isRestrict);
    }

    /// @notice Create a scheme of profit share for user
    /// @param artistAddress Address of artist
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

    /// @notice Return a total number of profit share schemes
    /// @return Total number of schemes
    function getProfitShareSchemesTotalCount() public view returns (uint256) {
        return SnarkBaseExtraLib.getTotalNumberOfProfitShareSchemes(_storage);
    }

    /// @notice Return a total number of user's profit share schemes
    /// @param schemeOwner Owner of scheme
    /// @return Total number
    function getProfitShareSchemeCountByAddress(address schemeOwner) public view onlyOwner returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfProfitShareSchemesForOwner(_storage, schemeOwner);
    }

    /// @notice Return a scheme Id for user by index
    /// @param schemeOwner Owner of scheme
    /// @param index Index of scheme for current user's address
    /// @return Id of scheme
    function getProfitShareSchemeIdByIndex(address schemeOwner, uint256 index) public view onlyOwner returns (uint256) {
        return SnarkBaseExtraLib.getProfitShareSchemeIdForOwner(_storage, schemeOwner, index);
    }

    /// @notice Return a list of user profit share schemes
    /// @param schemeOwner Owner of scheme
    /// @return A list of schemes belongs to owner
    function getProfitShareParticipantsCount(address schemeOwner) public view onlyOwner returns(uint256) {
        return SnarkBaseExtraLib.getNumberOfUniqueParticipantsForOwner(_storage, schemeOwner);
    }

    /// @notice Return a list of unique profit share participants
    /// @param schemeOwner Owner of scheme
    /// @return An array of users schemas Ids
    function getProfitShareParticipantsList(address schemeOwner) public view onlyOwner returns (address[] memory) {
        return SnarkBaseExtraLib.getListOfUniqueParticipantsForOwner(_storage, schemeOwner);
    }

    /// @notice Function to add a new digital token to the blockchain. Only Snark can call this function.
    /// @param artistAddress Address of artist
    /// @param hashOfToken Unique hash of the token
    /// @param tokenUrl IPFS URL to digital work
    /// @param decorationUrl IPFS URL to json decoration file
    /// @param decriptionKey Decription key for digital work
    /// @param limitedEditionProfitSFSSProfitSSID Array of 3 variables: 
    ///         0 - Number of token edititons,
    ///         1 - Profit share % during secondary sale, going back to the artist and their list of participants
    ///         2 - Profit share scheme Id,
    /// @param isAcceptOfLoanRequest Sign of auto accept of requests from Snark and other users
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

    /// @notice Returns a decryption key for token's original file
    /// @param tokenId Id of token
    /// @return Decryption key
    function getTokenDecryptionKey(uint256 tokenId) public view returns (string memory) {
        require(
            msg.sender == SnarkBaseLib.getOwnerOfToken(_storage, tokenId) ||
            msg.sender == owner
        );
        return SnarkBaseLib.getTokenDecryptionKey(_storage, tokenId);
    }

    /// @notice Returns a number of tokens which belong to the artist
    /// @param artist Address of the artist
    /// @return Number of tokens
    function getTokensCountByArtist(address artist) public view returns (uint256) {
        return SnarkBaseLib.getNumberOfArtistTokens(_storage, artist);
    }

    /// @notice Returns a list of tokens which belong to the artist
    /// @param artist Address of the artist
    /// @return Array of tokens
    function getTokenListForArtist(address artist) public view returns (uint256[] memory) {
        uint256 _count = SnarkBaseLib.getNumberOfArtistTokens(_storage, artist);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = SnarkBaseLib.getTokenIdForArtist(_storage, artist, i);
        }
        return _retarray;
    }

    /// @notice Returns a list of tokens which belong to the particular address
    /// @param tokenOwner Address of user's wallet
    /// @return Array of tokens
    function getTokenListForOwner(address tokenOwner) public view returns (uint256[] memory) {
        uint256 _count = SnarkBaseLib.getOwnedTokensCount(_storage, tokenOwner);
        uint256[] memory _retarray = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _retarray[i] = SnarkBaseLib.getTokenIdOfOwner(_storage, tokenOwner, i);
        }
        return _retarray;
    }

    /// @notice Allows to check if the token participates in loans
    /// @param tokenId Id of token
    /// @return "True" if the user approved the token for participating in future loans, otherwise "False"
    function isTokenAcceptOfLoanRequest(uint256 tokenId) public view returns (bool) {
        return SnarkBaseLib.isTokenAcceptOfLoanRequest(_storage, tokenId);
    }

    /// @notice Return details about token
    /// @param tokenId Token Id of digital work
    /// @return Address of token's owner
    /// @return Address of the token's artist
    /// @return Hash of original file
    /// @return Amount of token's editions
    /// @return Edition number
    /// @return The last price of token's sale
    /// @return Id of profit share scheme
    /// @return Profit share in case secondary sale
    /// @return URL to original file
    /// @return URL to json file which contains decoration data
    /// @return Boolean value shows if token participating in loans
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

    /// @notice Change in profit sharing. Change can only be to the percentages for already registered wallet addresses.
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
    
    /// @notice Function to view the balance in our contract that an owner can withdraw 
    /// @param tokenOwner Address of token owner
    /// @return Balance in Wei
    function getWithdrawBalance(address tokenOwner) public view returns (uint256) {
        return SnarkBaseLib.getPendingWithdrawals(_storage, tokenOwner);
    }

    /// @notice Return number of particpants
    /// @param schemeId Id of profit share scheme
    /// @return Number of participants
    function getNumberOfParticipantsForProfitShareScheme(uint256 schemeId) public view returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(_storage, schemeId);
    }

    /// @notice Function returns a participant address and its profit
    /// @param schemeId Id of Profit Share Scheme
    /// @param index index of element in array of ProfitShareSchemes
    /// @return Address of participant and 
    /// @return Participant's profit in percentage
    function getParticipantOfProfitShareScheme(uint256 schemeId, uint256 index) 
        public 
        view 
        returns (address, uint256) 
    {
        return SnarkBaseExtraLib.getParticipantOfProfitShareScheme(_storage, schemeId, index);
    }

    /// @notice Function to withdraw funds to the owners wallet 
    function withdrawFunds() public {
        uint256 balance = SnarkBaseLib.getPendingWithdrawals(_storage, msg.sender);
        require(balance > 0);
        SnarkBaseLib.subPendingWithdrawals(_storage, msg.sender, balance);
        SnarkStorage(_storage).transferFunds(msg.sender, balance);
    }

    /// @notice Allows to set up a new wallet of Snark
    /// @param snarkWalletAddr New address of wallet
    function setSnarkWalletAddress(address snarkWalletAddr) public onlyOwner {
        SnarkBaseLib.setSnarkWalletAddress(_storage, snarkWalletAddr);
    }

    /// @notice Allows to set up a new value of Snark's profit share in percentage
    /// @param profit New profit share
    function setPlatformProfitShare(uint256 profit) public onlyOwner {
        SnarkBaseLib.setPlatformProfitShare(_storage, profit);
    }

    /// @notice Allows to update the token data
    /// @param tokenId Id of token
    /// @param hashOfToken New hash of original file
    /// @param tokenUrl New URL to original file of token
    /// @param decorationUrl New URL to JSON file which contains a decoration data
    /// @param decriptionKey New key to decrypt the original file of token
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

    /// @notice Allows to get Snark's data
    /// @return Snark's wallet
    /// @return Snark's profit share in percentage
    function getSnarkWalletAddressAndProfit() public view returns (address snarkWalletAddr, uint256 platformProfit) {
        snarkWalletAddr = SnarkBaseLib.getSnarkWalletAddress(_storage);
        platformProfit = SnarkBaseLib.getPlatformProfitShare(_storage);
    }

    /// @notice Allows to get profit share of Snark
    /// @return Profit share in percentage
    function getPlatformProfitShare() public view returns (uint256) {
        return SnarkBaseLib.getPlatformProfitShare(_storage);
    }

    /// @notice Allows to check if the hash of token already saved
    /// @param tokenHash Hash of token
    /// @return "True" if the hash already saved, otherwise "False"
    function getTokenHashAsInUse(string memory tokenHash) public view returns (bool) {
        return SnarkBaseLib.getTokenHashAsInUse(_storage, tokenHash);
    }

    /// @notice Returns amount of profit share schemes
    /// @param schemeOwner Address of scheme owner
    /// @return Number of profit share schemes
    function getNumberOfProfitShareSchemesForOwner(address schemeOwner) public view returns (uint256) {
        return SnarkBaseExtraLib.getNumberOfProfitShareSchemesForOwner(_storage, schemeOwner);
    }

    /// @notice Allows to get a profit share scheme id by index for owner
    /// @param schemeOwner Address of profit share scheme owner
    /// @param index Index of profits in array
    /// @return Id of profit share scheme
    function getProfitShareSchemeIdForOwner(address schemeOwner, uint256 index)
        public
        view
        returns (uint256)
    {
        return SnarkBaseExtraLib.getProfitShareSchemeIdForOwner(_storage, schemeOwner, index);
    }

    /// @notice Retrieves a list of artists addresses
    /// @return Array of artists addresses
    function getListOfAllArtists() public view returns (address[] memory) {
        return SnarkBaseLib.getListOfAllArtists(_storage);
    }

    /// @notice Let to set up the price when the token sales by means "deeplink"
    /// @param tokenId Id of token
    /// @param price Price of selling by means "deeplink"
    function setLinkDropPrice(uint256 tokenId, uint256 price) public onlyOwner {
        SnarkBaseLib.setTokenLastPrice(_storage, tokenId, price);
    }

}
