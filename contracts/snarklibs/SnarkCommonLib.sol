pragma solidity >=0.5.0;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseExtraLib.sol";
import "./SnarkBaseLib.sol";
import "../SnarkERC721.sol";


library SnarkCommonLib {
    using SafeMath for uint256;
    using SnarkBaseExtraLib for address;
    using SnarkBaseLib for address;

    function transferToken(address payable _storageAddress, uint256 _tokenId, address _from, address _to) internal {
        require(
            _tokenId > 0 && _tokenId <= SnarkBaseLib.getTotalNumberOfTokens(_storageAddress), 
            "Token Id is wrong"
        );
        require(
            _from == SnarkBaseLib.getOwnerOfToken(_storageAddress, _tokenId), 
            "You try to transfer token from wrong owner address."
        );
        uint256 _index = SnarkBaseLib.getIndexOfOwnerToken(_storageAddress, _from, _tokenId);
        SnarkBaseLib.deleteTokenFromOwner(_storageAddress, _from, _index);
        SnarkBaseLib.setOwnerOfToken(_storageAddress, _tokenId, _to);
        SnarkBaseLib.addTokenToOwner(_storageAddress, _to, _tokenId);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function takePlatformProfitShare(address payable _storageAddress, uint256 _profit) internal {
        address snarkWallet = SnarkBaseLib.getSnarkWalletAddress(_storageAddress);
        SnarkStorage(_storageAddress).transferFunds(address(uint160(snarkWallet)), _profit);
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which token is sold
    /// @param _tokenId Token token ID
    /// @param _from Seller Address
    function incomeDistribution(address payable _storageAddress, uint256 _price, uint256 _tokenId, address _from) 
        internal 
    {
        uint256 lastPrice = SnarkBaseLib.getTokenLastPrice(_storageAddress, _tokenId);
        uint256 profitShareSchemaId = SnarkBaseExtraLib.getTokenProfitShareSchemeId(_storageAddress, _tokenId);
        uint256 profitShareFromSecondarySale = SnarkBaseLib.getTokenProfitShareFromSecondarySale(
            _storageAddress, _tokenId);
        uint256 profit = (_price > lastPrice) ? _price.sub(lastPrice) : 0;
        if (profit >= 100) {
            if (lastPrice > 0) {
                uint256 countToSeller = _price;
                profit = profit.mul(profitShareFromSecondarySale).div(100);
                countToSeller = countToSeller.sub(profit);
                SnarkStorage(_storageAddress).transferFunds(address(uint160(_from)), countToSeller);
            }
            uint256 residue = profit;
            uint256 participantsCount = 
                SnarkBaseExtraLib.getNumberOfParticipantsForProfitShareScheme(
                    address(uint160(_storageAddress)), profitShareSchemaId);
            address currentParticipant;
            uint256 participantProfit;
            for (uint256 i = 0; i < participantsCount; i++) {
                (currentParticipant, participantProfit) = 
                    SnarkBaseExtraLib.getParticipantOfProfitShareScheme(
                        _storageAddress, profitShareSchemaId, i);
                uint256 payout = profit.mul(participantProfit).div(100);
                SnarkStorage(_storageAddress).transferFunds(address(uint160(currentParticipant)), payout);
                residue = residue.sub(payout);
            }
            lastPrice = residue;
        } else {
            lastPrice = _price;
        }
        SnarkStorage(_storageAddress).transferFunds(address(uint160(_from)), lastPrice);
    }

    function calculatePlatformProfitShare(address payable _storageAddress, uint256 _income) 
        internal 
        view 
        returns (uint256 profit, uint256 residue) 
    {
        uint256 platformProfit = SnarkBaseLib.getPlatformProfitShare(_storageAddress);
        profit = _income.mul(platformProfit).div(100);
        residue = _income.sub(profit);
    }

    /// @dev Function of an token buying
    /// @param _storageAddress Address of storage
    /// @param _tokenId Token ID
    /// @param _value Selling price of token
    /// @param _from Address of seller
    /// @param _to Address of buyer
    function buy(
        address payable _storageAddress, 
        uint256 _tokenId, 
        uint256 _value,
        address _from, 
        address _to
    )
        internal 
    {
        uint256 profit;
        uint256 price;
        (profit, price) = calculatePlatformProfitShare(_storageAddress, _value);
        takePlatformProfitShare(_storageAddress, profit);
        incomeDistribution(_storageAddress, price, _tokenId, _from);
        SnarkBaseLib.setTokenLastPrice(_storageAddress, _tokenId, _value);
        SnarkBaseLib.setSaleTypeToToken(_storageAddress, _tokenId, 0);
        transferToken(_storageAddress, _tokenId, _from, _to);
    }

    function echoTransfer(address payable _erc721Address, address _from, address _to, uint256 _tokenId) internal {
        SnarkERC721(_erc721Address).echoTransfer(_from, _to, _tokenId);
    }
    
}