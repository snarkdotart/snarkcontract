pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkDefinitions.sol";
import "./SnarkBaseLib.sol";
import "./SnarkCommonLib.sol";


contract CommonFunc is Ownable, SnarkDefinitions {

    using SafeMath for uint256;
    using SnarkBaseLib for address;
    using SnarkCommonLib for address;

    address private _storage;

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which artwork is sold
    /// @param _tokenId Artwork token ID
    /// @param _from Seller Address
    function _incomeDistribution(uint256 _price, uint256 _tokenId, address _from) internal { 
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        // distribute the profit according to the schedule contained in the artwork token
        uint256 lastPrice = _storage.getArtworkLastPrice(_tokenId);
        uint256 profitShareSchemaId = _storage.getArtworkProfitShareSchemeId(_tokenId);
        uint256 profitShareFromSecondarySale = _storage.getArtworkProfitShareFromSecondarySale(_tokenId);
        // calculate profit
        // in primary sale the lastPrice should be 0 while in a secondary it should be a prior sale price
        if (lastPrice < _price && (_price - lastPrice) >= 100) {
            uint256 profit = _price - lastPrice;
            if (lastPrice > 0) {
                // if it is a secondary sale, reduce the profit by the profit sharing % specified by the artist 
                // the remaining count goes back to the seller
                uint256 countToSeller = _price;
                // the count to be distributed
                profit = profit * profitShareFromSecondarySale / 100;
                // the count that will go to the seller
                countToSeller -= profit;
                _storage.addPendingWithdrawals(_from, countToSeller);
            }
            uint256 residue = profit; 
            uint256 participantsCount = _storage.getNumberOfParticipantsForProfitShareScheme(profitShareSchemaId);
            address currentParticipant;
            uint256 participantProfit;
            for (uint256 i = 0; i < participantsCount; i++) { 
                (currentParticipant, participantProfit) = 
                    _storage.getParticipantOfProfitShareScheme(profitShareSchemaId, i);
                // calculate the payout count
                uint256 payout = profit * participantProfit / 100;
                // move the payout count to each participant
                _storage.addPendingWithdrawals(currentParticipant, payout);
                residue -= payout; // recalculate the uncollected count after the payout
            }
            // if there is any uncollected counts after distribution, move the count to the seller
            lastPrice = residue;
        } else {
            // if there is no profit, then all goes back to the seller
            lastPrice = _price;
        }
        _storage.addPendingWithdrawals(_from, lastPrice);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function _takePlatformProfitShare(uint256 _profit) internal {
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        address snarkWallet = _storage.getSnarkWalletAddress();
        _storage.addPendingWithdrawals(snarkWallet, _profit);
    }

    function _calculatePlatformProfitShare(uint256 _income) internal view returns (uint256 profit, uint256 residue) {
        /* !!!!!!!!!!! set to internal after test !!!!!!!!!!! */
        profit = (_income * _storage.getPlatformProfitShare() / 100);
        residue = (_income - profit);
    }

    /// @dev Function of an artwork buying
    /// @param _tokenId Artwork ID
    /// @param _value Selling price of artwork
    /// @param _from Address of seller
    /// @param _to Address of buyer
    /// @param _mediator Address of token's temporary keeper (Snark)
    function _buy(uint256 _tokenId, uint256 _value, address _from, address _to, address _mediator) internal {
        _storage.incomeDistribution(_value, _tokenId, _from);
        // mark the price for which the artwork sold
        _storage.setArtworkLastPrice(_tokenId, _value);
        // mark the sale type to None after sale
        _storage.setSaleTypeToArtwork(_tokenId, uint256(SaleType.None));
        transfer(_mediator, _to, _tokenId);
    }

}