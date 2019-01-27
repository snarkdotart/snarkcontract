pragma solidity ^0.4.25;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";
import "./SnarkBaseExtraLib.sol";
import "../SnarkERC721.sol";


library SnarkCommonLib {
    using SafeMath for uint256;
    using SnarkBaseLib for address;
    using SnarkBaseExtraLib for address;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    function transferToken(address _storageAddress, uint256 _tokenId, address _from, address _to) internal {
        require(_tokenId > 0 && _tokenId <= _storageAddress.getTotalNumberOfTokens(), "Token Id is wrong");
        require(
            _from == _storageAddress.getOwnerOfToken(_tokenId), 
            "You try to transfer token from wrong owner address."
        );
        uint256 _index = _storageAddress.getIndexOfOwnerToken(_from, _tokenId);
        _storageAddress.deleteTokenFromOwner(_from, _index);
        _storageAddress.setOwnerOfToken(_tokenId, _to);
        _storageAddress.addTokenToOwner(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function takePlatformProfitShare(address _storageAddress, uint256 _profit) internal {
        address snarkWallet = _storageAddress.getSnarkWalletAddress();
        // _storageAddress.addPendingWithdrawals(snarkWallet, _profit);
        SnarkStorage(_storageAddress).transferFunds(snarkWallet, _profit);
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which token is sold
    /// @param _tokenId Token token ID
    /// @param _from Seller Address
    function incomeDistribution(address _storageAddress, uint256 _price, uint256 _tokenId, address _from) internal {
        uint256 lastPrice = _storageAddress.getTokenLastPrice(_tokenId);
        uint256 profitShareSchemaId = _storageAddress.getTokenProfitShareSchemeId(_tokenId);
        uint256 profitShareFromSecondarySale = _storageAddress.getTokenProfitShareFromSecondarySale(_tokenId);
        uint256 profit = 0;
        if (_price > lastPrice) profit = _price.sub(lastPrice);
        if (profit >= 100) {
            if (lastPrice > 0) {
                uint256 countToSeller = _price;
                profit = profit.mul(profitShareFromSecondarySale).div(100);
                countToSeller = countToSeller.sub(profit);
                // _storageAddress.addPendingWithdrawals(_from, countToSeller);
                SnarkStorage(_storageAddress).transferFunds(_from, countToSeller);
            }
            uint256 residue = profit;
            uint256 participantsCount = 
                _storageAddress.getNumberOfParticipantsForProfitShareScheme(profitShareSchemaId);
            address currentParticipant;
            uint256 participantProfit;
            for (uint256 i = 0; i < participantsCount; i++) {
                (currentParticipant, participantProfit) = 
                    _storageAddress.getParticipantOfProfitShareScheme(profitShareSchemaId, i);
                uint256 payout = profit.mul(participantProfit).div(100);
                // _storageAddress.addPendingWithdrawals(currentParticipant, payout);
                SnarkStorage(_storageAddress).transferFunds(currentParticipant, payout);
                residue = residue.sub(payout);
            }
            lastPrice = residue;
        } else {
            lastPrice = _price;
        }
        // _storageAddress.addPendingWithdrawals(_from, lastPrice);
        SnarkStorage(_storageAddress).transferFunds(_from, lastPrice);
    }

    function calculatePlatformProfitShare(address _storageAddress, uint256 _income) 
        internal 
        view 
        returns (uint256 profit, uint256 residue) 
    {
        uint256 platformProfit = _storageAddress.getPlatformProfitShare();
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
        address _storageAddress, 
        uint256 _tokenId, 
        uint256 _value,
        address _from, 
        address _to
    )
        internal 
    {
        incomeDistribution(_storageAddress, _value, _tokenId, _from);
        _storageAddress.setTokenLastPrice(_tokenId, _value);
        _storageAddress.setSaleTypeToToken(_tokenId, 0);
        transferToken(_storageAddress, _tokenId, _from, _to);
    }

    function echoTransfer(address _erc721Address, address _from, address _to, uint256 _tokenId) internal {
        SnarkERC721(_erc721Address).echoTransfer(_from, _to, _tokenId);
    }
    
}