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
*SnarkBase* | 0x5524953B294981F70A2E32D3D14Fc4a58bD038A8
*SnarkLoan* | 0xca0e5EEC113b4305bE8B81228c8D81f69735d9A5
*SnarkERC721* | 0x8356fD87db9F86bB49A2f782f7188779B788695f

#### **Rinkeby**

`Contract` | `Address`
--- | ---
*SnarkBase* | 0xa6facdc6d2f95203ad9833137ba36205e87843f9
*SnarkLoan* | 0x162d108e9efd1fb00a699206b862470558a75794
*SnarkERC721* | 0xc42102a9a9baacd94667d51ace6e5a7dbabb884d

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
*sendRequestForApprovalOfProfitShareRemovalForSecondarySale* | tokenId: int | None
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
