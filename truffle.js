// require('dotenv').config();

var Web3 = require("web3");
var web3 = new Web3();

// var WalletProvider = require("truffle-hdwallet-provider");
// var Wallet = require('ethereumjs-wallet');

// var privateKey = new Buffer(process.env.SECRET_KEY, "hex");
// var wallet = Wallet.fromPrivateKey(privateKey);

// var mainNetProvider = new WalletProvider(wallet, "https://mainnet.infura.io/v3/" + process.env.PROJECT_ID);
// var ropstenProvider = new WalletProvider(wallet, "https://ropsten.infura.io/v3/" + process.env.PROJECT_ID);
// var rinkebyProvider = new WalletProvider(wallet, "https://rinkeby.infura.io/v3/" + process.env.PROJECT_ID);

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  /** 
   * Ropsten 
   * ------------
   * testnet: PoW (proof-of-work)
   * Cons: not immune to spam attacks.
   * Network id: 3
   * Block time: sub-30 seconds
   * Commands: geth --testnet or geth --network 3
   * Explorer: https://ropsten.etherscan.io
   * Github: https://github.com/ethereum/ropsten
   * 
   * Rinkeby
   * ------------
   * testnet: PoA (proof-of-authority)
   * Cons: ether can't be mined. it has to be requested from a faucet: https://faucet.rinkeby.io
   * Network id: 4
   * Block time: 15 seconds
   * Commands: geth --rinkeby or geth --networkid 4
   * Explorer: https://rinkeby.etherscan.io
   * Github: https://github.com/ethereum/EIPs/issues/225
   * Website: https://wwww.rinkeby.io
  */
  // 
  // 
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: 5777,
            gasPrice: 1
        },
        main: {
            // provider: mainNetProvider,
            gas: 4700000,
            gasPrice: web3.toWei("8", "gwei"),
            network_id: 1,
            host: "3.16.78.59",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        ropsten: {
            // provider: ropstenProvider,
            gas: 4700000,
            gasPrice: web3.toWei("8", "gwei"),
            network_id: 3,
            host: "13.58.178.26",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        rinkeby: {
            // provider: rinkebyProvider,
            gas: 4700000,
            gasPrice: web3.toWei("8", "gwei"),
            network_id: 4,
            host: "127.0.0.1",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        }        
    },
    solc: {
		optimizer: {
			enabled: true,
			runs: 200
		}
	}    
};
