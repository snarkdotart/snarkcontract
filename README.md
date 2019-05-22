# Snark Contracts

> ## *89seconds*

### Addresses of contracts

#### **Mainnet**

`Contract` | `Address`
--- | ---
*SnarkBase* | 0x7619df10aACF0B806EC2094081AC98968C9E71E9
*SnarkLoan* | 0xA933eB239D9c860d52dCa20340eE46d0d925844D
*SnarkERC721* | 0x125Ac71f194CDE29E8F2a104A04EA67779c91751

Next contracts will delete soon:

`Contract` | `Address`
--- | ---
*SnarkLoanExt* | 0xAe998FF9a0d5Ab0612ddee643D2D9D1fEEa4dEaa
*SnarkOfferBid* | 0x7622A961E89D84bC113b67838f08DF1B92a60f92

#### **Ropsten**

`Contract` | `Address`
--- | ---
*SnarkBase* | 0x16b41cdec057D589A58e66724eF39EEbD834cdDb
*SnarkLoan* | 0xD412315ab186A9CCe45C4c2D96a9dAbbA03cd694
*SnarkERC721* | 0xB4c39AF29d2c65962324ee4f9d3Ac5748CAbFe5c

#### **Rinkeby**

`Contract` | `Address`
--- | ---
*SnarkBase* | 0x5C84309Ad9648CcA8c4dB6F7E41e65CafA9f1b6F
*SnarkLoan* | 0x835933673a03673E563826a48a81ACACBd472e2d
*SnarkERC721* | 0xe75164C7f0391D48a08FF06d02600A64501D6007

### **SnarkBase contract**

#### Available Events

`Event Name` | `Input Parameters` | `Output Parameters`
--- | --- | ---
*TokenCreated* | tokenOwner: string, hashOfToken: string, tokenId: int | None
*ProfitShareSchemeAdded* | tokenOwner: string, profitShareSchemeId: int | None
*NeedApproveProfitShareRemoving* | participant: string, tokenId: int | None

#### Available Functions

`Function Name` | `Input Parameters` | `Output Parameters`
--- | --- | ---
*kill* | none | None
*sendRequestForApprovalOfProfit ShareRemovalForSecondarySale* | tokenId: int | None
*approveRemovingProfitShareFromSecondarySale* | tokenId: int | None
*setTokenAcceptOfLoanRequest* | tokenId: int, isAcceptForSnark: bool | None
*setTokenName* | tokenName: string | None
*setTokenSymbol* | tokenSymbol: string | None
*changeRestrictAccess* | isRestrict: bool | None
*createProfitShareScheme* | artistAddress: address, participants: address[], percentAmount: int[] | profitId: int
*getProfitShareSchemesTotalCount* | None | count: int
*getProfitShareSchemeCountByAddress* | schemeOwner: address | count: int
*getProfitShareSchemeIdByIndex* | schemeOwner: address, index: int | schemeId: int
*getProfitShareParticipantsCount* | schemeOwner: address | count: int
*getProfitShareParticipantsList* | schemeOwner: address | participants: string[]
*getOwnerOfToken* | tokenId: int | owner: address
*addToken* | artistAddress: address, hashOfToken: string, tokenUrl: string, decorationUrl: string, decriptionKey: string, limitedEditionProfitSFSSProfitSSID: int[], isAcceptOfLoanRequest: int | None
*getTokenDecryptionKey* | tokenId: int | description: string
*getTokensCount* | None | count: int
*getTokensCountByArtist* | artist: address | count: int
*getTokenListForArtist* | artist: address | tokens: int[]
*getTokensCountByOwner* | tokenOwner: address | count: int
*getTokenListForOwner* | tokenOwner: address | tokens: int[]
*isTokenAcceptOfLoanRequest* | tokenId: int | isAccept: bool
*getTokenDetail* | tokenId: int | currentOwner: address, artist: address, hashOfToken: string, limitedEdition: int, editionNumber: int, lastPrice: int, profitShareSchemeId: int, profitShareFromSecondarySale: int, tokenUrl: string, decorationUrl: string, isAcceptOfLoanRequest: bool
*changeProfitShareSchemeForToken* | tokenId: int, newProfitShareSchemeId: int | None
*getWithdrawBalance* | tokenOwner: address | balance: int
*getNumberOfParticipantsForProfitShareScheme* | schemeId: int | number: int
*getParticipantOfProfitShareScheme* | schemeId: int, index: int | participant: address, profit: int
*withdrawFunds* | None | None
*setSnarkWalletAddress* | snarkWalletAddr: address | None
*setPlatformProfitShare* | profit: int | None
*changeTokenData* | tokenId: int, hashOfToken: string, tokenUrl: string, decorationUrl: string, descriptionKey: string | None
*getSnarkWalletAddressAndProfit* | None | wallet: address, profit: int
*getPlatformProfitShare* | None | profit: int
*getSaleTypeToToken* | tokenId: int | saleType: int
*getTokenHashAsInUse* | tokenHash: string | isUse: bool
*getNumberOfProfitShareSchemesForOwner* | schemeOwner: address | number: int
*getProfitShareSchemeIdForOwner* | schemeOwner: address, index: int | schemeId: int
*getListOfAllArtists* | None | artists: address[]
*setLinkDropPrice* | tokenId: int, price: int | None
*toGiftToken* | tokenId: int, to: address | None

## *OldStatement*
