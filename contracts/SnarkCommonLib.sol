pragma solidity ^0.4.24;

import "./openzeppelin/SafeMath.sol";
import "./SnarkStorage.sol";


library SnarkCommonLib {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function transferToken(address _storageAddress, uint256 _tokenId, address _from, address _to) internal {
        if (_tokenId <= SnarkStorage(_storageAddress).uintStorage(keccak256("totalNumberOfTokens")) &&
            _from == SnarkStorage(_storageAddress).addressStorage(
                keccak256(abi.encodePacked("ownerOfToken", _tokenId)))
        ) {
            uint256 numberOfTokens = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", _from)));
            for (uint256 i = 0; i < numberOfTokens; i++) {
                if (_tokenId == SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("tokenOfOwner", _from, i))
                )) {
                    uint256 _index = i;
                    break;
                }
            }
            uint256 maxIndex = numberOfTokens.sub(1);
            if (maxIndex != _index) {
                uint256 tokenId = SnarkStorage(_storageAddress).uintStorage(
                    keccak256(abi.encodePacked("tokenOfOwner", _from, maxIndex)));
                SnarkStorage(_storageAddress).setUint(
                    keccak256(abi.encodePacked("tokenOfOwner", _from, _index)), 
                    tokenId);
            }
            SnarkStorage(_storageAddress).deleteUint(
                keccak256(abi.encodePacked("tokenOfOwner", _from, maxIndex)));
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", _from)),
                maxIndex);
            SnarkStorage(_storageAddress).setAddress(
                keccak256(abi.encodePacked("ownerOfToken", _tokenId)),
                _to);
            _index = SnarkStorage(_storageAddress).uintStorage(
                keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", _to))); 
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("tokenOfOwner", _to, _index)),
                _tokenId);
            SnarkStorage(_storageAddress).setUint(
                keccak256(abi.encodePacked("tokenOfOwner", "numberOfOwnerTokens", _to)),
                _index.add(1));
        }
        emit Transfer(_from, _to, _tokenId);
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
    /// @param _price Price at which token is sold
    /// @param _tokenId Token token ID
    /// @param _from Seller Address
    function incomeDistribution(address _storageAddress, uint256 _price, uint256 _tokenId, address _from) internal {
        uint256 lastPrice = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "lastPrice", _tokenId)));
        uint256 profitShareSchemaId = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "profitShareSchemeId", _tokenId)));
        uint256 profitShareFromSecondarySale = SnarkStorage(_storageAddress).uintStorage(
            keccak256(abi.encodePacked("token", "profitShareFromSecondarySale", _tokenId)));
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