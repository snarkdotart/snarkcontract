![89seconds](https://snark.art/assets/artworks/eve.png)

# 89 seconds Atomized: Experiment in collective ownership on the Ethereum Blockchain

89 seconds Atomized shatters the final artist's proof of Eve Sussman's acclaimed video 89 seconds at Alcazár into 2,304 video fragments, tokenized using ERC721 standard, to create a new artwork on the blockchain. Each token is tied to a 20 by 20 px fragment of the video. An experiment in ownership and collective interaction, the piece can be reassembled and screened at will by the community of collectors.

The repository contains the Ethereum contract to manage the ownership and transfer of fragmented artwork and for owners of the fragments to lend their framents to one another in order to give each owner a time-shared access to all fragments that have the necessary permissions from their owners.

# Snark Ethereum Contract

## Source Code

> Note: All of the Snark contract scripts are open source and documented with inline running commentary.

The project contains several contracts with their respective functionalities and allows us to satisfy a contract size restriction requirement.

### 89seconds Contracts

The project is divided into the following contracts:

Contract | Description
-- | --
[SnarkStorage](contracts/SnarkStorage.sol) | The contract contains functions that facilitate writing and reading various types of data elements from storage.
[SnarkBase](contracts/SnarkBase.sol) | This contract contains functions that facilitate minting, burning, reading and updating various properties of the artwork tokens.
[SnarkLoan](contracts/SnarkLoan.sol) | This contract contains functions that facilitate creation and deletion of token loans between the artwork token owners.  The contract also allows for reading of individual loan properties.
[SnarkERC721](contracts/SnarkERC721.sol) | This contract contains ERC721 token standard functions.  It has been modified to allow for token loans between token owners.

</br>

Contract | Address
--- | ---
SnarkBase | [0x7558B1733eAc2a9320A2B9900f1752dbF689f6A6](https://etherscan.io/address/0x7558B1733eAc2a9320A2B9900f1752dbF689f6A6#code)
SnarkLoan | [0x035BDDD14F8E92f0070A5d23E8B1F0Db043951fc](https://etherscan.io/address/0x035BDDD14F8E92f0070A5d23E8B1F0Db043951fc#code)
SnarkERC721 | [0x7237e6d335BF0158888Ace73F64Aa3b8c8140F93](https://etherscan.io/address/0x7237e6d335BF0158888Ace73F64Aa3b8c8140F93#code)
SnarkStorage | [0x3007b07667826a4a4aa17a7619e46dd0f0e75157](https://etherscan.io/address/0x3007b07667826a4a4aa17a7619e46dd0f0e75157#code)

[Truffle framework](https://www.trufflesuite.com/truffle) and [Ganache](https://www.trufflesuite.com/ganache) is required to run tests of the contracts.

When developing contracts the [openzeppelin](https://openzeppelin.org) library was used.\
The contract inheritance is as follows:

``` solidity
contract SnarkBase is Ownable
contract SnarkLoan is Ownable
contract SnarkStorage is Ownable
contract SnarkERC721 is Ownable, SupportsInterfaceWithLookup, ERC721
```

Most of an auxiliary functions were moved to libraries which work with data for each contract individually. They are located in the 'snarklibs' folder.

> Note: the secondary sale works on [OpenSea](https://opensea.io/assets/89secondsatomized) platform.

Feel free to explore our contracts. Most function names are self-explanatory to imply their usage.\
See the following remarks regarding several functions that require additional explanation:

- function **addToken**() of *SnarkBase contract* creates a new token and moves it to the artist's wallet as soon as it created. A profit share scheme has to exist before the token minting begins;
- function **setTokenAcceptOfLoanRequest**() of *SnarkBase contract* sets or cancels the owner's agreement to participate in lending of their tokens to other owners. Note that the owner's agreement doesn't revise automatically during a token transfer from one owner to another. Owner of the token has to change it manually if he wishes to update their agreement participation;
- function **getTokenListForOwner**() of *SnarkBase contract*  returns owner's tokens regardless of the presense of an active loan;
- function **createLoan**() of *SnarkLoan contract* creates a loan. Note that period of the loan cannot overlap with existing loans. 
- function **getLoanId**() of *SnarkLoan contract*  returns either the current active loan id or the next future loan id.

SnarkERC721 contract is based on Non Fungible Token (NFT) Standard (ERC-721)

_Snark provides a practical use case for digital collectibles by pioneering ERC-721, a non-fungible token protocol._

A standard interface allows any Non Fungible Token (NFTs) on Ethereum
to be handled by general-purpose applications.
In particular, it will allow for Non Fungible Token (NFTs)
to be tracked in standardized wallets and traded on exchanges.

There are functions of ERC721 which work differently depends on conditions.

- function **balanceOf**(address _owner) returns a balance of owner's tokens. If any loan is active then the algorithm of balance calculation changes and it lets you see all tokens which were agreed for a participating in loan.
- function **transferFrom**(address _to, uint256 _tokenId). This function declared as payable which means that if you send ether upon calling it then it will split the ether according to a profit share scheme if the last one were set up by an artist.
- function **tokenOfOwnerByIndex**(address _owner, uint256 _index) returns the owner's tokens by index. But in a case when a loan is active it also returns tokens which were agreed to participate in loans.

(Source: [Ethereum, Non Fungible Token (NFT) Standard #721](https://github.com/ethereum/EIPs/issues/721))

## License

Solidity is licensed under [GNU General Public License v3.0.](https://github.com/ethereum/solidity/blob/develop/LICENSE.txt)

Some third-party code has its [own licensing terms.](https://github.com/ethereum/solidity/blob/develop/cmake/templates/license.h.in)

![89seconds](https://snark.art/assets/artworks/eve.png)
