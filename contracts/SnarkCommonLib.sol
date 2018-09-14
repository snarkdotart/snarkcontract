pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./SnarkStorage.sol";


library SnarkCommonLib {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function transferArtwork(address _storageAddress, uint256 _artworkId, address _from, address _to) internal {
        if (_artworkId <= SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfArtworks")) &&
            _from == SnarkStorage(_storageAddress).addressStorage(
                keccak256(abi.encodePacked("ownerOfArtwork", _artworkId)))
        ) {
            uint256 numberOfArtworks = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _from)));
            for (uint256 i = 0; i < numberOfArtworks; i++) {
                if (_artworkId == SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, i))
                )) {
                    uint256 _index = i;
                    break;
                }
            }
            uint256 maxIndex = numberOfArtworks.sub(1);
            if (maxIndex != _index) {
                uint256 artworkId = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, maxIndex)));
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("artworkOfOwner", _from, _index)), 
                    artworkId);
            }
            SnarkStorage(_storageAddress).deleteUint(
                keccak256(abi.encodePacked("artworkOfOwner", _from, maxIndex)));
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _from)),
                maxIndex);
            SnarkStorage(_storageAddress).setAddress(
                keccak256(abi.encodePacked("ownerOfArtwork", _artworkId)),
                _to);
            _index = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _to))); 
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", _to, _index)),
                _artworkId);
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("artworkOfOwner", "numberOfOwnerArtworks", _to)),
                _index.add(1));
        }
        emit Transfer(_from, _to, _artworkId);
    }

    /// @dev Snark platform takes it's profit share
    /// @param _profit A price of selling
    function takePlatformProfitShare(address _storageAddress, uint256 _profit) internal {
        address snarkWallet = SnarkStorage(_storageAddress).addressStorage(keccak256("snarkWalletAddress"));
        uint256 currentBalance = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", snarkWallet)));
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", snarkWallet)),
            currentBalance.add(_profit)
        );
    }

    /// @dev Function to distribute the profits to participants
    /// @param _price Price at which artwork is sold
    /// @param _tokenId Artwork token ID
    /// @param _from Seller Address
    function incomeDistribution(address _storageAddress, uint256 _price, uint256 _tokenId, address _from) internal {
        uint256 lastPrice = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "lastPrice", _tokenId)));
        uint256 profitShareSchemaId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareSchemeId", _tokenId)));
        uint256 profitShareFromSecondarySale = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("artwork", "profitShareFromSecondarySale", _tokenId)));
        uint256 profit = _price - lastPrice;
        if (profit >= 100) {
            if (lastPrice > 0) {
                uint256 countToSeller = _price;
                profit = profit.mul(profitShareFromSecondarySale).div(100);
                countToSeller = countToSeller.sub(profit);
                uint256 currentBalance = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("pendingWithdrawals", _from)));
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("pendingWithdrawals", _from)), currentBalance.add(countToSeller));
            }
            uint256 residue = profit;
            uint256 participantsCount = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("numberOfParticipantsForProfitShareScheme", profitShareSchemaId)));
            address currentParticipant;
            uint256 participantProfit;
            for (uint256 i = 0; i < participantsCount; i++) {
                currentParticipant = SnarkStorage(_storageAddress).addressStorage(
                    keccak256(abi.encodePacked("participantAddressForProfitShareScheme", profitShareSchemaId, i)));
                participantProfit = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("participantProfitForProfitShareScheme", profitShareSchemaId, i)));
                uint256 payout = profit.mul(participantProfit).div(100);
                currentBalance = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("pendingWithdrawals", currentParticipant)));
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("pendingWithdrawals", currentParticipant)), currentBalance.add(payout));
                residue = residue.sub(payout);
            }
            lastPrice = residue;
        } else {
            lastPrice = _price;
        }
        currentBalance = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("pendingWithdrawals", _from)));
        SnarkStorage(_storageAddress).setUint(
            keccak256(abi.encodePacked("pendingWithdrawals", _from)), currentBalance.add(lastPrice));
    }

    function calculatePlatformProfitShare(address _storageAddress, uint256 _income) 
        internal 
        view 
        returns (uint256 profit, uint256 residue) 
    {
        uint256 platformProfit = SnarkStorage(_storageAddress).uintStorage(keccak256("platformProfitShare"));
        profit = _income.mul(platformProfit).div(100);
        residue = _income.sub(profit);
    }

    /// @dev Function of an artwork buying
    /// @param _storageAddress Address of storage
    /// @param _tokenId Artwork ID
    /// @param _value Selling price of artwork
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
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("artwork", "lastPrice", _tokenId)), _value);
        SnarkStorage(_storageAddress).setUint(keccak256(abi.encodePacked("saleTypeToArtwork", _tokenId)), 0);
        transferArtwork(_storageAddress, _tokenId, _mediator, _to);
    }
}