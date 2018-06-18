pragma solidity ^0.4.24;

import "./SnarkERC721.sol";


contract SnarkArt is SnarkERC721 {

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256('supportsInterface(bytes4)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenByIndex(uint256)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokenURI(uint256)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('getApproved(uint256)')) ^
    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    */

    // solhint-disable-next-line
    bytes4 public constant InterfaceSignature_ERC721Optional = 0x4f558e79;
    /*
    bytes4(keccak256('exists(uint256)'));
    */

    /// @notice Query if a contract implements an interface
    /// @param _interfaceID The interface identifier, as 
    ///   specified in ERC-165
    /// @dev Interface identification is specified in 
    ///   ERC-165. This function uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` 
    ///   and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata) 
        || (_interfaceID == InterfaceSignature_ERC721Optional)
        || (_interfaceID == ERC721_RECEIVED));
    }
}