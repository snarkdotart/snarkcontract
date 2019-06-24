![89seconds](https://snark.art/assets/artworks/eve.png)

# Snark Blockchain Contracts

## Source Code

> Note: All of the Snark contract scripts are open source and documented with inline running commentary.

Project contains several logic contracts where each of them performs certain functionality. It also allows to satisfy a restriction requirement of size contract.

You can find contracts in Etherscan at the following addresses:

### 89seconds

Contract | Address
--- | ---
SnarkBase | [0xc1539693B0Abddcc0FD49Be0050835AeD6f67A50](https://etherscan.io/address/0xc1539693B0Abddcc0FD49Be0050835AeD6f67A50#code)
SnarkLoan | [0x98514a7063393436076dB6a4E40f7fe181d4AA87](https://etherscan.io/address/0x98514a7063393436076dB6a4E40f7fe181d4AA87#code)
SnarkERC721 | [0x27C8bba278aCa587772cfA91028363ae301b1A72](https://etherscan.io/address/0x27C8bba278aCa587772cfA91028363ae301b1A72#code)
SnarkStorage | [0x3007b07667826a4a4aa17a7619e46dd0f0e75157](https://etherscan.io/address/0x3007b07667826a4a4aa17a7619e46dd0f0e75157#code)

### OldTestament

Contract | Address
--- | ---
SnarkBase | [](https://etherscan.io/address/#code)
SnarkLoan | [](https://etherscan.io/address/#code)
SnarkERC721 | [](https://etherscan.io/address/#code)
SnarkStorage | [](https://etherscan.io/address/#code)

[Truffle framework](https://www.trufflesuite.com/truffle) and [Ganache](https://www.trufflesuite.com/ganache) is required to run tests of contracts.

## Overview

When developing contracts the [openzeppelin](https://openzeppelin.org) library was used.\
The contract of inheritance is as follows:

``` solidity
contract SnarkBase is Ownable
contract SnarkLoan is Ownable
contract SnarkStorage is Ownable
contract SnarkERC721 is Ownable, SupportsInterfaceWithLookup, ERC721
```

Most of an auxiliary functions were moved to libraries which work with data for each contract separately. You can find them into a 'snarklibs' folder.

Contract | Description
-- | --
[SnarkStorage](contracts/SnarkStorage.sol) | The contract contains functions of writing and reading various types data to a storage.
[SnarkBase](contracts/SnarkBase.sol) | This contract contains such functions as a creation, getting detail and update properties of tokens.
[SnarkLoan](contracts/SnarkLoan.sol) | This contract allows create and delete loans and read their properties as well.
[SnarkERC721](contracts/SnarkERC721.sol) | As you can guess from the title the contract just realize functions of ERC721 specification.

> Note: the secondary sale works on [OpenSea](https://opensea.io/assets/89secondsatomized) platform.

You can explore contracts by yourself. All function names are self-explanatory to understand their usage.\
Here we put a couple of remarks which can be not obvious at first glance.

- function **addToken**() of *SnarkBase contract* creates a new token and moves it to an artist wallet as soon as it created. You have to be aware of a profit share scheme has to exist before a token creation;
- function **setTokenAcceptOfLoanRequest**() of *SnarkBase contract* sets agree of participation in future loans or cancel this participation. Pay attention that the agreement doesn't change upon moving a token from one wallet to another. Owner of the token has to change it manually if he wishes;
- function **getTokenListForOwner**() of *SnarkBase contract* always returns owner's tokens despite active loans;
- function **createLoan**() of *SnarkLoan contract* creates a loan. Pay your attention period of the loan has not to crossed with existing loans. Otherwise, the transaction fails;
- function **getLoanId**() of *SnarkLoan contract* always returns either the current active loan id or the next future loan id.

SnarkERC721 contract is based on Non Fungible Token (NFT) Standard (ERC-721)

_Snark provides a practical use case for digital collectibles by pioneering ERC-721, a non-fungible token protocol._

A standard interface allows any Non Fungible Token (NFTs) on Ethereum
to be handled by general-purpose applications.
In particular, it will allow for Non Fungible Token (NFTs)
to be tracked in standardized wallets and traded on exchanges.

There are two functions of ERC721 which work differently depends on conditions.

- function **balanceOf**(address _owner) returns a balance of owner's tokens. If any loan is active then the algorithm of balance calculation changes and it lets you see all tokens which were agreed for a participating in loan.
- function **transferFrom**(address _to, uint256 _tokenId). This function declared as payable which means that if you send ether upon calling it then it will split the ether according to a profit share scheme if the last one were set up by an artist.
- function **tokenOfOwnerByIndex**(address _owner, uint256 _index) returns the owner's tokens by index. But in a case when a loan is active it also returns tokens which were agreed to participate in loans.

(Source: [Ethereum, Non Fungible Token (NFT) Standard #721](https://github.com/ethereum/EIPs/issues/721))

## License

Solidity is licensed under [GNU General Public License v3.0.](https://github.com/ethereum/solidity/blob/develop/LICENSE.txt)

Some third-party code has its [own licensing terms.](https://github.com/ethereum/solidity/blob/develop/cmake/templates/license.h.in)
