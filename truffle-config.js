require('dotenv').config();
var HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: 5777,
            gasPrice: 1
        },
        main: {
            provider: new HDWalletProvider(process.env.SECRET_KEY, "https://mainnet.infura.io/v3/" + process.env.PROJECT_ID),
            gas: 7900000,
            gasPrice: 10000000000, // 7 Gwei
            network_id: 1,
            confirmations: 2,
            skipDryRun: true,
        },
        ropsten: {
            provider: new HDWalletProvider(process.env.SECRET_KEY, "https://ropsten.infura.io/v3/" + process.env.PROJECT_ID),
            gas: 7900000,
            gasPrice: 7000000000, // 7 Gwei
            network_id: 3,
            confirmations: 2,
            skipDryRun: true,
        },
        rinkeby: {
            provider: new HDWalletProvider(process.env.SECRET_KEY, "https://rinkeby.infura.io/v3/" + process.env.PROJECT_ID),
            gas: 6900000,
            gasPrice: 7000000000, // 7 Gwei
            network_id: 4,
            confirmations: 2,
            skipDryRun: true,
        }
    },
    compilers: {
        solc: {
            // version: "0.5.4",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                }
            }
        },
    },
};
