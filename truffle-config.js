require('dotenv').config();

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
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: 5777,
            gasPrice: 1
        },
        main: {
            // provider: mainNetProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 1,
            host: "18.220.154.113",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        ropsten: {
            // provider: ropstenProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 3,
            host: "13.58.178.26",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        rinkeby: {
            // provider: rinkebyProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 4,
            host: "127.0.0.1",
            port: 8545,
            from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        }        
    },
    compilers: {
        solc: {
            version: "0.4.25",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                }
            }
        },
    },
    mocha: {
        // timeout: 100000
    },
};
