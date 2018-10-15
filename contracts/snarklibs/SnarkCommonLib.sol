pragma solidity ^0.4.24;

import "../openzeppelin/SafeMath.sol";
import "../SnarkStorage.sol";
import "./SnarkBaseLib.sol";


library SnarkCommonLib {
    using SafeMath for uint256;
    using SnarkBaseLib for address;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function transferToken(address _storageAddress, uint256 _tokenId, address _from, address _to) internal {
        if (_tokenId <= SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfTokens")) &&
            _from == SnarkStorage(_storageAddress).addressStorage(
                keccak256(abi.encodePacked("ownerOfToken", _tokenId)))
        ) {
            uint256 numberOfTokens = _storageAddress.getOwnedTokensCount(_from);
            for (uint256 i = 0; i < numberOfTokens; i++) {
                if (_tokenId == _storageAddress.getTokenIdOfOwner(_from, i)) {
                    uint256 _index = i;
                    break;
                }
            }
            _storageAddress.deleteTokenFromOwner(_from, _index);
            _storageAddress.setOwnerOfToken(_tokenId, _to);
            _storageAddress.addTokenToOwner(_to, _tokenId);
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function takePlatformProfitShare(address _storageAddress, uint256 _profit) internal {
        address snarkWallet = _storageAddress.getSnarkWalletAddress();
        _storageAddress.addPendingWithdrawals(snarkWallet, _profit);
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which token is sold
    /// @param _tokenId Token token ID
    /// @param _from Seller Address
    function incomeDistribution(address _storageAddress, uint256 _price, uint256 _tokenId, address _from) internal {
        uint256 lastPrice = _storageAddress.getTokenLastPrice(_tokenId);
        uint256 profitShareSchemaId = _storageAddress.getTokenProfitShareSchemeId(_tokenId);
        uint256 profitShareFromSecondarySale = _storageAddress.getTokenProfitShareFromSecondarySale(_tokenId);
        uint256 profit = _price - lastPrice;
        if (profit >= 100) {
            if (lastPrice > 0) {
                uint256 countToSeller = _price;
                profit = profit.mul(profitShareFromSecondarySale).div(100);
                countToSeller = countToSeller.sub(profit);
                _storageAddress.addPendingWithdrawals(_from, countToSeller);
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
                _storageAddress.addPendingWithdrawals(currentParticipant, payout);
                residue = residue.sub(payout);
            }
            lastPrice = residue;
        } else {
            lastPrice = _price;
        }
        _storageAddress.addPendingWithdrawals(_from, lastPrice);
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
    /// @param _mediator Address of token's temporary keeper (Snark)
    function buy(
        address _storageAddress, 
        uint256 _tokenId, 
        uint256 _value,
        address _from, 
        address _to, 
        address _mediator
    )
        internal 
    {
        incomeDistribution(_storageAddress, _value, _tokenId, _from);
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("token", "lastPrice", _tokenId)), _value);
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("saleTypeToToken", _tokenId)), 0);
        transferToken(_storageAddress, _tokenId, _mediator, _to);
    }
}