require('dotenv').config();

var Web3 = require("web3");
var web3 = new Web3('http://localhost:8545');

var HDWalletProvider = require("truffle-hdwallet-provider");

var mainNetProvider = new HDWalletProvider(process.env.SECRET_KEY, "https://mainnet.infura.io/v3/" + process.env.PROJECT_ID);
var ropstenProvider = new HDWalletProvider(process.env.SECRET_KEY, "https://ropsten.infura.io/v3/" + process.env.PROJECT_ID);
var rinkebyProvider = new HDWalletProvider(process.env.SECRET_KEY, "https://rinkeby.infura.io/v3/" + process.env.PROJECT_ID);

console.log('Provider is: ', ropstenProvider);

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: 5777,
            gasPrice: 1
        },
        main: {
            provider: mainNetProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 1,
            // host: "18.220.154.113",
            // port: 8545,
            // from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        ropsten: {
            provider: ropstenProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 3,
            // host: "13.58.178.26",
            // port: 8545,
            // from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
        },
        rinkeby: {
            provider: rinkebyProvider,
            gas: 7800000,
            gasPrice: web3.utils.toWei("8", "gwei"),
            network_id: 4,
            // host: "127.0.0.1",
            // port: 8545,
            // from: '0xc5a3d99e05c39a18d6342b5f27c08c64a486df00'
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
};
